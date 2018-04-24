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
#ifndef LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_COLOR_PICKER_PLUGIN_H_
#define LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_COLOR_PICKER_PLUGIN_H_
#include "plugin.h"

#include <memory>

namespace flutter_desktop_embedding {

// Implements a color picker plugin.
class ColorPickerPlugin : public Plugin {
 public:
  explicit ColorPickerPlugin(PlatformCallback platform_callback);
  virtual ~ColorPickerPlugin();

  Json::Value HandlePlatformMessage(const Json::Value &message) override;

 private:
  // Private implementation.
  class ColorPicker;
  std::unique_ptr<ColorPicker> color_picker_;
};

}  // namespace flutter_desktop_embedding

#endif  // LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_COLOR_PICKER_PLUGIN_H_
