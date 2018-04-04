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
#include <flutter_desktop_embedding/file_chooser_plugin.h>

#include <gtk/gtk.h>
#include <iostream>
#include <vector>

static constexpr char kChannelName[] = "flutter/filechooser";

// File chooser methods.
static constexpr char kFileOpenMethod[] = "FileChooser.Show.Open";
static constexpr char kFileSaveMethod[] = "FileChooser.Show.Save";

static constexpr char kArgumentsKey[] = "args";
static constexpr char kMethodKey[] = "method";

// File chooser args.
static constexpr char kAllowedFileTypesKey[] = "allowedFileTypes";
static constexpr char kAllowsMultipleSelectionKey[] = "allowsMultipleSelection";
static constexpr char kCanChooseDirectoriesKey[] = "canChooseDirectories";
static constexpr char kInitialDirectoryKey[] = "initialDirectory";
static constexpr char kClientIdKey[] = "clientID";

// File chooser callback methods.
static constexpr char kFileCallbackMethod[] = "FileChooser.Callback";

// File chooser callback args.
static constexpr char kPathsKey[] = "paths";
static constexpr char kResultKey[] = "result";

// File chooser callback results.
static constexpr int kCancelResultValue = 0;
static constexpr int kOkResultValue = 1;

namespace flutter_desktop_embedding {

// Applies filters to the file chooser.
//
// Takes the JSON method args and attempts to apply filters to the file chooser
// (in the event that they exist).
static void ProcessFilters(const Json::Value &method_args,
                           GtkFileChooser *chooser) {
  Json::Value allowed_file_types = method_args[kAllowedFileTypesKey];
  if (!allowed_file_types.empty() && allowed_file_types.isArray()) {
    GtkFileFilter *filter = gtk_file_filter_new();
    const std::string comma_delimiter = ", ";
    const std::string file_wildcard = "*.";
    std::string filter_name = "";
    for (const Json::Value &element : allowed_file_types) {
      std::string pattern = file_wildcard + element.asString();
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
// Take the JSON method args and attempts to apply the possible attributes that
// would modify the file chooser: whether multiple files can be selected,
// whether a directory is a valid target, etc.
static void ProcessAttributes(const Json::Value &method_args,
                              GtkFileChooser *chooser) {
  if (!method_args[kAllowsMultipleSelectionKey].isNull()) {
    gtk_file_chooser_set_select_multiple(
        chooser, method_args[kAllowsMultipleSelectionKey].asBool());
  }
  Json::Value choose_dirs = method_args[kCanChooseDirectoriesKey];
  if (!choose_dirs.isNull() && choose_dirs.asBool()) {
    gtk_file_chooser_set_action(chooser, GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER);
  }
  Json::Value start_dir = method_args[kInitialDirectoryKey];
  if (!start_dir.isNull()) {
    std::string start_dir_str(start_dir.asString());
    gtk_file_chooser_set_current_folder(chooser, start_dir_str.c_str());
  }
}

// Creates a file chooser based on the method type.
//
// If the method type is the open method (defined under kFileOpenMethod), then
// this returns a file opener dialog. If it is a kFileSaveMethod string, then
// this returns a file saver dialog.
//
// If the method is not recognized as one of those above, will return a nullptr.
static GtkFileChooserNative *CreateFileChooserFromMethod(
    const std::string &method) {
  GtkFileChooserNative *chooser = nullptr;
  if (method == kFileOpenMethod) {
    GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_OPEN;
    chooser = gtk_file_chooser_native_new("Open File", NULL, action, "_Open",
                                          "_Cancel");
  } else if (method == kFileSaveMethod) {
    GtkFileChooserAction action = GTK_FILE_CHOOSER_ACTION_SAVE;
    chooser = gtk_file_chooser_native_new("Save File", NULL, action, "_Save",
                                          "_Cancel");
  }
  return chooser;
}

// Creates a native file chooser based on the method specified.
//
// The JSON args determine the modifications to the file chooser, like filters,
// being able to choose multiple files, etc.
static GtkFileChooserNative *CreateFileChooser(const std::string &method,
                                               const Json::Value &args) {
  GtkFileChooserNative *chooser = CreateFileChooserFromMethod(method);
  if (chooser == nullptr) {
    std::cerr << "Could not determine method for file chooser from: " << method
              << std::endl;
    return chooser;
  }
  ProcessFilters(args, GTK_FILE_CHOOSER(chooser));
  ProcessAttributes(args, GTK_FILE_CHOOSER(chooser));
  return chooser;
}

// Creates a valid callback JSON object.
//
// This is based on the results of the file chooser termination.
static Json::Value CreateCallback(const std::vector<std::string> &filenames,
                                  gint chooser_res, const Json::Value &args) {
  Json::Value result;
  result[kMethodKey] = kFileCallbackMethod;
  result[kArgumentsKey] = Json::objectValue;
  if (chooser_res == GTK_RESPONSE_ACCEPT) {
    result[kArgumentsKey][kPathsKey] = Json::arrayValue;
    for (const std::string &filename : filenames) {
      result[kArgumentsKey][kPathsKey].append(filename);
    }
    result[kArgumentsKey][kResultKey] = kOkResultValue;
  } else {
    result[kArgumentsKey][kResultKey] = kCancelResultValue;
  }
  result[kArgumentsKey][kClientIdKey] = args[kClientIdKey];
  return result;
}

FileChooserPlugin::FileChooserPlugin() : Plugin(kChannelName, true) {}

FileChooserPlugin::~FileChooserPlugin() {}

Json::Value FileChooserPlugin::HandlePlatformMessage(
    const Json::Value &message) {
  Json::Value result;
  Json::Value method = message[kMethodKey];
  if (method.isNull()) {
    std::cerr << "No file chooser method declaration" << std::endl;
    return Json::nullValue;
  }
  Json::Value args = message[kArgumentsKey];
  if (args.isNull()) {
    std::cerr << "Null file chooser method args received" << std::endl;
    return Json::nullValue;
  }

  gint chooser_res;
  auto chooser = CreateFileChooser(method.asString(), args);
  if (chooser == nullptr) {
    return Json::nullValue;
  }
  chooser_res = gtk_native_dialog_run(GTK_NATIVE_DIALOG(chooser));
  std::vector<std::string> filenames;
  if (chooser_res == GTK_RESPONSE_ACCEPT) {
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
  g_object_unref(chooser);
  return CreateCallback(filenames, chooser_res, args);
}

}  // namespace flutter_desktop_embedding
