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
#include "plugins/file_chooser/linux/file_chooser_plugin.h"

#include <gtk/gtk.h>
#include <iostream>
#include <memory>
#include <vector>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar.h>
#include <flutter/standard_method_codec.h>

namespace plugins_file_chooser {

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

}  // namespace

class FileChooserPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar *registrar);

  virtual ~FileChooserPlugin();

 private:
  // Creates a plugin that communicates on the given channel.
  FileChooserPlugin(
      std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel);

  // Called when a method is called on |channel_|;
  void HandleMethodCall(
      const flutter::MethodCall<EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<EncodableValue>> result);

  // The MethodChannel used for communication with the Flutter engine.
  std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel_;
};

// Applies filters to the file chooser.
//
// Takes the method args and attempts to apply filters to the file chooser
// (in the event that they exist).
static void ProcessFilters(const EncodableMap &method_args,
                           GtkFileChooser *chooser) {
  const EncodableValue &allowed_file_types =
      ValueOrNull(method_args, kAllowedFileTypesKey);
  if (allowed_file_types.IsList() && !allowed_file_types.ListValue().empty()) {
    GtkFileFilter *filter = gtk_file_filter_new();
    const std::string comma_delimiter = ", ";
    const std::string file_wildcard = "*.";
    std::string filter_name = "";
    for (const EncodableValue &element : allowed_file_types.ListValue()) {
      std::string pattern = file_wildcard + element.StringValue();
      filter_name.append(pattern + comma_delimiter);
      gtk_file_filter_add_pattern(filter, pattern.c_str());
    }
    // Deletes trailing comma and space.
    filter_name.erase(filter_name.end() - comma_delimiter.size(),
                      filter_name.end());
    gtk_file_filter_set_name(filter, filter_name.c_str());
    gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(chooser), filter);
  }
}

// Applies attributes from method args to the file chooser.
//
// Take the method args and attempts to apply the possible attributes that
// would modify the file chooser: whether multiple files can be selected,
// whether a directory is a valid target, etc.
static void ProcessAttributes(const EncodableMap &method_args,
                              GtkFileChooser *chooser) {
  EncodableValue allow_multiple_selection =
      ValueOrNull(method_args, kAllowsMultipleSelectionKey);
  if (!allow_multiple_selection.IsNull()) {
    gtk_file_chooser_set_select_multiple(chooser,
                                         allow_multiple_selection.BoolValue());
  }
  EncodableValue choose_dirs =
      ValueOrNull(method_args, kCanChooseDirectoriesKey);
  if (!choose_dirs.IsNull() && choose_dirs.BoolValue()) {
    gtk_file_chooser_set_action(chooser, GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER);
  }
  EncodableValue start_dir = ValueOrNull(method_args, kInitialDirectoryKey);
  if (!start_dir.IsNull()) {
    gtk_file_chooser_set_current_folder(chooser,
                                        start_dir.StringValue().c_str());
  }
  EncodableValue initial_file_name =
      ValueOrNull(method_args, kInitialFileNameKey);
  if (!initial_file_name.IsNull()) {
    gtk_file_chooser_set_current_name(chooser,
                                      initial_file_name.StringValue().c_str());
  }
}

// Creates a file chooser based on the method type.
//
// If the method type is the open method (defined under kShowOpenFileMethod),
// then this returns a file opener dialog. If it is a kShowSaveFileMethod
// string, then this returns a file saver dialog.
//
// If the method is not recognized as one of those above, will return a nullptr.
static GtkWidget *CreateFileChooserFromMethod(const std::string &method,
                                              const std::string &ok_button) {
  GtkWidget *chooser = nullptr;
  if (method == kShowOpenPanelMethod) {
    GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_OPEN;
    chooser = gtk_file_chooser_dialog_new(
        "Open File", NULL, action,
        ok_button.empty() ? "_Open" : ok_button.c_str(), GTK_RESPONSE_ACCEPT,
        "_Cancel", GTK_RESPONSE_CANCEL, NULL);
  } else if (method == kShowSavePanelMethod) {
    GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_SAVE;
    chooser = gtk_file_chooser_dialog_new(
        "Save File", NULL, action,
        ok_button.empty() ? "_Save" : ok_button.c_str(), GTK_RESPONSE_ACCEPT,
        "_Cancel", GTK_RESPONSE_CANCEL, NULL);
  }
  return chooser;
}

// Creates a native file chooser based on the method specified.
//
// The args determine the modifications to the file chooser, like filters,
// being able to choose multiple files, etc.
static GtkWidget *CreateFileChooser(const std::string &method,
                                    const EncodableMap &args) {
  EncodableValue ok_button_value = ValueOrNull(args, kConfirmButtonTextKey);
  std::string ok_button_str;
  if (!ok_button_value.IsNull()) {
    ok_button_str = ok_button_value.StringValue();
  }
  GtkWidget *chooser = CreateFileChooserFromMethod(method, ok_button_str);
  if (chooser == nullptr) {
    std::cerr << "Could not determine method for file chooser from: " << method
              << std::endl;
    return chooser;
  }
  ProcessFilters(args, GTK_FILE_CHOOSER(chooser));
  ProcessAttributes(args, GTK_FILE_CHOOSER(chooser));
  return chooser;
}

// Creates a valid channel response object given the list of filenames.
//
// An empty array is treated as a cancelled operation.
static EncodableValue CreateResponseObject(
    const std::vector<std::string> &filenames) {
  if (filenames.empty()) {
    return EncodableValue();
  }
  EncodableList response;
  for (const std::string &filename : filenames) {
    response.push_back(EncodableValue(filename));
  }
  return EncodableValue(std::move(response));
}

// static
void FileChooserPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());
  auto *channel_pointer = channel.get();

  // Uses new instead of make_unique due to private constructor.
  std::unique_ptr<FileChooserPlugin> plugin(
      new FileChooserPlugin(std::move(channel)));

  channel_pointer->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  registrar->EnableInputBlockingForChannel(kChannelName);

  registrar->AddPlugin(std::move(plugin));
}

FileChooserPlugin::FileChooserPlugin(
    std::unique_ptr<flutter::MethodChannel<EncodableValue>> channel)
    : channel_(std::move(channel)) {}

FileChooserPlugin::~FileChooserPlugin() {}

void FileChooserPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  if (!method_call.arguments() || !method_call.arguments()->IsMap()) {
    result->Error("Bad Arguments", "Argument map missing or malformed");
    return;
  }

  auto chooser = CreateFileChooser(method_call.method_name(),
                                   method_call.arguments()->MapValue());
  if (chooser == nullptr) {
    result->NotImplemented();
    return;
  }
  gint chooser_result = gtk_dialog_run(GTK_DIALOG(chooser));
  std::vector<std::string> filenames;
  if (chooser_result == GTK_RESPONSE_ACCEPT) {
    GSList *files = gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(chooser));
    // Each filename must be freed, and then GSList afterward:
    //
    // See:
    // https://developer.gnome.org/gtk3/stable/GtkFileChooser.html#gtk-file-chooser-get-filenames
    for (GSList *iter = files; iter != nullptr; iter = iter->next) {
      std::string filename;
      gchar *g_filename = reinterpret_cast<gchar *>(iter->data);
      filename.assign(g_filename);
      g_free(g_filename);
      filenames.push_back(filename);
    }
    g_slist_free(files);
  }
  gtk_widget_destroy(chooser);

  EncodableValue response_object(CreateResponseObject(filenames));
  result->Success(&response_object);
}

}  // namespace plugins_file_chooser

void FileChooserRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  // The plugin registrar owns the plugin, registered callbacks, etc., so must
  // remain valid for the life of the application.
  static auto *plugin_registrar = new flutter::PluginRegistrar(registrar);
  plugins_file_chooser::FileChooserPlugin::RegisterWithRegistrar(
      plugin_registrar);
}
