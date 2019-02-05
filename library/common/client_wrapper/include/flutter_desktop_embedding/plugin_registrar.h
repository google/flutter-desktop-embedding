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
#ifndef LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_REGISTRAR_H_
#define LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_REGISTRAR_H_

#include <memory>

#include "binary_messenger.h"

namespace flutter_desktop_embedding {

class Plugin;

// A object managing the registration of a plugin for various events.
//
// Currently this class has very limited functionality, but is expected to
// expand over time to more closely match the functionality of
// the Flutter mobile plugin APIs' plugin registrars.
class PluginRegistrar {
 public:
  virtual ~PluginRegistrar() {}

  // Returns the messenger to use for creating channels to communicate with the
  // Flutter engine.
  //
  // This pointer must remain valid for the life of the plugin that this
  // registrar is used for.
  virtual BinaryMessenger *messenger() = 0;

  // Takes ownership of |plugin|.
  //
  // Plugins are not required to call this method if they have other lifetime
  // management, but this is a convient place for plugins to be owned to ensure
  // that they stay valid for any registered callbacks.
  virtual void AddPlugin(std::unique_ptr<Plugin> plugin) = 0;

  // Enables input blocking on the given channel name.
  //
  // If set, then the parent window should disable input callbacks
  // while waiting for the handler for messages on that channel to run.
  virtual void EnableInputBlockingForChannel(const std::string &channel) = 0;
};

// A plugin that can be registered for ownership by a PluginRegistrar.
class Plugin {
 public:
  virtual ~Plugin() {}
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_REGISTRAR_H_
