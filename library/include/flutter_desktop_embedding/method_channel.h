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
#ifndef LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CHANNEL_H_
#define LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CHANNEL_H_

#include <string>

#include "binary_messenger.h"
#include "method_call.h"
#include "method_codec.h"
#include "method_result.h"

namespace flutter_desktop_embedding {

// A handler for receiving a method call from the Flutter engine.
//
// Implementations must asynchronously call exactly one of the methods on
// |result| to indicate the resust of the method call.
typedef std::function<void(const MethodCall &call,
                           std::unique_ptr<MethodResult> result)>
    MethodCallHandler;

// A channel for communicating with the Flutter engine using invocation of
// asynchronous methods.
class MethodChannel {
 public:
  // Creates an instance that sends and receives method calls on the channel
  // named |name|, encoded with |codec| and dispatched via |messenger|.
  //
  // TODO: Make codec optional once the standard codec is supported (Issue #67).
  MethodChannel(BinaryMessenger *messenger, const std::string &name,
                const MethodCodec *codec);
  ~MethodChannel();

  // Prevent copying.
  MethodChannel(MethodChannel const &) = delete;
  MethodChannel &operator=(MethodChannel const &) = delete;

  // Sends |method_call| to the Flutter engine on this channel.
  //
  // TODO: Implement InovkeMethod and remove this. This is a temporary
  // implementation, since supporting InvokeMethod involves significant changes
  // to other classes.
  void InvokeMethodCall(const MethodCall &method_call) const;

  // TODO: Add support for a version expecting a reply once
  // https://github.com/flutter/flutter/issues/18852 is fixed.

  // Registers a handler that should be called any time a method call is
  // received on this channel.
  void SetMethodCallHandler(MethodCallHandler handler) const;

 private:
  BinaryMessenger *messenger_;
  std::string name_;
  const MethodCodec *codec_;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_METHOD_CHANNEL_H_
