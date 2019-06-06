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

#import <AppKit/AppKit.h>

// See channel_controller.dart for documentation.
static NSString *const kChannelName = @"flutter/filechooser";
static NSString *const kShowOpenPanelMethod = @"FileChooser.Show.Open";
static NSString *const kShowSavePanelMethod = @"FileChooser.Show.Save";
static NSString *const kInitialDirectoryKey = @"initialDirectory";
static NSString *const kInitialFileNameKey = @"initialFileName";
static NSString *const kAllowedFileTypesKey = @"allowedFileTypes";
static NSString *const kConfirmButtonTextKey = @"confirmButtonText";
static NSString *const kAllowsMultipleSelectionKey = @"allowsMultipleSelection";
static NSString *const kCanChooseDirectoriesKey = @"canChooseDirectories";

@implementation FLEFileChooserPlugin {
  // The view displaying Flutter content.
  NSView *_flutterView;
}

- (instancetype)initWithView:(NSView *)view {
  self = [super init];
  if (self != nil) {
    _flutterView = view;
  }
  return self;
}

/**
 * Configures an NSSavePanel instance on behalf of a flutter client.
 *
 * @param panel - The panel to configure.
 * @param arguments - A dictionary of method arguments used to configure a panel instance.
 */
- (void)configureSavePanel:(nonnull NSSavePanel *)panel
             withArguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  NSSet *argKeys = [NSSet setWithArray:arguments.allKeys];
  if ([argKeys containsObject:kInitialDirectoryKey]) {
    panel.directoryURL = [NSURL URLWithString:arguments[kInitialDirectoryKey]];
  }
  if ([argKeys containsObject:kAllowedFileTypesKey]) {
    panel.allowedFileTypes = arguments[kAllowedFileTypesKey];
  }
  if ([argKeys containsObject:kInitialFileNameKey]) {
    panel.nameFieldStringValue = arguments[kInitialFileNameKey];
  }
  if ([argKeys containsObject:kConfirmButtonTextKey]) {
    panel.prompt = arguments[kConfirmButtonTextKey];
  }
}

/**
 * Configures an NSOpenPanel instance on behalf of a flutter client.
 *
 * @param panel - The open panel to configure.
 * @param arguments - A dictionary of method arguments used to configure a panel instance.
 */
- (void)configureOpenPanel:(nonnull NSOpenPanel *)panel
             withArguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  NSSet *argKeys = [NSSet setWithArray:arguments.allKeys];
  if ([argKeys containsObject:kAllowsMultipleSelectionKey]) {
    panel.allowsMultipleSelection = [arguments[kAllowsMultipleSelectionKey] boolValue];
  }
  if ([argKeys containsObject:kCanChooseDirectoriesKey]) {
    BOOL canChooseDirectories = [arguments[kCanChooseDirectoriesKey] boolValue];
    panel.canChooseDirectories = canChooseDirectories;
    panel.canChooseFiles = !canChooseDirectories;
  }
}

#pragma FlutterPlugin implementation

+ (void)registerWithRegistrar:(id<FlutterPluginRegistrar>)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:kChannelName
                                                              binaryMessenger:registrar.messenger];
  FLEFileChooserPlugin *instance = [[FLEFileChooserPlugin alloc] initWithView:registrar.view];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSDictionary *arguments = call.arguments;

  if ([call.method isEqualToString:kShowSavePanelMethod]) {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.canCreateDirectories = YES;
    [self configureSavePanel:savePanel withArguments:arguments];
    [savePanel beginSheetModalForWindow:_flutterView.window
                      completionHandler:^(NSModalResponse panelResult) {
                        NSArray<NSURL *> *URLs =
                            (panelResult == NSModalResponseOK) ? @[ savePanel.URL ] : nil;
                        result([URLs valueForKey:@"path"]);
                      }];

  } else if ([call.method isEqualToString:kShowOpenPanelMethod]) {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [self configureSavePanel:openPanel withArguments:arguments];
    [self configureOpenPanel:openPanel withArguments:arguments];
    [openPanel beginSheetModalForWindow:_flutterView.window
                      completionHandler:^(NSModalResponse panelResult) {
                        NSArray<NSURL *> *URLs =
                            (panelResult == NSModalResponseOK) ? openPanel.URLs : nil;
                        result([URLs valueForKey:@"path"]);
                      }];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
