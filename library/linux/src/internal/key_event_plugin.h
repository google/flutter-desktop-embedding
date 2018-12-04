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
#ifndef LIBRARY_LINUX_SRC_INTERNAL_KEY_EVENT_PLUGIN_H_
#define LIBRARY_LINUX_SRC_INTERNAL_kEY_EVENT_PLUGIN_H_

#include "library/linux/include/flutter_desktop_embedding/binary_messenger.h"

#include "library/linux/src/internal/keyboard_hook_handler.h"

#include <memory>

namespace flutter_desktop_embedding {
class KeyEventPlugin : public KeyboardHookHandler {
 public:
  explicit KeyEventPlugin();
  virtual ~KeyEventPlugin();

  // KeyboardHookHandler.
  void KeyboardHook(GLFWwindow *window, int key, int scancode, int action,
                    int mods) override;

  // KeyboardHookHandler.
  void CharHook(GLFWwindow *window, unsigned int code_point) override;

  // Binds this plugin to the given caller-owned binary messenger. It must
  // remain valid for the life of the plugin.
  void SetBinaryMessenger(BinaryMessenger *messenger);

 private:
  const BinaryMessenger *messenger_;
  std::string channel_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_LINUX_SRC_INTERNAL_KEY_EVENT_PLUGIN_H_
