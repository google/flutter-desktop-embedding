#include <flutter/flutter_window_controller.h>
#include <linux/limits.h>
#include <unistd.h>

#include <cstdlib>
#include <iostream>
#include <memory>
#include <vector>

// For plugin-compatible event handling (e.g., modal windows).
#include <X11/Xlib.h>
#include <gtk/gtk.h>

#include "flutter/generated_plugin_registrant.h"
#include "window_configuration.h"

namespace {

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
  char buffer[PATH_MAX + 1];
  ssize_t length = readlink("/proc/self/exe", buffer, sizeof(buffer));
  if (length > PATH_MAX) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::string executable_path(buffer, length);
  size_t last_separator_position = executable_path.find_last_of('/');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path
              << std::endl;
    return "";
  }
  return executable_path.substr(0, last_separator_position);
}

}  // namespace

int main(int argc, char **argv) {
  // Resources are located relative to the executable.
  std::string base_directory = GetExecutableDirectory();
  if (base_directory.empty()) {
    base_directory = ".";
  }
  std::string data_directory = base_directory + "/data";
  std::string assets_path = data_directory + "/flutter_assets";
  std::string icu_data_path = data_directory + "/icudtl.dat";

  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;
#ifdef NDEBUG
  arguments.push_back("--disable-dart-asserts");
#endif

  flutter::FlutterWindowController flutter_controller(icu_data_path);
  flutter::WindowProperties window_properties = {};
  window_properties.title = kFlutterWindowTitle;
  window_properties.width = kFlutterWindowWidth;
  window_properties.height = kFlutterWindowHeight;

  // Start the engine.
  if (!flutter_controller.CreateWindow(window_properties, assets_path,
                                       arguments)) {
    return EXIT_FAILURE;
  }
  RegisterPlugins(&flutter_controller);

  // Set up for GTK event handling, needed by the GTK-based plugins.
  gtk_init(0, nullptr);
  XInitThreads();

  // Run until the window is closed, processing GTK events in parallel for
  // plugin handling.
  while (flutter_controller.RunEventLoopWithTimeout(
      std::chrono::milliseconds(10))) {
    if (gtk_events_pending()) {
      gtk_main_iteration();
    }
  }
  return EXIT_SUCCESS;
}
