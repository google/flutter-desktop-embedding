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

#import "FLEFileChooserPlugin.h"

#import "FLEViewController.h"

// The identifier for the platform channel used to exchange messages with macOS.
static NSString *const kFileChooserChannelName = @"flutter/filechooser";

// Method call identifiers.
// Show an instance of NSOpenPanel.
static NSString *const kShowOpenPanelMethod = @"FileChooser.Show.Open";
// Show an instance of NSSavePanel.
static NSString *const kShowSavePanelMethod = @"FileChooser.Show.Save";
static NSString *const kFileChooserCallbackMethod = @"FileChooser.Callback";

// Platform message keys.
static NSString *const kPlatformMethodNameKey = @"method";
static NSString *const kPlatformMethodArgsKey = @"args";

// Method argument keys for NSSavePanel.
static NSString *const kOKButtonLabelKey = @"confirmButtonLabel";
static NSString *const kInitialDirectoryKey = @"initialDirectory";
static NSString *const kAllowedFileTypesKey = @"allowedFileTypes";
static NSString *const kInitialFileName = @"initialFileName";

// Method argument keys for NSOpenPanel.
static NSString *const kAllowsMultipleSelectionKey = @"allowsMultipleSelection";
static NSString *const kCanChooseDirectoriesKey = @"canChooseDirectories";
static NSString *const kPlatformClientIDKey = @"clientID";

// Callback keys.
static NSString *const kFileChooserResultKey = @"result";
static NSString *const kFileChooserPathsKey = @"paths";

@interface FLEFileChooserPlugin ()

/**
 * A dictionary that maps flutter clientIDs to their representative file chooser panel.
 */
@property(nonatomic, strong, nonnull) NSMutableDictionary<NSNumber *, NSSavePanel *> *panels;

@end

@implementation FLEFileChooserPlugin

@synthesize controller = _controller;

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _panels = [NSMutableDictionary dictionary];
  }
  return self;
}

/**
 * Configures an NSSavePanel instance on behalf of a flutter client.
 *
 * @param clientID - identifier for the flutter client with which a panel instance is associated.
 * @param arguments - a dictionary of method arguments used to configure a panel instance.
 */
- (void)configureSavePanelForClient:(nonnull NSNumber *)clientID
                      withArguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  NSSet *argKeys = [NSSet setWithArray:arguments.allKeys];
  if ([argKeys containsObject:kInitialDirectoryKey]) {
    _panels[clientID].directoryURL = [NSURL URLWithString:arguments[kInitialDirectoryKey]];
  }
  if ([argKeys containsObject:kAllowedFileTypesKey]) {
    _panels[clientID].allowedFileTypes = arguments[kAllowedFileTypesKey];
  }
  if ([argKeys containsObject:kInitialFileName]) {
    _panels[clientID].nameFieldStringValue = arguments[kInitialFileName];
  }
  if ([argKeys containsObject:kOKButtonLabelKey]) {
    _panels[clientID].prompt = arguments[kOKButtonLabelKey];
  }
}

/**
 * Configures an NSOpenPanel instance on behalf of a flutter client.
 *
 * @param clientID - identifier for the flutter client with which a panel instance is associated.
 * @param arguments - a dictionary of method arguments used to configure a panel instance.
 */
- (void)configureOpenPanelForClient:(nonnull NSNumber *)clientID
                      withArguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  NSSet *argKeys = [NSSet setWithArray:arguments.allKeys];
  NSOpenPanel *openPanel = (NSOpenPanel *)_panels[clientID];
  if ([argKeys containsObject:kAllowsMultipleSelectionKey]) {
    openPanel.allowsMultipleSelection =
        [arguments[kAllowsMultipleSelectionKey] boolValue];
  }
  if ([argKeys containsObject:kCanChooseDirectoriesKey]) {
    BOOL canChooseDirectories = [arguments[kCanChooseDirectoriesKey] boolValue];
    openPanel.canChooseDirectories = canChooseDirectories;
    openPanel.canChooseFiles = !canChooseDirectories;
  }
}

/**
 * Encode and send a callback message to a flutter client.
 *
 * @param clientID - identifer for the flutter client to which the callback message will be sent.
 * @param URLs - an array of URLs selected using the flutter client's panel instance.
 * @param result - the platform message callback.
 */
- (void)invokeCallbackForClient:(nonnull NSNumber *)clientID
                       withURLs:(nullable NSArray<NSURL *> *)URLs
                         result:(nonnull FLEMethodResult)result {
  // Send an empty succes reply to indicate that the requset was handled.
  // TODO: Eliminate the seperate response message, and send the results back here. This will
  // require simultaneous changes on the Dart side.
  result(nil);

  NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
  arguments[kFileChooserResultKey] = @(URLs ? 1 : 0);
  arguments[kPlatformClientIDKey] = clientID;
  if (URLs.count > 0) {
    arguments[kFileChooserPathsKey] = [URLs valueForKey:@"path"];
  }

  [_controller invokeMethod:kFileChooserCallbackMethod
                  arguments:arguments
                  onChannel:kFileChooserChannelName];
}

#pragma FLEPlugin implementation

- (NSString *)channel {
  return kFileChooserChannelName;
}

- (void)handleMethodCall:(FLEMethodCall *)call result:(FLEMethodResult)result {
  NSDictionary *arguments = call.arguments;
  NSNumber *clientID = arguments[kPlatformClientIDKey];

  __weak FLEFileChooserPlugin *weakself = self;
  if ([call.methodName isEqualToString:kShowSavePanelMethod]) {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.canCreateDirectories = YES;
    _panels[clientID] = savePanel;
    [self configureSavePanelForClient:clientID withArguments:arguments];
    [savePanel beginSheetModalForWindow:_controller.view.window
                      completionHandler:^(NSModalResponse panelResult) {
                        [weakself invokeCallbackForClient:clientID
                                                 withURLs:(panelResult == NSModalResponseOK)
                                                              ? @[ savePanel.URL ]
                                                              : nil
                                                   result:result];
                      }];

  } else if ([call.methodName isEqualToString:kShowOpenPanelMethod]) {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    _panels[clientID] = openPanel;
    [self configureSavePanelForClient:clientID withArguments:arguments];
    [self configureOpenPanelForClient:clientID withArguments:arguments];
    [openPanel beginSheetModalForWindow:_controller.view.window
                      completionHandler:^(NSModalResponse panelResult) {
                        [weakself invokeCallbackForClient:clientID
                                                 withURLs:(panelResult == NSModalResponseOK)
                                                              ? openPanel.URLs
                                                              : nil
                                                   result:result];
                      }];
  } else {
    result(FLEMethodNotImplemented);
  }
}

@end
