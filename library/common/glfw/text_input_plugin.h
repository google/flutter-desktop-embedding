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
#ifndef LIBRARY_COMMON_GLFW_TEXT_INPUT_PLUGIN_H_
#define LIBRARY_COMMON_GLFW_TEXT_INPUT_PLUGIN_H_

#include <map>
#include <memory>

#include "library/common/client_wrapper/include/flutter_desktop_embedding/method_channel.h"
#include "library/common/client_wrapper/include/flutter_desktop_embedding/plugin_registrar.h"
#include "library/common/glfw/keyboard_hook_handler.h"
#include "library/common/internal/text_input_model.h"

namespace flutter_desktop_embedding {

// Implements a text input plugin.
//
// Specifically handles window events within GLFW.
class TextInputPlugin : public KeyboardHookHandler {
 public:
  TextInputPlugin(PluginRegistrar *registrar);
  virtual ~TextInputPlugin();

  // KeyboardHookHandler:
  void KeyboardHook(GLFWwindow *window, int key, int scancode, int action,
                    int mods) override;
  void CharHook(GLFWwindow *window, unsigned int code_point) override;

 private:
  // Sends the current state of the given model to the Flutter engine.
  void SendStateUpdate(const TextInputModel &model);

  // Sends an action triggered by the Enter key to the Flutter engine.
  void EnterPressed(TextInputModel *model);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(const MethodCall<Json::Value> &method_call,
                        std::unique_ptr<MethodResult<Json::Value>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<MethodChannel<Json::Value>> channel_;

  // Mapping of client IDs to text input models.
  std::map<int, std::unique_ptr<TextInputModel>> input_models_;

  // The active model. nullptr if not set.
  TextInputModel *active_model_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_GLFW_TEXT_INPUT_PLUGIN_H_
