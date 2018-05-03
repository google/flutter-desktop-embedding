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

#include <functional>
#include <string>

#include <embedder.h>

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
      : channel_(channel), engine_(nullptr), input_blocking_(input_blocking) {}
  virtual ~Plugin() {}

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

  // Sets the pointer to the caller-owned Flutter Engine.
  //
  // The embedder typically sets this pointer rather than the client.
  virtual void set_flutter_engine(FlutterEngine engine) { engine_ = engine; }

 protected:
  // Runs the platform callback. Noop if the callback is not set.
  void CallPlatformCallback(const Json::Value &json) {
    if (!engine_) {
      return;
    }
    Json::StreamWriterBuilder writer_builder;
    std::string output = Json::writeString(writer_builder, json);
    FlutterPlatformMessage platform_message_response = {
        .struct_size = sizeof(FlutterPlatformMessage),
        .channel = channel_.c_str(),
        .message = reinterpret_cast<const uint8_t *>(output.c_str()),
        .message_size = output.size(),
    };
    FlutterEngineSendPlatformMessage(engine_, &platform_message_response);
  }

 private:
  std::string channel_;
  // Caller-owned instance of the Flutter Engine.
  FlutterEngine engine_;
  bool input_blocking_;
};

}  // namespace flutter_desktop_embedding

#endif  // LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_H_
