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
#ifndef LINUX_LIBRARY_SRC_INTERNAL_ENGINE_METHOD_RESULT_H_
#define LINUX_LIBRARY_SRC_INTERNAL_ENGINE_METHOD_RESULT_H_

#include <string>
#include <vector>

#include <flutter_embedder.h>

#include "linux/library/include/flutter_desktop_embedding/method_codec.h"
#include "linux/library/include/flutter_desktop_embedding/method_result.h"

namespace flutter_desktop_embedding {

// Implemention of MethodResult that sends responses to the Flutter egnine.
class EngineMethodResult : public MethodResult {
 public:
  // Creates a result object that will send results to |engine|, tagged as
  // associated with |response_handle|, encoded using |codec|. The |engine|
  // and |codec| pointers must remain valid for as long as this object exists.
  //
  // If the codec is null, only NotImplemented() may be called.
  EngineMethodResult(
      FlutterEngine engine,
      const FlutterPlatformMessageResponseHandle *response_handle,
      const MethodCodec *codec);
  ~EngineMethodResult();

 protected:
  // MethodResult:
  void SuccessInternal(const void *result) override;
  void ErrorInternal(const std::string &error_code,
                     const std::string &error_message,
                     const void *error_details) override;
  void NotImplementedInternal() override;

 private:
  // Sends the given response data (which must either be nullptr, which
  // indicates an unhandled method, or a response serialized with |codec_|) to
  // the engine.
  void SendResponseData(const std::vector<uint8_t> *data);

  FlutterEngine engine_;
  const FlutterPlatformMessageResponseHandle *response_handle_;
  const MethodCodec *codec_;
};

}  // namespace flutter_desktop_embedding

#endif  // LINUX_LIBRARY_SRC_INTERNAL_ENGINE_METHOD_RESULT_H_
