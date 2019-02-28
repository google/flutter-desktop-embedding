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
#include "flutter_desktop_embedding/plugin_registrar.h"

#include "flutter_desktop_embedding/engine_method_result.h"
#include "flutter_desktop_embedding/method_channel.h"

#include <iostream>
#include <map>

namespace flutter_desktop_embedding {

namespace {

// Passes |message| to |user_data|, which must be a BinaryMessageHandler, along
// with a BinaryReply that will send a response on |message|'s response handle.
//
// This serves as an adaptor between the function-pointer-based message callback
// interface provided by embedder.h and the std::function-based message handler
// interface of BinaryMessenger.
void ForwardToHandler(FlutterEmbedderMessengerRef messenger,
                      const FlutterEmbedderMessage *message, void *user_data) {
  auto *response_handle = message->response_handle;
  BinaryReply reply_handler = [messenger, response_handle](
                                  const uint8_t *reply,
                                  const size_t reply_size) mutable {
    if (!response_handle) {
      std::cerr << "Error: Response can be set only once. Ignoring "
                   "duplicate response."
                << std::endl;
      return;
    }
    FlutterEmbedderMessengerSendResponse(messenger, response_handle, reply,
                                         reply_size);
    // The engine frees the response handle once
    // FlutterEmbedderSendMessageResponse is called.
    response_handle = nullptr;
  };

  const BinaryMessageHandler &message_handler =
      *static_cast<BinaryMessageHandler *>(user_data);

  message_handler(message->message, message->message_size,
                  std::move(reply_handler));
}

}  // namespace

// Wrapper around a FlutterEmbedderMessengerRef that implements the
// BinaryMessenger API.
class BinaryMessengerImpl : public BinaryMessenger {
 public:
  explicit BinaryMessengerImpl(FlutterEmbedderMessengerRef core_messenger)
      : messenger_(core_messenger) {}
  virtual ~BinaryMessengerImpl() {}

  // Prevent copying.
  BinaryMessengerImpl(BinaryMessengerImpl const &) = delete;
  BinaryMessengerImpl &operator=(BinaryMessengerImpl const &) = delete;

  // BinaryMessenger implementation:
  void Send(const std::string &channel, const uint8_t *message,
            const size_t message_size) const override;
  void SetMessageHandler(const std::string &channel,
                         BinaryMessageHandler handler) override;

 private:
  // Handle for interacting with the core embedding API.
  FlutterEmbedderMessengerRef messenger_;

  // A map from channel names to the BinaryMessageHandler that should be called
  // for incoming messages on that channel.
  std::map<std::string, BinaryMessageHandler> handlers_;
};

void BinaryMessengerImpl::Send(const std::string &channel,
                               const uint8_t *message,
                               const size_t message_size) const {
  FlutterEmbedderMessengerSend(messenger_, channel.c_str(), message,
                               message_size);
}

void BinaryMessengerImpl::SetMessageHandler(const std::string &channel,
                                            BinaryMessageHandler handler) {
  if (!handler) {
    handlers_.erase(channel);
    FlutterEmbedderMessengerSetCallback(messenger_, channel.c_str(), nullptr,
                                        nullptr);
    return;
  }
  // Save the handler, to keep it alive.
  handlers_[channel] = std::move(handler);
  BinaryMessageHandler *message_handler = &handlers_[channel];
  // Set an adaptor callback that will invoke the handler.
  FlutterEmbedderMessengerSetCallback(messenger_, channel.c_str(),
                                      ForwardToHandler, message_handler);
}

// PluginRegistrar:

PluginRegistrar::PluginRegistrar(FlutterEmbedderPluginRegistrarRef registrar)
    : registrar_(registrar) {
  auto core_messenger = FlutterEmbedderRegistrarGetMessenger(registrar_);
  messenger_ = std::make_unique<BinaryMessengerImpl>(core_messenger);
}

PluginRegistrar::~PluginRegistrar() {}

void PluginRegistrar::AddPlugin(std::unique_ptr<Plugin> plugin) {
  plugins_.insert(std::move(plugin));
}

void PluginRegistrar::EnableInputBlockingForChannel(
    const std::string &channel) {
  FlutterEmbedderRegistrarEnableInputBlocking(registrar_, channel.c_str());
}

}  // namespace flutter_desktop_embedding
