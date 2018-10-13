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

#import <Cocoa/Cocoa.h>
#import <FlutterEmbedderMac/FlutterEmbedderMac.h>

/**
 * View capable of acting as a rendering target and input source for the Flutter
 * engine.
 */
@interface FLEView : NSOpenGLView <FLEOpenGLContextHandling>

/**
 * Listener for reshape events. See protocol description.
 */
@property(nonatomic, weak, nullable) IBOutlet id<FLEReshapeListener> reshapeListener;

@end
