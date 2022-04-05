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

#ifndef FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_
#define FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace menubar {

class MenubarPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MenubarPlugin();

  virtual ~MenubarPlugin();

  // Disallow copy and assign.
  MenubarPlugin(const MenubarPlugin &) = delete;
  MenubarPlugin &operator=(const MenubarPlugin &) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Fills |menu| with items constructed from the given method channel
  // representation of a menu.
  //
  // On failure, returns an EncodableValue with error details.
  static std::optional<EncodableValue> PopulateMenu(
      HMENU menu, const EncodableList &representation);

  // Constructs a menu item corresponding to the item in |representation|,
  // including recursively creating children if it has a submenu, and adds it to
  // |menu|.
  //
  // On failure, returns an EncodableValue with error details.
  static std::optional<EncodableValue> AddMenuItem(
      HMENU menu, const EncodableMap &representation);

  // Called for top-level WindowProc delegation.
  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam);

  // The registrar for this plugin.
  flutter::PluginRegistrarWindows *registrar_;

  // The cannel to send menu item activations on.
  std::unique_ptr<flutter::MethodChannel<>> channel_;

  // The ID of the registered WindowProc handler.
  int window_proc_id_;
};

}  // namespace menubar

#endif  // FLUTTER_PLUGIN_MENUBAR_PLUGIN_H_
