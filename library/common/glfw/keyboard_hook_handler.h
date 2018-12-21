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
#ifndef LIBRARY_COMMON_GLFW_KEYBOARD_HOOK_HANDLER_H_
#define LIBRARY_COMMON_GLFW_KEYBOARD_HOOK_HANDLER_H_

#include <GLFW/glfw3.h>

namespace flutter_desktop_embedding {

// Abstract class for handling keyboard input events.
class KeyboardHookHandler {
 public:
  // A function for hooking into keyboard input.
  virtual void KeyboardHook(GLFWwindow *window, int key, int scancode,
                            int action, int mods) = 0;

  // A function for hooking into unicode code point input.
  virtual void CharHook(GLFWwindow *window, unsigned int code_point) = 0;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_GLFW_KEYBOARD_HOOK_HANDLER_H_
