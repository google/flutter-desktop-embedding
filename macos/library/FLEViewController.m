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
@interface FLEViewController () <FLEReshapeListener> {
  NSOpenGLContext *_resourceContext;
}

/**
 * Responds to system messages sent to this controller from the Flutter engine.
 * Invoked from a static method provided in the engine configuration, thus must be
 * explicitly declared.
 */
- (void)handlePlatformMessage:(const FlutterPlatformMessage *)message;

/**
 * Makes the OpenGL context used by the engine for rendering optimization the
 * current context.
 */
- (void)makeResourceContextCurrent;

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
  [NSOpenGLContext clearCurrentContext];
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

/**
 * Makes the resource context the current context.
 */
static bool OnMakeResourceCurrent(FLEViewController *controller) {
  [controller makeResourceContextCurrent];
  return true;
}

#pragma mark - Static methods provided for headless engine configuration.

static bool HeadlessOnMakeCurrent(FLEViewController *controller) { return false; }

static bool HeadlessOnClearCurrent(FLEViewController *controller) { return false; }

static bool HeadlessOnPresent(FLEViewController *controller) { return false; }

static uint32_t HeadlessOnFBO(FLEViewController *controller) { return kDefaultWindowFramebuffer; }

static bool HeadlessOnMakeResourceCurrent(FLEViewController *controller) { return false; }

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
  return [self launchEngineInternalWithAssetsPath:assets
                                         mainPath:main
                                     packagesPath:packages
                                       asHeadless:headless
                             commandLineArguments:arguments];
}

- (BOOL)launchEngineWithAssetsPath:(nonnull NSURL *)assets
                        asHeadless:(BOOL)headless
              commandLineArguments:(nonnull NSArray<NSString *> *)arguments {
  return [self launchEngineInternalWithAssetsPath:assets
                                         mainPath:nil
                                     packagesPath:nil
                                       asHeadless:headless
                             commandLineArguments:arguments];
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

- (void)invokeMethod:(nonnull NSString *)method
           arguments:(nullable id)arguments
           onChannel:(nonnull NSString *)channel
           withCodec:(nonnull id<FLEMethodCodec>)codec {
  FLEMethodCall *methodCall = [[FLEMethodCall alloc] initWithMethodName:method arguments:arguments];
  NSData *messageData = [codec encodeMethodCall:methodCall];
  if (!messageData) {
    NSLog(@"Error: Unable to construct a message to call %@ on %@", method, channel);
    return;
  }

  FlutterPlatformMessage platformMessage = {
      .struct_size = sizeof(FlutterPlatformMessage),
      .channel = [channel UTF8String],
      .message = messageData.bytes,
      .message_size = messageData.length,
  };

  FlutterResult result = FlutterEngineSendPlatformMessage(_engine, &platformMessage);
  if (result != kSuccess) {
    NSLog(@"Unable to invoke %@ on Flutter engine (%d).", method, result);
  }
}

- (void)invokeMethod:(nonnull NSString *)method
           arguments:(nullable id)arguments
           onChannel:(nonnull NSString *)channel {
  [self invokeMethod:method
           arguments:arguments
           onChannel:channel
           withCodec:[FLEJSONMethodCodec sharedInstance]];
}

#pragma mark - Private methods.

/**
 * Identical to the public API except that |main| and |packages| are nullable (and assets and main
 * are swapped to make it clearer that they are the nullable pair; the public API is staying the
 * same for now to avoid needless thrashing for code using it). Per the TODO in the header, this API
 * should be reworked once we have decided whether both versions will stay.
 *
 * If main is nil, the engine will run in snapshot mode.
 */
- (BOOL)launchEngineInternalWithAssetsPath:(nonnull NSURL *)assets
                                  mainPath:(nullable NSURL *)main
                              packagesPath:(nullable NSURL *)packages
                                asHeadless:(BOOL)headless
                      commandLineArguments:(nonnull NSArray<NSString *> *)arguments {
  if (_engine != NULL) {
    return NO;
  }

  [self createResourceContext];

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

  NSString *icuData = [[NSBundle bundleWithIdentifier:kICUBundleID] pathForResource:kICUBundlePath
                                                                             ofType:nil];

  const FlutterProjectArgs args = {
      .struct_size = sizeof(FlutterProjectArgs),
      .assets_path = assets.fileSystemRepresentation,
      .main_path = (main != nil) ? main.fileSystemRepresentation : "",
      .packages_path = (packages != nil) ? packages.fileSystemRepresentation : "",
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
        .open_gl.fbo_callback = (UIntCallback)HeadlessOnFBO,
        .open_gl.make_resource_current = (BoolCallback)HeadlessOnMakeResourceCurrent};
    return config;
  } else {
    const FlutterRendererConfig config = {
        .type = kOpenGL,
        .open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig),
        .open_gl.make_current = (BoolCallback)OnMakeCurrent,
        .open_gl.clear_current = (BoolCallback)OnClearCurrent,
        .open_gl.present = (BoolCallback)OnPresent,
        .open_gl.fbo_callback = (UIntCallback)OnFBO,
        .open_gl.make_resource_current = (BoolCallback)OnMakeResourceCurrent};
    return config;
  }
}

- (void)handlePlatformMessage:(const FlutterPlatformMessage *)message {
  NSData *data = [NSData dataWithBytesNoCopy:(void *)message->message
                                      length:message->message_size
                                freeWhenDone:NO];
  NSString *channel = @(message->channel);
  __block const FlutterPlatformMessageResponseHandle *responseHandle = message->response_handle;

  id<FLEPlugin> plugin = _plugins[channel];
  if (!plugin) {
    FlutterEngineSendPlatformMessageResponse(self->_engine, responseHandle, NULL, 0);
    return;
  }

  // See the note on the |codec| property of FLEPlugin for the reason this defaults to JSON.
  id<FLEMethodCodec> codec = [FLEJSONMethodCodec sharedInstance];
  if ([plugin respondsToSelector:@selector(codec)]) {
    codec = plugin.codec;
  }
  FLEMethodCall *methodCall = [codec decodeMethodCall:data];

  FLEMethodResult resultHandler = ^(id result) {
    NSData *responseData = nil;
    if (result == FLEMethodNotImplemented) {
      // No-op; nil is the not-implemented response.
      // Note that the compare above deliberately uses pointer equality rather than string equality
      // since only the constant itself should be treated as 'not implemented'.
    } else if ([result isKindOfClass:[FLEMethodError class]]) {
      responseData = [codec encodeErrorEnvelope:(FLEMethodError *)result];
    } else {
      responseData = [codec encodeSuccessEnvelope:result];
    }

    if (responseHandle) {
      FlutterEngineSendPlatformMessageResponse(self->_engine, responseHandle, responseData.bytes,
                                               responseData.length);
      responseHandle = NULL;
    } else {
      NSLog(@"Error: Method call responses can be called only once. Ignoring duplicate response "
             "for '%@' on channel '%@'.",
            methodCall.methodName, channel);
    }
  };

  if (!methodCall) {
    NSLog(@"Received invalid platform message on channel %@", channel);
    resultHandler(FLEMethodNotImplemented);
    return;
  }

  [plugin handleMethodCall:methodCall result:resultHandler];
}

/**
 * Creates the OpenGL context used as the resource context by the engine.
 *
 * This is done explicitly rather than in viewDidLoad as there's no guarantee that viewDidLoad
 * will be called before the engine is started, and the context must be valid by then.
 */
- (void)createResourceContext {
  NSOpenGLContext *viewContext = ((NSOpenGLView *)self.view).openGLContext;
  _resourceContext = [[NSOpenGLContext alloc] initWithFormat:viewContext.pixelFormat
                                                shareContext:viewContext];
}

- (void)makeResourceContextCurrent {
  [_resourceContext makeCurrentContext];
}

/*
 * Responds to view reshape by notifying the engine of the change in dimensions.
 */
- (void)viewDidReshape:(NSOpenGLView *)view {
  CGRect scaledBounds = [view convertRectToBacking:view.bounds];
  const FlutterWindowMetricsEvent event = {
      .struct_size = sizeof(event),
      .width = scaledBounds.size.width,
      .height = scaledBounds.size.height,
      .pixel_ratio = scaledBounds.size.width / view.bounds.size.width,
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
  NSPoint locationInView = [self.view convertPoint:theEvent.locationInWindow fromView:nil];
  NSPoint locationInBackingCoordinates = [self.view convertPointToBacking:locationInView];
  const FlutterPointerEvent event = {
      .struct_size = sizeof(event),
      .phase = phase,
      .x = locationInBackingCoordinates.x,
      .y = -locationInBackingCoordinates.y,  // convertPointToBacking makes this negative.
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
