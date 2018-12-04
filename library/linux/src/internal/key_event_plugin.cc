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
#include "library/linux/src/internal/key_event_plugin.h"
#include "library/linux/src/internal/json_message_codec.h"

#include <flutter_embedder.h>
#include <json/json.h>
#include <iostream>

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
KeyEventPlugin::KeyEventPlugin() : channel_(kChannelName) {}
KeyEventPlugin::~KeyEventPlugin() {}

void KeyEventPlugin::SetBinaryMessenger(BinaryMessenger *messenger) {
  messenger_ = messenger;
}

void KeyEventPlugin::CharHook(GLFWwindow *window, unsigned int code_point) {}

void KeyEventPlugin::KeyboardHook(GLFWwindow *window, int key, int scancode,
                                  int action, int mods) {
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
      break;
  }

  auto message = JsonMessageCodec::GetInstance().EncodeMessage(args);
  messenger_->Send(channel_, message->data(), message->size());
}

}  // namespace flutter_desktop_embedding