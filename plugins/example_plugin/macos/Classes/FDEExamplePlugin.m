// Copyright 2019 Google LLC
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

#import "FDEExamplePlugin.h"

@implementation FDEExamplePlugin

+ (void)registerWithRegistrar:(id<FLEPluginRegistrar>)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"example_plugin"
                                                              binaryMessenger:registrar.messenger];
  FDEExamplePlugin *instance = [[FDEExamplePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"macOS "
        stringByAppendingString:[[NSProcessInfo processInfo] operatingSystemVersionString]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
