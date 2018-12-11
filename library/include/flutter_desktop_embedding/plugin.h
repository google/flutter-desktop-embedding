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
#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_H_

#include <functional>
#include <memory>
#include <string>

#include "binary_messenger.h"
#include "method_call.h"
#include "method_codec.h"
#include "method_result.h"

namespace flutter_desktop_embedding {

// Represents a plugin that can be registered with the Flutter Embedder.
//
// A plugin listens on a platform channel and processes requests that come
// in on said channel.  See https://flutter.io/platform-channels/ for more
// details on what these channels look like.
class Plugin {
 public:
  // Constructs a plugin for a given channel.
  //
  // |input_blocking| Determines whether user input should be blocked during the
  // duration of this plugin's platform callback handler (in most cases this
  // can be set to false).
  explicit Plugin(const std::string &channel, bool input_blocking = false);
  virtual ~Plugin();

  // Returns the codec to use for this plugin.
  virtual const MethodCodec &GetCodec() const = 0;

  // Handles a method call from Flutter on this platform's channel.
  //
  // Implementations must call exactly one of the methods on |result|,
  // exactly once. Failure to indicate a |result| is a memory leak.
  virtual void HandleMethodCall(const MethodCall &method_call,
                                std::unique_ptr<MethodResult> result) = 0;

  // Returns the channel on which this plugin listens.
  virtual std::string channel() const { return channel_; }

  // Determines whether this plugin blocks on input while it is running.
  //
  // If this is true, then the parent window should  disable input callbacks
  // while waiting for this plugin to handle its platform message.
  virtual bool input_blocking() const { return input_blocking_; }

  // Binds this plugin to the given caller-owned binary messenger. It must
  // remain valid for the life of the plugin.
  //
  // The embedder typically sets this pointer rather than the client.
  void SetBinaryMessenger(BinaryMessenger *messenger);

 protected:
  // Implementers should register any MethodChannels that should receive
  // messages from Flutter with |messenger| when this is called.
  virtual void RegisterMethodChannels(BinaryMessenger *messenger) = 0;

  // Calls a method in the Flutter engine on this Plugin's channel.
  //
  // Deprecated. Use MethodChannel's InvokeMethodCall instead.
  void InvokeMethodCall(const MethodCall &method_call);

 private:
  std::string channel_;
  // Caller-owned instance of the binary messenger used to message the engine.
  const BinaryMessenger *messenger_;
  bool input_blocking_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_PLUGIN_H_
