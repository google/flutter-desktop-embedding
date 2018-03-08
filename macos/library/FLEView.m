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

#import "FLEView.h"

@implementation FLEView

#pragma mark -
#pragma mark FLEContextHandlingProtocol

- (void)makeCurrentContext {
  [self.openGLContext makeCurrentContext];
}

- (void)onPresent {
  [self.openGLContext flushBuffer];
}

#pragma mark -
#pragma mark Implementation

/**
 * Declares that the view uses a flipped coordinate system, consistent with Flutter conventions.
 */
- (BOOL)isFlipped {
  return YES;
}

- (BOOL)isOpaque {
  return YES;
}

- (void)reshape {
  [_reshapeListener viewDidReshape:self];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

@end
