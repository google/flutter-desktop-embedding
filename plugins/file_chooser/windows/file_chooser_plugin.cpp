// Copyright 2020 Google LLC
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

// Converts an null-terminated array of Windows wchar_t's (UTF-16)
// to a std::string.
std::string StdStringFromWideChars(const wchar_t *wide_chars) {
  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> wide_to_utf8;
  return wide_to_utf8.to_bytes(wide_chars);
}

// Converts a UTF-8 character array to a Windows std::wstring (UTF-16).
std::wstring WideStringFromChars(const char *chars) {
  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> wide_to_utf8;
  return wide_to_utf8.from_bytes(chars);
}

// Returns the path for |shell_item| as a UTF-8 string, or an
// empty string on failure.
std::string GetPathForShellItem(IShellItem *shell_item) {
  wchar_t *wide_path = nullptr;
  if (!SUCCEEDED(shell_item->GetDisplayName(SIGDN_FILESYSPATH, &wide_path))) {
    return "";
  }
  std::string path = StdStringFromWideChars(wide_path);
  CoTaskMemFree(wide_path);
  return path;
}

// Wraps an IFileDialog, managing object lifetime as a scoped object and
// providing a simplified API for interacting with it as needed for the plugin.
class DialogWrapper {
 public:
  DialogWrapper(IID type) {
    is_open_dialog_ = type == CLSID_FileOpenDialog;
    last_result_ = CoCreateInstance(type, nullptr, CLSCTX_INPROC_SERVER,
                                    IID_PPV_ARGS(&dialog_));
  }

  ~DialogWrapper() {
    if (dialog_) {
      dialog_->Release();
    }
  }

  // Attempts to set the default folder for the dialog to |path|,
  // if it exists.
  void SetDefaultFolder(const std::string &path) {
    std::wstring wide_path = WideStringFromChars(path.c_str());
    IShellItem *item;
    last_result_ = SHCreateItemFromParsingName(wide_path.c_str(), nullptr,
                                               IID_PPV_ARGS(&item));
    if (!SUCCEEDED(last_result_)) {
      return;
    }
    dialog_->SetDefaultFolder(item);
    item->Release();
  }

  // Sets the file name that is initially shown in the dialog.
  void SetFileName(const std::string &name) {
    std::wstring wide_name = WideStringFromChars(name.c_str());
    last_result_ = dialog_->SetFileName(wide_name.c_str());
  }

  // Sets the label of the confirmation button.
  void SetOkButtonLabel(const std::string &label) {
    std::wstring wide_label = WideStringFromChars(label.c_str());
    last_result_ = dialog_->SetOkButtonLabel(wide_label.c_str());
  }

  // Adds the given options to the dialog's current option set.
  void AddOptions(FILEOPENDIALOGOPTIONS new_options) {
    FILEOPENDIALOGOPTIONS options;
    last_result_ = dialog_->GetOptions(&options);
    if (!SUCCEEDED(last_result_)) {
      return;
    }
    options |= new_options;
    last_result_ = dialog_->SetOptions(options);
  }

  // Sets the filters for allowed file types to select.
  void SetFileTypeFilters(const EncodableList &filters) {
    const std::wstring spec_delimiter = L";";
    const std::wstring file_wildcard = L"*.";
    std::vector<COMDLG_FILTERSPEC> filter_specs;
    // Temporary ownership of the constructed strings whose data is used in
    // filter_specs, so that they live until the call to SetFileTypes is done.
    std::vector<std::wstring> filter_names;
    std::vector<std::wstring> filter_extensions;
    filter_extensions.reserve(filters.size());
    filter_names.reserve(filters.size());

    for (const EncodableValue &filter_info : filters) {
      filter_names.push_back(WideStringFromChars(
          filter_info.ListValue()[0].StringValue().c_str()));
      filter_extensions.push_back(L"");
      EncodableList extensions = filter_info.ListValue()[1].ListValue();
      std::wstring &spec = filter_extensions.back();
      if (extensions.empty()) {
        spec += L"*.*";
      } else {
        for (const EncodableValue &extension : extensions) {
          if (!spec.empty()) {
            spec += spec_delimiter;
          }
          spec += file_wildcard +
                  WideStringFromChars(extension.StringValue().c_str());
        }
      }
      filter_specs.push_back({filter_names.back().c_str(), spec.c_str()});
    }
    last_result_ = dialog_->SetFileTypes(static_cast<UINT>(filter_specs.size()),
                                         filter_specs.data());
  }

  // Displays the dialog, and returns the selected file or files as an
  // EncodableValue of type List, or a null EncodableValue on cancel or
  // error.
  EncodableValue Show(HWND parent_window) {
    assert(dialog_);
    last_result_ = dialog_->Show(parent_window);
    if (!SUCCEEDED(last_result_)) {
      return EncodableValue();
    }
    EncodableList files;
    if (is_open_dialog_) {
      IFileOpenDialog *open_dialog;
      last_result_ = dialog_->QueryInterface(IID_PPV_ARGS(&open_dialog));
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
      while (item_enumerator->Next(1, &shell_item, nullptr) == S_OK) {
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
    IID type, HWND parent_window, const EncodableMap &args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  DialogWrapper dialog(type);
  if (!SUCCEEDED(dialog.last_result())) {
    EncodableValue error_code(dialog.last_result());
    result->Error("System error", "Could not create dialog", &error_code);
    return;
  }

  FILEOPENDIALOGOPTIONS dialog_options = 0;
  EncodableValue allow_multiple_selection =
      ValueOrNull(args, kAllowsMultipleSelectionKey);
  if (!allow_multiple_selection.IsNull() &&
      allow_multiple_selection.BoolValue()) {
    dialog_options |= FOS_ALLOWMULTISELECT;
  }
  EncodableValue choose_dirs = ValueOrNull(args, kCanChooseDirectoriesKey);
  if (!choose_dirs.IsNull() && choose_dirs.BoolValue()) {
    dialog_options |= FOS_PICKFOLDERS;
  }
  if (dialog_options != 0) {
    dialog.AddOptions(dialog_options);
  }

  EncodableValue start_dir = ValueOrNull(args, kInitialDirectoryKey);
  if (!start_dir.IsNull()) {
    dialog.SetDefaultFolder(start_dir.StringValue());
  }
  EncodableValue initial_file_name = ValueOrNull(args, kInitialFileNameKey);
  if (!initial_file_name.IsNull()) {
    dialog.SetFileName(initial_file_name.StringValue());
  }
  EncodableValue confirm_label = ValueOrNull(args, kConfirmButtonTextKey);
  if (!confirm_label.IsNull()) {
    dialog.SetOkButtonLabel(confirm_label.StringValue());
  }
  EncodableValue allowed_types = ValueOrNull(args, kAllowedFileTypesKey);
  if (!allowed_types.IsNull() && !allowed_types.ListValue().empty()) {
    dialog.SetFileTypeFilters(allowed_types.ListValue());
  }

  EncodableValue files = dialog.Show(parent_window);
  if (files.IsNull() &&
      dialog.last_result() != HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
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

FileChooserPlugin::~FileChooserPlugin() {}

void FileChooserPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare(kShowOpenPanelMethod) == 0 ||
      method_call.method_name().compare(kShowSavePanelMethod) == 0) {
    if (!method_call.arguments() || !method_call.arguments()->IsMap()) {
      result->Error("Bad Arguments", "Argument map missing or malformed");
      return;
    }
    IID dialog_type =
        method_call.method_name().compare(kShowOpenPanelMethod) == 0
            ? CLSID_FileOpenDialog
            : CLSID_FileSaveDialog;
    ShowDialog(dialog_type, GetRootWindow(registrar_->GetView()),
               method_call.arguments()->MapValue(), std::move(result));
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void FileChooserPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  FileChooserPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
