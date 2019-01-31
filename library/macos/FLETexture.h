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

#import <Foundation/Foundation.h>
#import <CoreVideo/CVPixelBuffer.h>

@protocol FLETexture<NSObject>

- (nullable CVPixelBufferRef)copyPixelBuffer;

@end

@protocol FLETextureRegistrar<NSObject>

- (int64_t)registerTexture:(nonnull id<FLETexture>)texture;

- (void)textureFrameAvailable:(int64_t)textureId;

- (void)unregisterTexture:(int64_t)textureId;

@end
