// Copyright 2019 Google LLC
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
#include "file_chooser_plugin.h"

#include <ShObjIdl_core.h>
#include <flutter/flutter_view.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <codecvt>
#include <string>
#include <vector>

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// See channel_controller.dart for documentation.
const char kChannelName[] = "flutter/filechooser";
const char kShowOpenPanelMethod[] = "FileChooser.Show.Open";
const char kShowSavePanelMethod[] = "FileChooser.Show.Save";
const char kInitialDirectoryKey[] = "initialDirectory";
const char kInitialFileNameKey[] = "initialFileName";
const char kAllowedFileTypesKey[] = "allowedFileTypes";
const char kConfirmButtonTextKey[] = "confirmButtonText";
const char kAllowsMultipleSelectionKey[] = "allowsMultipleSelection";
const char kCanChooseDirectoriesKey[] = "canChooseDirectories";

// Returns the path for |shell_item| as a UTF-8 string, or an
// empty string on failure.
std::string GetPathForShellItem(IShellItem *shell_item) {
  PWSTR wide_path = nullptr;
  if (!SUCCEEDED(shell_item->GetDisplayName(SIGDN_FILESYSPATH, &wide_path))) {
    return "";
  }
  std::wstring_convert<std::codecvt_utf8<wchar_t>> wide_to_utf8;
  std::string path = wide_to_utf8.to_bytes(wide_path);
  CoTaskMemFree(wide_path);
  return path;
}

// Wraps an IFileDialog, managing object lifetime as a scoped object and
// providing a simplified API for interacting with it as needed for the plugin.
class DialogWrapper {
 public:
  DialogWrapper(IID type) {
    is_open_dialog_ = type == CLSID_FileOpenDialog;
    last_result_ = CoCreateInstance(type, NULL, CLSCTX_INPROC_SERVER,
                                    IID_PPV_ARGS(&dialog_));
  }

  ~DialogWrapper() {
    if (dialog_) {
      dialog_->Release();
    }
  }

  // Displays the dialog, and returns the selected file or files as an
  // EncodableValue of type List, or a null EncodableValue on error.
  EncodableValue Show(HWND parent_window) {
    assert(dialog_);
    last_result_ = dialog_->Show(parent_window);
    bool cancelled = last_result_ == HRESULT_FROM_WIN32(ERROR_CANCELLED);
    if (!cancelled && !SUCCEEDED(last_result_)) {
      return EncodableValue();
    }
    EncodableList files;
    if (!cancelled) {
      if (is_open_dialog_) {
        IFileOpenDialog *open_dialog;
        last_result_ = dialog_->QueryInterface(
            IID_IFileOpenDialog, reinterpret_cast<void **>(&open_dialog));
        if (!SUCCEEDED(last_result_)) {
          return EncodableValue();
        }
        IShellItemArray *shell_items;
        last_result_ = open_dialog->GetResults(&shell_items);
        open_dialog->Release();
        if (!SUCCEEDED(last_result_)) {
          return EncodableValue();
        }
        IEnumShellItems *item_enumerator;
        last_result_ = shell_items->EnumItems(&item_enumerator);
        if (!SUCCEEDED(last_result_)) {
          shell_items->Release();
          return EncodableValue();
        }
        IShellItem *shell_item;
        while (item_enumerator->Next(1, &shell_item, NULL) == S_OK) {
          files.push_back(EncodableValue(GetPathForShellItem(shell_item)));
          shell_item->Release();
        }
        item_enumerator->Release();
        shell_items->Release();
      } else {
        IShellItem *shell_item;
        last_result_ = dialog_->GetResult(&shell_item);
        if (!SUCCEEDED(last_result_)) {
          return EncodableValue();
        }
        files.push_back(EncodableValue(GetPathForShellItem(shell_item)));
        shell_item->Release();
      }
    }
    return EncodableValue(std::move(files));
  }

  // Returns the result of the last Win32 API call related to this object.
  HRESULT last_result() { return last_result_; }

 private:
  IFileDialog *dialog_;
  bool is_open_dialog_;
  HRESULT last_result_;
};

// Looks for |key| in |map|, returning the associated value if it is present, or
// a Null EncodableValue if not.
const EncodableValue &ValueOrNull(const EncodableMap &map, const char *key) {
  static EncodableValue null_value;
  auto it = map.find(EncodableValue(key));
  if (it == map.end()) {
    return null_value;
  }
  return it->second;
}

// Displays the open or save dialog (according to |type|) and sends the
// selected file path(s) back to the engine via |result|, or sends an
// error on failure.
//
// |result| is guaranteed to be resolved by this function.
void ShowDialog(
    IID type, HWND parent_window,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  DialogWrapper dialog(type);
  if (!SUCCEEDED(dialog.last_result())) {
    EncodableValue error_code(dialog.last_result());
    result->Error("System error", "Could not create dialog", &error_code);
    return;
  }
  EncodableValue files = dialog.Show(parent_window);
  if (files.IsNull()) {
    EncodableValue error_code(dialog.last_result());
    result->Error("System error", "Could not show dialog", &error_code);
  }
  EncodableValue response(std::move(files));
  result->Success(&response);
}

// Returns the top-level window that owns |view|.
HWND GetRootWindow(flutter::FlutterView *view) {
  return GetAncestor(view->GetNativeWindow(), GA_ROOT);
}

class FileChooserPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  // Creates a plugin that communicates on the given channel.
  FileChooserPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~FileChooserPlugin();

 private:
  // Called when a method is called on the plugin channel;
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // The registrar for this plugin, for accessing the window.
  flutter::PluginRegistrarWindows *registrar_;
};

// static
void FileChooserPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FileChooserPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FileChooserPlugin::FileChooserPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {}

FileChooserPlugin::~FileChooserPlugin(){};

void FileChooserPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  HWND window = GetRootWindow(registrar_->GetView());
  if (method_call.method_name().compare(kShowOpenPanelMethod) == 0) {
    ShowDialog(CLSID_FileOpenDialog, window, std::move(result));
  } else if (method_call.method_name().compare(kShowSavePanelMethod) == 0) {
    ShowDialog(CLSID_FileSaveDialog, window, std::move(result));
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void FileChooserPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar =
      new flutter::PluginRegistrarWindows(registrar);

  FileChooserPlugin::RegisterWithRegistrar(plugin_registrar);
}
