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
#import <FlutterEmbedder/FlutterEmbedder.h>

#import "FLETexture.h"

/**
 * Used to bridge external FLETexture objects,
 * so the implementer only needs to return the CVPixelBufferRef object,
 * which will make the interface consistent with the FlutterTexture.
 */
@interface FLEExternalTexture : NSObject

/**
 *
 */
- (nonnull instancetype)initWithExternalTexture:(id<FLETexture>)external_texture;

/**
 * Accept texture rendering notifications from the flutter engine.
 */
- (BOOL)populateTextureWidth:(size_t)width
                      height:(size_t)height
                     texture:(FlutterOpenGLTexture *)texture;

/**
 *
 */
- (int64_t)textureId;

@property(nullable, weak) id<FLETexture> external_texture;

@end
