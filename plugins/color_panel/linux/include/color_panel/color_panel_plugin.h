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
#ifndef PLUGINS_COLOR_PANEL_LINUX_INCLUDE_COLOR_PANEL_COLOR_PANEL_PLUGIN_H_
#define PLUGINS_COLOR_PANEL_LINUX_INCLUDE_COLOR_PANEL_COLOR_PANEL_PLUGIN_H_
#include <flutter_desktop_embedding/plugin.h>

#include <memory>

namespace flutter_desktop_embedding {

// A plugin for communicating with a native color picker panel.
class ColorPanelPlugin : public Plugin {
 public:
  ColorPanelPlugin();
  virtual ~ColorPanelPlugin();

  void HandleMethodCall(const MethodCall &method_call,
                        std::unique_ptr<MethodResult> result) override;

 protected:
  // The source of a request to hide the panel, either a user action or
  // a programmatic request via the platform channel.
  enum class CloseRequestSource { kUserAction, kPlatformChannel };

  // Hides the color picker panel if it is showing.
  void HidePanel(CloseRequestSource source);

 private:
  // Private implementation.
  class ColorPanel;
  std::unique_ptr<ColorPanel> color_panel_;
};

}  // namespace flutter_desktop_embedding

#endif  // PLUGINS_COLOR_PANEL_LINUX_INCLUDE_COLOR_PANEL_COLOR_PANEL_PLUGIN_H_
