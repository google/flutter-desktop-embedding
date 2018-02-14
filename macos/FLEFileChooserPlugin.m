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

// Method argument keys.
static NSString *const kAllowedFileTypesKey = @"allowedFileTypes";
static NSString *const kAllowsMultipleSelectionKey = @"allowsMultipleSelection";
static NSString *const kCanChooseDirectoriesKey = @"canChooseDirectories";
static NSString *const kInitialDirectoryKey = @"initialDirectory";
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
  if ([argKeys containsObject:kAllowsMultipleSelectionKey]) {
    ((NSOpenPanel *)_panels[clientID]).allowsMultipleSelection =
        [arguments[kAllowsMultipleSelectionKey] boolValue];
  }
  if ([argKeys containsObject:kCanChooseDirectoriesKey]) {
    ((NSOpenPanel *)_panels[clientID]).canChooseDirectories =
        [arguments[kCanChooseDirectoriesKey] boolValue];
  }
}

/**
 * Encode and send a callback message to a flutter client.
 *
 * @param clientID - identifer for the flutter client to which the callback message will be sent.
 * @param result - the result value returned by the panel associated with the client.
 * @param URLs - an array of URLs selected using the flutter client's panel instance.
 */
- (void)invokeCallbackForClient:(nonnull NSNumber *)clientID
                     withResult:(NSModalResponse)result
                           URLs:(nullable NSArray<NSURL *> *)URLs {
  NSMutableDictionary *response =
      [NSMutableDictionary dictionaryWithObject:kFileChooserCallbackMethod
                                         forKey:kPlatformMethodNameKey];
  response[kPlatformMethodArgsKey] =
      [NSMutableDictionary dictionaryWithObject:@(result) forKey:kFileChooserResultKey];
  response[kPlatformMethodArgsKey][kPlatformClientIDKey] = clientID;
  if (result == NSModalResponseOK && URLs.count > 0) {
    response[kPlatformMethodArgsKey][kFileChooserPathsKey] = [URLs valueForKey:@"path"];
  }

  if (![NSJSONSerialization isValidJSONObject:response]) {
    NSLog(@"ERROR: invalid JSON object: %@", response);
    return;
  }

  NSError *error = nil;
  NSData *message = [NSJSONSerialization dataWithJSONObject:response options:0 error:&error];
  if (message == nil || error != nil) {
    NSLog(@"ERROR: could send platform response message: %@", error.debugDescription);
    return;
  }

  [_controller sendPlatformMessage:message onChannel:kFileChooserChannelName];
}

#pragma FLEPlugin implementation

- (NSString *)channel {
  return kFileChooserChannelName;
}

- (nullable id)handlePlatformMessage:(NSDictionary *)message {
  NSString *methodName = message[kPlatformMethodNameKey];
  NSDictionary *methodArgs = message[kPlatformMethodArgsKey];
  NSNumber *clientID = methodArgs[kPlatformClientIDKey];

  __weak FLEFileChooserPlugin *weakself = self;
  if ([methodName isEqualToString:kShowSavePanelMethod]) {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    _panels[clientID] = savePanel;
    [self configureSavePanelForClient:clientID withArguments:methodArgs];
    [savePanel beginSheetModalForWindow:_controller.view.window
                      completionHandler:^(NSModalResponse result) {
                        [weakself invokeCallbackForClient:clientID
                                               withResult:result
                                                     URLs:(result == NSModalResponseOK)
                                                              ? @[ savePanel.URL ]
                                                              : nil];
                      }];

  } else if ([methodName isEqualToString:kShowOpenPanelMethod]) {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    _panels[clientID] = openPanel;
    [self configureSavePanelForClient:clientID withArguments:methodArgs];
    [self configureOpenPanelForClient:clientID withArguments:methodArgs];
    [openPanel
        beginSheetModalForWindow:_controller.view.window
               completionHandler:^(NSModalResponse result) {
                 [weakself
                     invokeCallbackForClient:clientID
                                  withResult:result
                                        URLs:(result == NSModalResponseOK) ? openPanel.URLs : nil];
               }];
  }

  return nil;
}

@end
