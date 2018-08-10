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
#include "linux/library/src/internal/text_input_plugin.h"

#include <cstdint>
#include <iostream>

static constexpr char kSetEditingStateMethod[] = "TextInput.setEditingState";
static constexpr char kClearClientMethod[] = "TextInput.clearClient";
static constexpr char kSetClientMethod[] = "TextInput.setClient";
static constexpr char kShowMethod[] = "TextInput.show";
static constexpr char kHideMethod[] = "TextInput.hide";

static constexpr char kUpdateEditingStateMethod[] =
    "TextInputClient.updateEditingState";

static constexpr char kSelectionBaseKey[] = "selectionBase";
static constexpr char kSelectionExtentKey[] = "selectionExtent";

static constexpr char kTextKey[] = "text";

static constexpr char kChannelName[] = "flutter/textinput";

static constexpr char kBadArgumentError[] = "Bad Arguments";
static constexpr char kInternalConsistencyError[] =
    "Internal Consistency Error";

static constexpr uint32_t kInputModelLimit = 256;

namespace flutter_desktop_embedding {

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
        active_model_->MoveCursorToEnd();
        SendStateUpdate(*active_model_);
        break;
      case GLFW_KEY_HOME:
        active_model_->MoveCursorToBeginning();
        SendStateUpdate(*active_model_);
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
      default:
        break;
    }
  }
}

TextInputPlugin::TextInputPlugin()
    : JsonPlugin(kChannelName, false), active_model_(nullptr) {}

TextInputPlugin::~TextInputPlugin() {}

void TextInputPlugin::HandleJsonMethodCall(
    const JsonMethodCall &method_call, std::unique_ptr<MethodResult> result) {
  const std::string &method = method_call.method_name();

  if (method.compare(kShowMethod) == 0 || method.compare(kHideMethod) == 0) {
    // These methods are no-ops.
  } else if (method.compare(kClearClientMethod) == 0) {
    active_model_ = nullptr;
  } else {
    // Every following method requires args.
    const Json::Value &args = method_call.GetArgumentsAsJson();
    if (args.isNull()) {
      result->Error(kBadArgumentError, "Method invoked without args");
      return;
    }

    if (method.compare(kSetClientMethod) == 0) {
      // TODO(awdavies): There's quite a wealth of arguments supplied with this
      // method, and they should be inspected/used.
      Json::Value client_id_json = args[0];
      if (client_id_json.isNull()) {
        result->Error(kBadArgumentError, "Could not set client, ID is null.");
        return;
      }
      int client_id = client_id_json.asInt();
      if (input_models_.find(client_id) == input_models_.end()) {
        // Skips out on adding a new input model once over the limit.
        if (input_models_.size() > kInputModelLimit) {
          result->Error(
              kInternalConsistencyError,
              "Input models over limit. Aborting creation of new text model.");
          return;
        }
        input_models_.insert(std::make_pair(
            client_id, std::make_unique<TextInputModel>(client_id)));
      }
      active_model_ = input_models_[client_id].get();
    } else if (method.compare(kSetEditingStateMethod) == 0) {
      if (active_model_ == nullptr) {
        result->Error(
            kInternalConsistencyError,
            "Set editing state has been invoked, but no client is set.");
        return;
      }
      Json::Value text = args[kTextKey];
      if (text.isNull()) {
        result->Error(kBadArgumentError,
                      "Set editing state has been invoked, but without text.");
        return;
      }
      Json::Value selection_base = args[kSelectionBaseKey];
      Json::Value selection_extent = args[kSelectionExtentKey];
      if (selection_base.isNull() || selection_extent.isNull()) {
        result->Error(kInternalConsistencyError,
                      "Selection base/extent values invalid.");
        return;
      }
      active_model_->SetEditingState(selection_base.asInt(),
                                     selection_extent.asInt(), text.asString());
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
  InvokeMethod(kUpdateEditingStateMethod, model.GetState());
}

}  // namespace flutter_desktop_embedding
