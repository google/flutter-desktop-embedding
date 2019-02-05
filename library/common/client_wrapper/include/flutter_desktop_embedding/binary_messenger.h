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
#ifndef LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BINARY_MESSENGER_H_
#define LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BINARY_MESSENGER_H_

#include <functional>
#include <string>

// TODO: Consider adding absl as a dependency and using absl::Span for all of
// the message/message_size pairs.
namespace flutter_desktop_embedding {

// A binary message reply callback.
//
// Used for submitting a binary reply back to a Flutter message sender.
typedef std::function<void(const uint8_t *reply, const size_t reply_size)>
    BinaryReply;

// A message handler callback.
//
// Used for receiving messages from Flutter and providing an asynchronous reply.
typedef std::function<void(const uint8_t *message, const size_t message_size,
                           BinaryReply reply)>
    BinaryMessageHandler;

// A protocol for a class that handles communication of binary data on named
// channels to and from the Flutter engine.
class BinaryMessenger {
 public:
  // Sends a binary message to the Flutter side on the specified channel,
  // expecting no reply.
  //
  // TODO: Consider adding absl as a dependency and using absl::Span.
  virtual void Send(const std::string &channel, const uint8_t *message,
                    const size_t message_size) const = 0;

  // TODO: Add support for a version of Send expecting a reply once
  // https://github.com/flutter/flutter/issues/18852 is fixed.

  // Registers a message handler for incoming binary messages from the Flutter
  // side on the specified channel.
  //
  // Replaces any existing handler. Provide a null handler to unregister the
  // existing handler.
  virtual void SetMessageHandler(const std::string &channel,
                                 BinaryMessageHandler handler) = 0;
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_COMMON_CLIENT_WRAPPER_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BINARY_MESSENGER_H_
