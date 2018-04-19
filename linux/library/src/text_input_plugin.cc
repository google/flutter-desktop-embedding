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

#include <flutter_desktop_embedding/text_input_model.h>

static constexpr char kChannelName[] = "flutter/textinput";

namespace flutter_desktop_embedding {

static TextInputModel model(1);

void TextInputPlugin::CharHook(GLFWwindow *window, unsigned int char_point) {
  // TODO(awdavies): Get a "current" model.
  model.AddCharacter(static_cast<char>(char_point));
  CallPlatformCallback(model.GetState());
}

void TextInputPlugin::KeyboardHook(GLFWwindow *window, int key, int scancode,
                                   int action, int mods) {
  if (action == GLFW_PRESS || action == GLFW_REPEAT) {
    switch (key) {
      case GLFW_KEY_LEFT:
        if (model.MoveCursorBack()) {
          CallPlatformCallback(model.GetState());
        }
        break;
      case GLFW_KEY_RIGHT:
        if (model.MoveCursorForward()) {
          CallPlatformCallback(model.GetState());
        }
        break;
      case GLFW_KEY_END:
        model.MoveCursorToEnd();
        CallPlatformCallback(model.GetState());
        break;
      case GLFW_KEY_HOME:
        model.MoveCursorToBeginning();
        CallPlatformCallback(model.GetState());
        break;
      case GLFW_KEY_BACKSPACE:
        if (model.Backspace()) {
          CallPlatformCallback(model.GetState());
        }
        break;
      case GLFW_KEY_DELETE:
        if (model.Delete()) {
          CallPlatformCallback(model.GetState());
        }
        break;
      default:
        break;
    }
  }
}  // namespace flutter_desktop_embedding

TextInputPlugin::TextInputPlugin(PlatformCallback platform_callback)
    : Plugin(kChannelName, platform_callback, false) {}

TextInputPlugin::~TextInputPlugin() {}

Json::Value TextInputPlugin::HandlePlatformMessage(const Json::Value &message) {
  // TODO(awdavies): Set the model state from this.
  // std::cerr << "You gotta handle this, son: " << message << std::endl;
  return Json::nullValue;
}

}  // namespace flutter_desktop_embedding
