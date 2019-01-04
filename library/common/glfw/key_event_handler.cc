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
#include "library/common/glfw/key_event_handler.h"

#include <json/json.h>
#include <iostream>

#include "library/common/internal/json_message_codec.h"

static constexpr char kChannelName[] = "flutter/keyevent";

static constexpr char kKeyCodeKey[] = "keyCode";
static constexpr char kKeyMapKey[] = "keymap";
static constexpr char kTypeKey[] = "type";

static constexpr char kAndroidKeyMap[] = "android";
static constexpr char kKeyUp[] = "keyup";
static constexpr char kKeyDown[] = "keydown";
// TODO: This event is not supported by Flutter. Add once it's implemented.
static constexpr char kRepeat[] = "repeat";

namespace flutter_desktop_embedding {

KeyEventHandler::KeyEventHandler(const BinaryMessenger *messenger)
    : messenger_(messenger), channel_(kChannelName) {}

KeyEventHandler::~KeyEventHandler() {}

void KeyEventHandler::CharHook(GLFWwindow *window, unsigned int code_point) {}

void KeyEventHandler::KeyboardHook(GLFWwindow *window, int key, int scancode,
                                   int action, int mods) {
  // TODO: Translate to a cross-platform key code system rather than passing
  // the native key code.
  Json::Value args;
  args[kKeyCodeKey] = key;
  args[kKeyMapKey] = kAndroidKeyMap;

  switch (action) {
    case GLFW_PRESS:
      args[kTypeKey] = kKeyDown;
      break;
    case GLFW_RELEASE:
      args[kTypeKey] = kKeyUp;
      break;
    default:
      std::cerr << "Unknown key event action: " << action << std::endl;
      return;
  }
  auto message = JsonMessageCodec::GetInstance().EncodeMessage(args);
  messenger_->Send(channel_, message->data(), message->size());
}

}  // namespace flutter_desktop_embedding