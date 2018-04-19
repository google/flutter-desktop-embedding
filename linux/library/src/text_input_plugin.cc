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
#include <flutter_desktop_embedding/text_input_plugin.h>

#include <iostream>

#include <flutter_desktop_embedding/common/platform_protocol.h>

static constexpr char kSetEditingStateMethod[] = "TextInput.setEditingState";
static constexpr char kClearClientMethod[] = "TextInput.clearClient";
static constexpr char kSetClientMethod[] = "TextInput.setClient";
static constexpr char kShowMethod[] = "TextInput.show";
static constexpr char kHideMethod[] = "TextInput.hide";

static constexpr char kSelectionBaseKey[] = "selectionBase";
static constexpr char kSelectionExtentKey[] = "selectionExtent";

static constexpr char kTextKey[] = "text";

static constexpr char kChannelName[] = "flutter/textinput";

namespace flutter_desktop_embedding {

void TextInputPlugin::CharHook(GLFWwindow *window, unsigned int code_point) {
  if (active_model_ == nullptr) {
    return;
  }
  // TODO(awdavies): Actually handle potential unicode characters. Probably
  // requires some ICU data or something.
  active_model_->AddCharacter(static_cast<char>(code_point));
  CallPlatformCallback(active_model_->GetState());
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
          CallPlatformCallback(active_model_->GetState());
        }
        break;
      case GLFW_KEY_RIGHT:
        if (active_model_->MoveCursorForward()) {
          CallPlatformCallback(active_model_->GetState());
        }
        break;
      case GLFW_KEY_END:
        active_model_->MoveCursorToEnd();
        CallPlatformCallback(active_model_->GetState());
        break;
      case GLFW_KEY_HOME:
        active_model_->MoveCursorToBeginning();
        CallPlatformCallback(active_model_->GetState());
        break;
      case GLFW_KEY_BACKSPACE:
        if (active_model_->Backspace()) {
          CallPlatformCallback(active_model_->GetState());
        }
        break;
      case GLFW_KEY_DELETE:
        if (active_model_->Delete()) {
          CallPlatformCallback(active_model_->GetState());
        }
        break;
      default:
        break;
    }
  }
}

TextInputPlugin::TextInputPlugin(PlatformCallback platform_callback)
    : Plugin(kChannelName, platform_callback, false), active_model_(nullptr) {}

TextInputPlugin::~TextInputPlugin() {}

Json::Value TextInputPlugin::HandlePlatformMessage(const Json::Value &message) {
  Json::Value method = message[kMethodKey];
  if (method.isNull()) {
    std::cerr << "No text input method declaration" << std::endl;
    return Json::nullValue;
  }
  std::string method_str = method.asString();

  // These methods are no-ops.
  if (method_str.compare(kShowMethod) == 0 ||
      method_str.compare(kHideMethod) == 0) {
    return Json::nullValue;
  }

  // Clear client method takes no args. Every following method requires args.
  if (method_str.compare(kClearClientMethod) == 0) {
    active_model_ = nullptr;
    return Json::nullValue;
  }

  Json::Value args = message[kArgumentsKey];
  if (args.isNull()) {
    std::cerr << "Method invoked without args" << std::endl;
    return Json::nullValue;
  }

  if (method_str.compare(kSetClientMethod) == 0) {
    // TODO(awdavies): There's quite a wealth of arguments supplied with this
    // method, and they should be inspected/used.
    Json::Value client_id_json = args[0];
    if (client_id_json.isNull()) {
      std::cerr << "Could not set client, ID is null." << std::endl;
      return Json::nullValue;
    }
    int client_id = client_id_json.asInt();
    if (input_models_.find(client_id) == input_models_.end()) {
      input_models_.insert(std::make_pair(
          client_id, std::make_unique<TextInputModel>(client_id)));
    }
    active_model_ = input_models_[client_id].get();
    return Json::nullValue;
  }

  if (method_str.compare(kSetEditingStateMethod) == 0) {
    if (active_model_ == nullptr) {
      std::cerr << "Set editing state has been invoked, but no client is set."
                << std::endl;
      return Json::nullValue;
    }
    Json::Value text = args[kTextKey];
    if (text.isNull()) {
      std::cerr << "Set editing state has been invoked, but without text."
                << std::endl;
      return Json::nullValue;
    }
    Json::Value selection_base = args[kSelectionBaseKey];
    Json::Value selection_extent = args[kSelectionExtentKey];
    if (selection_base.isNull() || selection_extent.isNull()) {
      std::cerr << "Selection base/extent values invalid." << std::endl;
      return Json::nullValue;
    }
    active_model_->SetEditingState(selection_base.asInt(),
                                   selection_extent.asInt(), text.asString());
  }
  // TODO(awdavies): Issue #45 dictates this is going to have to be updated
  // to show that the command has run successfully. Current implementation just
  // returns an empty string to the engine regardless of the result.
  return Json::nullValue;
}

}  // namespace flutter_desktop_embedding
