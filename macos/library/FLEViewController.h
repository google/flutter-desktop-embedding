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

#import "FLEOpenGLContextHandling.h"
#import "FLEPlugin.h"

/**
 * Controls embedder plugins and communication with the underlying Flutter engine, managing a view
 * intended to handle key inputs and drawing protocols (see |view|).
 *
 * Can be launched headless (no managed view), at which point a Dart executable will be run on the
 * Flutter engine in non-interactive mode, or with a drawable Flutter canvas.
 */
@interface FLEViewController : NSViewController

/**
 * The view this controller manages when launched in interactive mode (headless set to false). Must
 * be capable of handling text input events, and the OpenGL context handling protocols.
 */
@property(nullable) NSView<FLEOpenGLContextHandling> *view;

/**
 * Launches the Flutter engine in snapshot mode with the provided configuration. The path argument
 * is used to identify the Flutter application the engine should be configured with. See
 * https://github.com/flutter/engine/wiki/Custom-Flutter-Engine-Embedders for more information
 * on embedding, including the meaning of various possible arguments.
 *
 * In snapshot mode, the snapshot in the assets directory will be used instead of the original
 * dart sources.
 */
- (BOOL)launchEngineWithAssetsPath:(nonnull NSURL *)assets
                        asHeadless:(BOOL)headless
              commandLineArguments:(nonnull NSArray<NSString *> *)arguments;

/**
 * Launches the Flutter engine in source mode with the provided configuration. The path arguments
 * are used to identify the Flutter application the engine should be configured with. See
 * https://github.com/flutter/engine/wiki/Custom-Flutter-Engine-Embedders for more information
 * on embedding, including the meaning of various possible arguments.
 *
 * In source mode, the Dart source and its dependencies will be read directly from their locations
 * on disk.
 * TODO: Evaluate whether this mode needs to be present in the long term, and if so reconsider this
 * API structure.
 */
- (BOOL)launchEngineWithMainPath:(nonnull NSURL *)main
                      assetsPath:(nonnull NSURL *)assets
                    packagesPath:(nonnull NSURL *)packages
                      asHeadless:(BOOL)headless
            commandLineArguments:(nonnull NSArray<NSString *> *)arguments;

/**
 * Adds a plugin to the view controller to handle domain-specific system messages. The plugin's
 * channel property will determine which system channel the plugin operates on. Only one plugin
 * can operate on a given named channel; if two plugins declare the same channel, the second
 * add will return NO.
 */
- (BOOL)addPlugin:(nonnull id<FLEPlugin>)plugin;

/**
 * Sends a platform message to the Flutter engine on the given channel.
 *
 * // TODO: Support responses.
 */
- (void)invokeMethod:(nonnull NSString *)method
           arguments:(nullable id)arguments
           onChannel:(nonnull NSString *)channel;

@end
