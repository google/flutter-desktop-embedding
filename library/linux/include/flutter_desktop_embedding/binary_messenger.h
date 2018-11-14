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
#ifndef LIBRARY_LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BINARY_MESSENGER_H_
#define LIBRARY_LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BINARY_MESSENGER_H_

#include <string>

namespace flutter_desktop_embedding {

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

  // TODO: Add SetMessageHandler. See Issue #102.
};

}  // namespace flutter_desktop_embedding

#endif  // LIBRARY_LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_BINARY_MESSENGER_H_
