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

#include "plugins/file_chooser/common/channel_constants.h"

@implementation FLEFileChooserPlugin

@synthesize controller = _controller;

/**
 * Configures an NSSavePanel instance on behalf of a flutter client.
 *
 * @param panel - The panel to configure.
 * @param arguments - A dictionary of method arguments used to configure a panel instance.
 */
- (void)configureSavePanel:(nonnull NSSavePanel *)panel
             withArguments:(nonnull NSDictionary<NSString *, id> *)arguments {
  NSSet *argKeys = [NSSet setWithArray:arguments.allKeys];
  if ([argKeys containsObject:@(plugins_file_chooser::kInitialDirectoryKey)]) {
    panel.directoryURL =
        [NSURL URLWithString:arguments[@(plugins_file_chooser::kInitialDirectoryKey)]];
  }
  if ([argKeys containsObject:@(plugins_file_chooser::kAllowedFileTypesKey)]) {
    panel.allowedFileTypes = arguments[@(plugins_file_chooser::kAllowedFileTypesKey)];
  }
  if ([argKeys containsObject:@(plugins_file_chooser::kInitialFileNameKey)]) {
    panel.nameFieldStringValue = arguments[@(plugins_file_chooser::kInitialFileNameKey)];
  }
  if ([argKeys containsObject:@(plugins_file_chooser::kConfirmButtonTextKey)]) {
    panel.prompt = arguments[@(plugins_file_chooser::kConfirmButtonTextKey)];
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
  if ([argKeys containsObject:@(plugins_file_chooser::kAllowsMultipleSelectionKey)]) {
    panel.allowsMultipleSelection =
        [arguments[@(plugins_file_chooser::kAllowsMultipleSelectionKey)] boolValue];
  }
  if ([argKeys containsObject:@(plugins_file_chooser::kCanChooseDirectoriesKey)]) {
    BOOL canChooseDirectories =
        [arguments[@(plugins_file_chooser::kCanChooseDirectoriesKey)] boolValue];
    panel.canChooseDirectories = canChooseDirectories;
    panel.canChooseFiles = !canChooseDirectories;
  }
}

#pragma FLEPlugin implementation

- (NSString *)channel {
  return @(plugins_file_chooser::kChannelName);
}

- (void)handleMethodCall:(FLEMethodCall *)call result:(FLEMethodResult)result {
  NSDictionary *arguments = call.arguments;

  if ([call.methodName isEqualToString:@(plugins_file_chooser::kShowSavePanelMethod)]) {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.canCreateDirectories = YES;
    [self configureSavePanel:savePanel withArguments:arguments];
    [savePanel beginSheetModalForWindow:_controller.view.window
                      completionHandler:^(NSModalResponse panelResult) {
                        NSArray<NSURL *> *URLs =
                            (panelResult == NSModalResponseOK) ? @[ savePanel.URL ] : nil;
                        result([URLs valueForKey:@"path"]);
                      }];

  } else if ([call.methodName isEqualToString:@(plugins_file_chooser::kShowOpenPanelMethod)]) {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [self configureSavePanel:openPanel withArguments:arguments];
    [self configureOpenPanel:openPanel withArguments:arguments];
    [openPanel beginSheetModalForWindow:_controller.view.window
                      completionHandler:^(NSModalResponse panelResult) {
                        NSArray<NSURL *> *URLs =
                            (panelResult == NSModalResponseOK) ? openPanel.URLs : nil;
                        result([URLs valueForKey:@"path"]);
                      }];
  } else {
    result(FLEMethodNotImplemented);
  }
}

@end
