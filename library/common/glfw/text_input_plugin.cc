// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include "library/common/glfw/text_input_plugin.h"

#include <cstdint>
#include <iostream>

#include "library/common/client_wrapper/include/flutter_desktop_embedding/json_method_codec.h"

static constexpr char kSetEditingStateMethod[] = "TextInput.setEditingState";
static constexpr char kClearClientMethod[] = "TextInput.clearClient";
static constexpr char kSetClientMethod[] = "TextInput.setClient";
static constexpr char kShowMethod[] = "TextInput.show";
static constexpr char kHideMethod[] = "TextInput.hide";

// Client config  keys.
static constexpr char kTextInputAction[] = "inputAction";
static constexpr char kTextInputType[] = "inputType";
static constexpr char kTextInputTypeName[] = "name";

static constexpr char kUpdateEditingStateMethod[] =
    "TextInputClient.updateEditingState";
static constexpr char kPerformActionMethod[] = "TextInputClient.performAction";

static constexpr char kChannelName[] = "flutter/textinput";

static constexpr char kBadArgumentError[] = "Bad Arguments";
static constexpr char kInternalConsistencyError[] =
    "Internal Consistency Error";

// Text affinity options keys.
static constexpr char kTextAffinityDownstream[] = "TextAffinity.downstream";
static constexpr char kTextAffinityUpstream[] = "TextAffinity.upstream";

// State keys.
static constexpr char kComposingBaseKey[] = "composingBase";
static constexpr char kComposingExtentKey[] = "composingExtent";
static constexpr char kSelectionBaseKey[] = "selectionBase";
static constexpr char kSelectionExtentKey[] = "selectionExtent";
static constexpr char kSelectionAffinityKey[] = "selectionAffinity";
static constexpr char kSelectionIsDirectionalKey[] = "selectionIsDirectional";
static constexpr char kTextKey[] = "text";

static constexpr uint32_t kInputModelLimit = 256;

namespace flutter_desktop_embedding {

// Plugin methods

void TextInputPlugin::CharHook(GLFWwindow *window, unsigned int code_point) {
  if (active_model_ == nullptr) {
    return;
  }
  // TODO(awdavies): Actually handle potential unicode characters. Probably
  // requires some ICU data or something.
  active_model_->AddCharacter(static_cast<char>(code_point));
  SendStateUpdate(*active_model_);
}

void TextInputPlugin::KeyboardHook(GLFWwindow *window, int key, int scancode,
                                   int action, int mods) {
  if (active_model_ == nullptr) {
    return;
  }
  if (action == GLFW_PRESS || action == GLFW_REPEAT) {
    switch (key) {
      case GLFW_KEY_DOWN:
        if (active_model_->MoveCursorDown()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_UP:
        if (active_model_->MoveCursorUp()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_LEFT:
        if (active_model_->MoveCursorBack()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_RIGHT:
        if (active_model_->MoveCursorForward()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_END:
        if (active_model_->MoveCursorToEnd()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_HOME:
        if (active_model_->MoveCursorToBeginning()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_BACKSPACE:
        if (active_model_->Backspace()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_DELETE:
        if (active_model_->Delete()) {
          SendStateUpdate(*active_model_);
        }
        break;
      case GLFW_KEY_ENTER:
        EnterPressed(active_model_);
      default:
        break;
    }
  }
}

// Utility functions to convert to/from Json/State

Json::Value StateToJson(const State &state) {
  Json::Value editing_state;
  editing_state[kComposingBaseKey] = static_cast<int>(state.composing.begin);
  editing_state[kComposingExtentKey] = static_cast<int>(state.composing.end);
  editing_state[kSelectionAffinityKey] =
      state.text_affinity.compare(kTextAffinityUpstream) == 0
          ? kTextAffinityUpstream
          : kTextAffinityDownstream;
  editing_state[kSelectionBaseKey] = static_cast<int>(state.selection.begin);
  editing_state[kSelectionExtentKey] = static_cast<int>(state.selection.end);
  editing_state[kSelectionIsDirectionalKey] = state.isDirectional;
  editing_state[kTextKey] = state.text;
  return editing_state;
}

State StateFromJson(Json::Value state) {
  State new_state;
  Json::Value text = state[kTextKey];
  if (text.isNull()) {
    throw std::invalid_argument(
        "Set editing state has been invoked, but without text.");
  }
  new_state.text = text.asString();

  Json::Value selection_base = state[kSelectionBaseKey];
  Json::Value selection_extent = state[kSelectionExtentKey];
  if (selection_base.isNull() || selection_extent.isNull()) {
    throw std::invalid_argument("Selection base/extent values invalid.");
  }
  new_state.selection.begin = static_cast<size_t>(selection_base.asInt());
  new_state.selection.end = static_cast<size_t>(selection_extent.asInt());

  Json::Value composing_base = state[kComposingBaseKey];
  Json::Value composing_extent = state[kComposingExtentKey];
  new_state.composing.begin = composing_base.isNull()
                                  ? new_state.selection.begin
                                  : static_cast<size_t>(composing_base.asInt());
  new_state.composing.end = composing_extent.isNull()
                                ? new_state.selection.end
                                : static_cast<size_t>(composing_extent.asInt());

  Json::Value text_affinity = state[kSelectionAffinityKey];
  new_state.text_affinity = text_affinity.isNull() ? kTextAffinityDownstream
                                                   : text_affinity.asString();
  return new_state;
}

// TextInputPlugin methods

TextInputPlugin::TextInputPlugin(PluginRegistrar *registrar)
    : channel_(std::make_unique<MethodChannel<Json::Value>>(
          registrar->messenger(), kChannelName,
          &JsonMethodCodec::GetInstance())),
      active_model_(nullptr) {
  channel_->SetMethodCallHandler(
      [this](const MethodCall<Json::Value> &call,
             std::unique_ptr<MethodResult<Json::Value>> result) {
        HandleMethodCall(call, std::move(result));
      });
}

TextInputPlugin::~TextInputPlugin() {}

void TextInputPlugin::HandleMethodCall(
    const MethodCall<Json::Value> &method_call,
    std::unique_ptr<MethodResult<Json::Value>> result) {
  const std::string &method = method_call.method_name();

  if (method.compare(kShowMethod) == 0 || method.compare(kHideMethod) == 0) {
    // These methods are no-ops.
  } else if (method.compare(kClearClientMethod) == 0) {
    active_model_ = nullptr;
  } else {
    // Every following method requires args.
    if (!method_call.arguments() || method_call.arguments()->isNull()) {
      result->Error(kBadArgumentError, "Method invoked without args");
      return;
    }
    const Json::Value &args = *method_call.arguments();

    if (method.compare(kSetClientMethod) == 0) {
      // TODO(awdavies): There's quite a wealth of arguments supplied with this
      // method, and they should be inspected/used.
      Json::Value client_id_json = args[0];
      Json::Value client_config = args[1];
      if (client_id_json.isNull()) {
        result->Error(kBadArgumentError, "Could not set client, ID is null.");
        return;
      }
      if (client_config.isNull()) {
        result->Error(kBadArgumentError,
                      "Could not set client, missing arguments.");
      }
      active_client_id = client_id_json.asInt();
      if (input_models_.find(active_client_id) == input_models_.end()) {
        // Skips out on adding a new input model once over the limit.
        if (input_models_.size() > kInputModelLimit) {
          result->Error(
              kInternalConsistencyError,
              "Input models over limit. Aborting creation of new text model.");
          return;
        }
        std::string input_action = client_config[kTextInputAction].asString();
        Json::Value input_type_info = client_config[kTextInputType];
        std::string input_type = input_type_info[kTextInputTypeName].asString();
        if (input_action.empty() || input_type.empty()) {
          result->Error(kBadArgumentError,
                        "Missing arguments input_action or input_type.");
          return;
        }
        input_models_.insert(std::make_pair(
            active_client_id,
            std::make_unique<TextInputModel>(input_type, input_action)));
      }
      active_model_ = input_models_[active_client_id].get();
    } else if (method.compare(kSetEditingStateMethod) == 0) {
      if (active_model_ == nullptr) {
        result->Error(
            kInternalConsistencyError,
            "Set editing state has been invoked, but no client is set.");
        return;
      }
      try {
        State state = StateFromJson(args);
        active_model_->UpdateState(state);
      } catch (const std::exception &e) {
        result->Error(
            "Failed to set state. Arguments might be missing or misconfigured",
            e.what());
        return;
      }
    } else {
      // Unhandled method.
      result->NotImplemented();
      return;
    }
  }
  // All error conditions return early, so if nothing has gone wrong indicate
  // success.
  result->Success();
}

void TextInputPlugin::SendStateUpdate(const TextInputModel &model) {
  auto state = std::make_unique<Json::Value>();
  state.get()->append(active_client_id);
  state.get()->append(StateToJson(model.GetState()));
  channel_->InvokeMethod(kUpdateEditingStateMethod, std::move(state));
}

void TextInputPlugin::EnterPressed(TextInputModel *model) {
  if (model->InsertNewLine()) {
    SendStateUpdate(*model);
  }
  auto args = std::make_unique<Json::Value>(Json::arrayValue);
  args->append(active_client_id);
  args->append(model->input_action());

  channel_->InvokeMethod(kPerformActionMethod, std::move(args));
}

}  // namespace flutter_desktop_embedding
