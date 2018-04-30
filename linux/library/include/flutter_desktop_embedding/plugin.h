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
#ifndef LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_H_
#define LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_H_
#include <json/json.h>

#include <GLFW/glfw3.h>
#include <functional>
#include <string>

namespace flutter_desktop_embedding {

// A platform callback:
//
// Contains a channel string for the plugin and a JSON value to pass to the
// engine.
typedef std::function<void(const std::string &, const Json::Value &)>
    PlatformCallback;

// Represents a plugin that can be registered with the Flutter Embedder.
//
// A plugin listens on a platform channel and processes JSON requests that come
// in on said channel.  See https://flutter.io/platform-channels/ for more
// details on what these channels look like.
class Plugin {
 public:
  // Constructs a plugin for a given channel.
  //
  // |input_blocking| Determines whether user input should be blocked during the
  // duration of this plugin's platform callback handler (in most cases this
  // can be set to false).
  explicit Plugin(std::string channel, bool input_blocking = false)
      : channel_(channel),
        platform_callback_(nullptr),
        input_blocking_(input_blocking) {}
  virtual ~Plugin() {}

  // A function for hooking into keyboard input.
  virtual void KeyboardHook(GLFWwindow *window, int key, int scancode,
                            int action, int mods) {}

  // A function for hooking into unicode code point input.
  virtual void CharHook(GLFWwindow *window, unsigned int code_point) {}

  // Handles a platform message sent on this platform's channel.
  //
  // If some error has occurred or there is no valid response that can be
  // made, must return a Json::nullValue object.
  virtual Json::Value HandlePlatformMessage(const Json::Value &message) = 0;

  // Returns the channel on which this plugin listens.
  virtual std::string channel() const { return channel_; }

  // Determines whether this plugin blocks on input while it is running.
  //
  // If this is true, then the parent window should  disable input callbacks
  // while waiting for this plugin to handle its platform message.
  virtual bool input_blocking() const { return input_blocking_; }

  // Sets the platform callback.
  //
  // Called via the embedder to handle interaction with Flutter engine.
  virtual void set_platform_callback(PlatformCallback platform_callback) {
    platform_callback_ = platform_callback;
  }

 protected:
  // Runs the platform callback. Noop if the callback is not set.
  void CallPlatformCallback(const Json::Value &json) {
    if (platform_callback_) {
      platform_callback_(channel_, json);
    }
  }

 private:
  std::string channel_;
  PlatformCallback platform_callback_;
  bool input_blocking_;
};

}  // namespace flutter_desktop_embedding

#endif  // LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_H_
