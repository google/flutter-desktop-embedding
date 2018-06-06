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
#ifndef LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CHANNELS_H_
#define LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CHANNELS_H_

#include <json/json.h>

#include <memory>
#include <string>

#include <flutter_embedder.h>

namespace flutter_desktop_embedding {

// An object encapsulating a method call from Flutter.
// TODO: Move serialization details into a method codec class, to match mobile
// Flutter plugin APIs.
class MethodCall {
 public:
  // Creates a MethodCall with the given name and, optionally, arguments.
  explicit MethodCall(const std::string &method_name,
                      const Json::Value &arguments = Json::Value());

  // Returns a new MethodCall created from a JSON message received from the
  // Flutter engine.
  static std::unique_ptr<MethodCall> CreateFromMessage(
      const Json::Value &message);
  ~MethodCall();

  // The name of the method being called.
  const std::string &method_name() const { return method_name_; }

  // The arguments to the method call, or a nullValue if there are none.
  const Json::Value &arguments() const { return arguments_; }

  // Returns a version of the method call serialized in the format expected by
  // the Flutter engine.
  Json::Value AsMessage() const;

 private:
  std::string method_name_;
  Json::Value arguments_;
};

// Encapsulates a result sent back to the Flutter engine in response to a
// MethodCall. Only one method should be called on any given instance.
class MethodResult {
 public:
  // Sends a success response, indicating that the call completed successfully.
  // An optional value can be provided as part of the success message.
  void Success(const Json::Value &result = Json::Value());

  // Sends an error response, indicating that the call was understood but
  // handling failed in some way. A string error code must be provided, and in
  // addition an optional user-readable error_message and/or details object can
  // be included.
  void Error(const std::string &error_code,
             const std::string &error_message = "",
             const Json::Value &error_details = Json::Value());

  // Sends a not-implemented response, indicating that the method either was not
  // recognized, or has not been implemented.
  void NotImplemented();

 protected:
  // Internal implementation of the interface methods above, to be implemented
  // in subclasses.
  virtual void SuccessInternal(const Json::Value &result) = 0;
  virtual void ErrorInternal(const std::string &error_code,
                             const std::string &error_message,
                             const Json::Value &error_details) = 0;
  virtual void NotImplementedInternal() = 0;
};

// Implemention of MethodResult using JSON as the protocol.
// TODO: Move this logic into method codecs.
class JsonMethodResult : public MethodResult {
 public:
  // Creates a result object that will send results to |engine|, tagged as
  // associated with |response_handle|. The engine pointer must remain valid for
  // as long as this object exists.
  JsonMethodResult(FlutterEngine engine,
                   const FlutterPlatformMessageResponseHandle *response_handle);
  ~JsonMethodResult();

 protected:
  void SuccessInternal(const Json::Value &result) override;
  void ErrorInternal(const std::string &error_code,
                     const std::string &error_message,
                     const Json::Value &error_details) override;
  void NotImplementedInternal() override;

 private:
  // Sends the given JSON response object to the engine.
  void SendResponseJson(const Json::Value &response);

  // Sends the given response data (which must either be nullptr or a serialized
  // JSON response) to the engine.
  // Uses a pointer rather than a reference since nullptr is used to indicate
  // not-implemented (which is represented to Flutter by no data).
  void SendResponse(const std::string *serialized_response);

  FlutterEngine engine_;
  const FlutterPlatformMessageResponseHandle *response_handle_;
};

}  // namespace flutter_desktop_embedding

#endif  // LINUX_INCLUDE_FLUTTER_DESKTOP_EMBEDDING_CHANNELS_H_
