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

#import "FLEExternalTexture.h"

#import <AppKit/NSOpenGL.h>
#import <CoreVideo/CVOpenGLBuffer.h>
#import <CoreVideo/CVOpenGLTextureCache.h>
#import <OpenGL/gl.h>

@implementation FLEExternalTexture {
  CVOpenGLTextureCacheRef _textureCache;
  CVPixelBufferRef _pixelBuffer;
}

@synthesize external_texture;

- (instancetype)initWithExternalTexture:(id<FLETexture>)external_texture {
  self = [super init];

  if (self) {
    self.external_texture = external_texture;
  }

  return self;
}

static void OnGLTextureRelease(CVPixelBufferRef pixelBuffer) {
  CVPixelBufferRelease(pixelBuffer);
}

- (int64_t)textureId {
  return (NSInteger)(self);
}

- (BOOL)populateTextureWidth:(size_t)width
           height:(size_t)height
          texture:(FlutterOpenGLTexture *)texture {

  if(_pixelBuffer == NULL || external_texture == NULL){
    return NO;
  }

  // Copy image buffer from external texture.
  _pixelBuffer = [external_texture copyPixelBuffer];

  // Create the texture cache if necessary.
  if (_textureCache == NULL) {
    CGLContextObj context = [NSOpenGLContext currentContext].CGLContextObj;
    CGLPixelFormatObj format = CGLGetPixelFormat(context);
    if (CVOpenGLTextureCacheCreate(kCFAllocatorDefault, NULL, context, format, NULL, &_textureCache) != kCVReturnSuccess) {
      NSLog(@"Could not create texture cache.");
      CVPixelBufferRelease(_pixelBuffer);
      return NO;
    }
  }

  // Try to clear the cache of OpenGL textures to save memory.
  CVOpenGLTextureCacheFlush(_textureCache, 0);
  
  CVOpenGLTextureRef openGLTexture = NULL;
  if (CVOpenGLTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCache, _pixelBuffer, NULL, &openGLTexture) != kCVReturnSuccess) {
    CVPixelBufferRelease(_pixelBuffer);
    return NO;
  }

  texture->target = CVOpenGLTextureGetTarget(openGLTexture);
  texture->name = CVOpenGLTextureGetName(openGLTexture);
  texture->format = GL_RGBA8;
  texture->destruction_callback = (VoidCallback)&OnGLTextureRelease;
  texture->user_data = openGLTexture;

  CVPixelBufferRelease(_pixelBuffer);
  return YES;
}

- (void)dealloc {
  CVOpenGLTextureCacheRelease(_textureCache);
}

@end
