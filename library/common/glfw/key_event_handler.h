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
#ifndef LIBRARY_COMMON_GLFW_KEY_EVENT_HANDLER_H_
#define LIBRARY_COMMON_GLFW_KEY_EVENT_HANDLER_H_

#include <memory>

#include <json/json.h>

#include "library/common/client_wrapper/include/flutter_desktop_embedding/basic_message_channel.h"
#include "library/common/client_wrapper/include/flutter_desktop_embedding/binary_messenger.h"
#include "library/common/glfw/keyboard_hook_handler.h"

namespace flutter_desktop_embedding {

// Implements a KeyboardHookHandler
//
// Handles key events and forwards them to the Flutter engine.
class KeyEventHandler : public KeyboardHookHandler {
 public:
  explicit KeyEventHandler(BinaryMessenger *messenger);
  virtual ~KeyEventHandler();

  // KeyboardHookHandler.
  void KeyboardHook(GLFWwindow *window, int key, int scancode, int action,
                    int mods) override;
  void CharHook(GLFWwindow *window, unsigned int code_point) override;

 private:
  // The Flutter system channel for key event messages.
  std::unique_ptr<BasicMessageChannel<Json::Value>> channel_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_GLFW_KEY_EVENT_HANDLER_H_
