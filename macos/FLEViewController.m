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

#import "FLEViewController.h"

#import <FlutterEmbedder/FlutterEmbedder.h>
#import "FLEColorPanelPlugin.h"
#import "FLEReshapeListener.h"
#import "FLETextInputPlugin.h"
#import "FLEView.h"

static NSString *const kXcodeExtraArgumentOne = @"-NSDocumentRevisionsDebugMode";
static NSString *const kXcodeExtraArgumentTwo = @"YES";

static NSString *const kICUBundleID = @"io.flutter.flutter_embedder";
static NSString *const kICUBundlePath = @"icudtl.dat";

static const int kDefaultWindowFramebuffer = 0;

#pragma mark - Private interface declaration.

/**
 * Private interface declaration for FLEViewController.
 */
@interface FLEViewController ()<FLEReshapeListener>

/**
 * Responds to system messages sent to this controller from the Flutter engine.
 * Invoked from a static method provided in the engine configuration, thus must be
 * explicitly declared.
 */
- (void)handlePlatformMessage:(const FlutterPlatformMessage *)message;

@property NSMutableDictionary<NSString *, id<FLEPlugin>> *plugins;

@end

#pragma mark - Static methods provided to engine configuration.

/**
 * Makes the owned FlutterView the current context.
 */
static bool OnMakeCurrent(FLEViewController *controller) {
  [controller.view makeCurrentContext];
  return true;
}

/**
 * Clears the current context.
 */
static bool OnClearCurrent(FLEViewController *controller) {
  [controller.view clearCurrentContext];
  return true;
}

/**
 * Flushes the GL context as part of the Flutter rendering pipeline.
 */
static bool OnPresent(FLEViewController *controller) {
  [controller.view onPresent];
  return true;
}

/**
 * Returns the framebuffer object whose color attachment the engine should render into.
 */
static uint32_t OnFBO(FLEViewController *controller) { return kDefaultWindowFramebuffer; }

/**
 * Handles the given platform message by dispatching to the controller.
 */
static void OnPlatformMessage(const FlutterPlatformMessage *message,
                              FLEViewController *controller) {
  [controller handlePlatformMessage:message];
}

#pragma mark - Static methods provided for headless engine configuration.

static bool HeadlessOnMakeCurrent(FLEViewController *controller) { return false; }

static bool HeadlessOnClearCurrent(FLEViewController *controller) { return false; }

static bool HeadlessOnPresent(FLEViewController *controller) { return false; }

static uint32_t HeadlessOnFBO(FLEViewController *controller) { return kDefaultWindowFramebuffer; }

#pragma mark - FLEViewController implementation.

@implementation FLEViewController {
  FlutterEngine _engine;
}

@dynamic view;

#pragma mark - Public methods.

- (BOOL)launchEngineWithMainPath:(nonnull NSURL *)main
                      assetsPath:(nonnull NSURL *)assets
                    packagesPath:(nonnull NSURL *)packages
                      asHeadless:(BOOL)headless
            commandLineArguments:(nonnull NSArray<NSString *> *)arguments {
  if (_engine != NULL) {
    return NO;
  }

  const FlutterRendererConfig config = [FLEViewController createRenderConfigHeadless:headless];

  // Strip out the Xcode-added -NSDocumentRevisionsDebugMode YES.
  // TODO: Improve command line argument handling.
  const unsigned long argc = arguments.count;
  unsigned long unused = 0;
  const char **command_line_args = (const char **)malloc(argc * sizeof(const char *));
  for (int i = 0; i < argc; ++i) {
    if ([arguments[i] isEqualToString:kXcodeExtraArgumentOne] && (i + 1 < argc) &&
        [arguments[i + 1] isEqualToString:kXcodeExtraArgumentTwo]) {
      unused += 2;
      ++i;
      continue;
    }
    command_line_args[i - unused] = [arguments[i] UTF8String];
  }

  NSString *icuData =
      [[NSBundle bundleWithIdentifier:kICUBundleID] pathForResource:kICUBundlePath ofType:nil];

  const FlutterProjectArgs args = {
      .struct_size = sizeof(FlutterProjectArgs),
      .assets_path = assets.fileSystemRepresentation,
      .main_path = main.fileSystemRepresentation,
      .packages_path = packages.fileSystemRepresentation,
      .icu_data_path = icuData.UTF8String,
      .command_line_argc = (int)(argc - unused),
      .command_line_argv = command_line_args,
      .platform_message_callback = (FlutterPlatformMessageCallback)OnPlatformMessage,
  };

  BOOL result = FlutterEngineRun(FLUTTER_ENGINE_VERSION, &config, &args, (__bridge void *)(self),
                                 &_engine) == kSuccess;
  free(command_line_args);
  return result;
}

/**
 * Adds a plugin to the view controller to handle domain-specific system messages.
 * This private method is called both during and after init.
 */
- (BOOL)_addPlugin:(nonnull id<FLEPlugin>)plugin {
  NSString *channel = plugin.channel;
  if (_plugins[channel] != nil) {
    NSLog(@"Warning: channel %@ already has an associated plugin", channel);
    return NO;
  }
  _plugins[channel] = plugin;
  plugin.controller = self;
  return YES;
}

- (BOOL)addPlugin:(nonnull id<FLEPlugin>)plugin {
  return [self _addPlugin:plugin];
}

- (BOOL)sendPlatformMessage:(nonnull NSData *)message onChannel:(nonnull NSString *)channel {
  FlutterPlatformMessage platformMessage = {
      .struct_size = sizeof(FlutterPlatformMessage),
      .channel = [channel UTF8String],
      .message = message.bytes,
      .message_size = message.length,
  };

  FlutterResult result = FlutterEngineSendPlatformMessage(_engine, &platformMessage);

  return result == kSuccess;
}

#pragma mark - Private methods.

/**
 * Creates a render config with callbacks based on whether the embedder is being run as a headless
 * server.
 */
+ (FlutterRendererConfig)createRenderConfigHeadless:(BOOL)headless {
  if (headless) {
    const FlutterRendererConfig config = {
        .type = kOpenGL,
        .open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig),
        .open_gl.make_current = (BoolCallback)HeadlessOnMakeCurrent,
        .open_gl.clear_current = (BoolCallback)HeadlessOnClearCurrent,
        .open_gl.present = (BoolCallback)HeadlessOnPresent,
        .open_gl.fbo_callback = (UIntCallback)HeadlessOnFBO};
    return config;
  } else {
    const FlutterRendererConfig config = {
        .type = kOpenGL,
        .open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig),
        .open_gl.make_current = (BoolCallback)OnMakeCurrent,
        .open_gl.clear_current = (BoolCallback)OnClearCurrent,
        .open_gl.present = (BoolCallback)OnPresent,
        .open_gl.fbo_callback = (UIntCallback)OnFBO};
    return config;
  }
}

- (void)handlePlatformMessage:(const FlutterPlatformMessage *)message {
  // This method must not return early as we still need to submit the
  // response callback in case of error.

  NSData *data = [NSData dataWithBytesNoCopy:(void *)message->message
                                      length:message->message_size
                                freeWhenDone:NO];

  NSError *error = nil;
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

  NSString *channel = @(message->channel);
  id<FLEPlugin> plugin = _plugins[channel];
  if (plugin != nil && dictionary != nil) {
    id response = [plugin handlePlatformMessage:dictionary];

    NSData *responseData = nil;
    if (response != nil) {
      responseData = [NSJSONSerialization dataWithJSONObject:response options:0 error:&error];
    }

    FlutterEngineSendPlatformMessageResponse(_engine, message->response_handle, responseData.bytes,
                                             responseData.length);
  }
}

/*
 * Responds to view reshape by notifying the engine of the change in dimensions.
 */
- (void)viewDidReshape:(NSOpenGLView *)view {
  const FlutterWindowMetricsEvent event = {
      .struct_size = sizeof(event),
      .width = view.bounds.size.width,
      .height = view.bounds.size.height,
      .pixel_ratio = 1.0,
  };
  FlutterEngineSendWindowMetricsEvent(_engine, &event);
}

#pragma mark - View controller lifecycle and responder overrides.

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self != nil) {
    [self initPlugins];
  }
  return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self != nil) {
    [self initPlugins];
  }
  return self;
}

- (void)loadView {
  self.view = [[FLEView alloc] init];
}

/**
 * Initializes plugins used by this view controller.
 * Called from init.
 */
- (void)initPlugins {
  _plugins = [[NSMutableDictionary alloc] init];

  FLETextInputPlugin *textPlugin = [[FLETextInputPlugin alloc] init];
  [self _addPlugin:textPlugin];

  FLEColorPanelPlugin *colorPlugin = [[FLEColorPanelPlugin alloc] init];
  [self _addPlugin:colorPlugin];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
  [self dispatchEvent:theEvent phase:kDown];
}

- (void)mouseUp:(NSEvent *)theEvent {
  [self dispatchEvent:theEvent phase:kUp];
}

- (void)mouseDragged:(nonnull NSEvent *)theEvent {
  [self dispatchEvent:theEvent phase:kMove];
}

- (void)dispatchEvent:(NSEvent *)theEvent phase:(FlutterPointerPhase)phase {
  NSPoint loc = [self.view convertPoint:theEvent.locationInWindow fromView:nil];
  const FlutterPointerEvent event = {
      .struct_size = sizeof(event),
      .phase = phase,
      .x = loc.x,
      .y = loc.y,
      .timestamp = theEvent.timestamp * NSEC_PER_MSEC,
  };
  FlutterEngineSendPointerEvent(_engine, &event, 1);
}

- (void)dealloc {
  if (FlutterEngineShutdown(_engine) == kSuccess) {
    _engine = NULL;
  }
}

@end
