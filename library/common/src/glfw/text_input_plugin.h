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
#ifndef LIBRARY_LINUX_SRC_INTERNAL_TEXT_INPUT_PLUGIN_H_
#define LIBRARY_LINUX_SRC_INTERNAL_TEXT_INPUT_PLUGIN_H_

#include <map>
#include <memory>

#include "library/common/include/flutter_desktop_embedding/json_plugin.h"
#include "library/common/src/glfw/keyboard_hook_handler.h"
#include "library/common/src/internal/text_input_model.h"

namespace flutter_desktop_embedding {

// Implements a text input plugin.
//
// Specifically handles window events within GLFW.
class TextInputPlugin : public KeyboardHookHandler, public JsonPlugin {
 public:
  TextInputPlugin();
  virtual ~TextInputPlugin();

  // Plugin.
  void HandleJsonMethodCall(const JsonMethodCall &method_call,
                            std::unique_ptr<MethodResult> result) override;

  // KeyboardHookHandler.
  void KeyboardHook(GLFWwindow *window, int key, int scancode, int action,
                    int mods) override;

  // KeyboardHookHandler.
  void CharHook(GLFWwindow *window, unsigned int code_point) override;

 private:
  // Sends the current state of the given model to the Flutter engine.
  void SendStateUpdate(const TextInputModel &model);

  // Sends an action triggered by the Enter key to the Flutter engine.
  void EnterPressed(const TextInputModel &model);

  // Mapping of client IDs to text input models.
  std::map<int, std::unique_ptr<TextInputModel>> input_models_;

  // The active model. nullptr if not set.
  TextInputModel *active_model_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_LINUX_SRC_INTERNAL_TEXT_INPUT_PLUGIN_H_
