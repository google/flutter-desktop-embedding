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

#import "FLETextInputPlugin.h"

#import <objc/message.h>

#import "FLETextInputModel.h"
#import "FLEViewController+Internal.h"

static NSString *const kTextInputChannel = @"flutter/textinput";

// See
// https://master-docs-flutter-io.firebaseapp.com/flutter/services/SystemChannels/textInput-constant.html
static NSString *const kSetClientMethod = @"TextInput.setClient";
static NSString *const kShowMethod = @"TextInput.show";
static NSString *const kHideMethod = @"TextInput.hide";
static NSString *const kClearClientMethod = @"TextInput.clearClient";
static NSString *const kSetEditingStateMethod = @"TextInput.setEditingState";
static NSString *const kUpdateEditStateResponseMethod = @"TextInputClient.updateEditingState";
static NSString *const kPerformAction = @"TextInputClient.performAction";
static NSString *const kNewLine = @"TextInputAction.newline";
static NSString *const kDone = @"TextInputAction.done";


/**
 * Private properties of FlutterTextInputPlugin.
 */
@interface FLETextInputPlugin () <NSTextInputClient>

/**
 * A text input context, representing a connection to the Cocoa text input system.
 */
@property NSTextInputContext *textInputContext;

/**
 * A dictionary of text input models, one per client connection, keyed
 * by the client connection ID.
 */
@property NSMutableDictionary<NSNumber *, FLETextInputModel *> *textInputModels;

/**
 * The currently active client connection ID.
 */
@property(nullable) NSNumber *activeClientID;

/**
 * The currently active text input model.
 */
@property(readonly, nullable) FLETextInputModel *activeModel;

@end

@implementation FLETextInputPlugin

@synthesize controller = _controller;

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _textInputModels = [[NSMutableDictionary alloc] init];
    _textInputContext = [[NSTextInputContext alloc] initWithClient:self];
  }
  return self;
}

- (NSString *)channel {
  return kTextInputChannel;
}

- (FLETextInputModel *)activeModel {
  return (_activeClientID == nil) ? nil : _textInputModels[_activeClientID];
}

- (void)handleMethodCall:(FLEMethodCall *)call result:(FLEMethodResult)result {
  BOOL handled = YES;
  NSString *method = call.methodName;
  if ([method isEqualToString:kSetClientMethod]) {
    NSNumber *clientID = call.arguments[0];
    if (clientID != nil &&
        (_activeClientID == nil || ![_activeClientID isEqualToNumber:clientID])) {
      _activeClientID = clientID;
      // TODO: Do we need to preserve state across setClient calls?
      _textInputModels[_activeClientID] = [[FLETextInputModel alloc] init];
    }
  } else if ([method isEqualToString:kShowMethod]) {
    [self.controller addKeyResponder:self];
    [_textInputContext activate];
  } else if ([method isEqualToString:kHideMethod]) {
    [self.controller removeKeyResponder:self];
    [_textInputContext deactivate];
  } else if ([method isEqualToString:kClearClientMethod]) {
    _activeClientID = nil;
  } else if ([method isEqualToString:kSetEditingStateMethod]) {
    NSDictionary *state = call.arguments;
    self.activeModel.state = state;
  } else {
    handled = NO;
    NSLog(@"Unhandled text input method '%@'", method);
  }
  result(handled ? nil : FLEMethodNotImplemented);
}

/**
 * Informs the Flutter framework of changes to the text input model's state.
 */
- (void)updateEditState {
  if (self.activeModel == nil) {
    return;
  }

  [_controller invokeMethod:kUpdateEditStateResponseMethod
                  arguments:@[ _activeClientID, _textInputModels[_activeClientID].state ]
                  onChannel:kTextInputChannel];
}

#pragma mark -
#pragma mark NSResponder

/**
 * Note, the Apple docs suggest that clients should override essentially all the
 * mouse and keyboard event-handling methods of NSResponder. However, experimentation
 * indicates that only key events are processed by the native layer; Flutter processes
 * mouse events. Additionally, processing both keyUp and keyDown results in duplicate
 * processing of the same keys. So for now, limit processing to just keyDown.
 */
- (void)keyDown:(NSEvent *)event {
  [_textInputContext handleEvent:event];
}

#pragma mark -
#pragma mark NSStandardKeyBindingMethods

/**
 * Note, experimentation indicates that moveRight and moveLeft are called rather
 * than the supposedly more RTL-friendly moveForward and moveBackward.
 */
- (void)moveLeft:(nullable id)sender {
  NSRange selection = self.activeModel.selectedRange;
  if (selection.length == 0) {
    if (selection.location > 0) {
      // Move to previous location
      self.activeModel.selectedRange = NSMakeRange(selection.location - 1, 0);
      [self updateEditState];
    }
  } else {
    // Collapse current selection
    self.activeModel.selectedRange = NSMakeRange(selection.location, 0);
    [self updateEditState];
  }
}

- (void)moveRight:(nullable id)sender {
  NSRange selection = self.activeModel.selectedRange;
  if (selection.length == 0) {
    if (selection.location < self.activeModel.text.length) {
      // Move to next location
      self.activeModel.selectedRange = NSMakeRange(selection.location + 1, 0);
      [self updateEditState];
    }
  } else {
    // Collapse current selection
    self.activeModel.selectedRange = NSMakeRange(selection.location + selection.length, 0);
    [self updateEditState];
  }
}

- (void)deleteBackward:(id)sender {
  NSRange selection = self.activeModel.selectedRange;
  if (selection.location == 0) return;
  NSRange range = selection;
  if (selection.length == 0) {
    NSUInteger location = (selection.location == NSNotFound) ? self.activeModel.text.length - 1
                                                             : selection.location - 1;
    range = NSMakeRange(location, 1);
  }
  self.activeModel.selectedRange = NSMakeRange(range.location, 0);
  [self insertText:@"" replacementRange:range];  // Updates edit state
}

#pragma mark -
#pragma mark NSTextInputClient

- (void)insertText:(id)string replacementRange:(NSRange)range {
  if (self.activeModel != nil) {
    if (range.location == NSNotFound && range.length == 0) {
      // Use selection
      range = self.activeModel.selectedRange;
    }
    if (range.location > self.activeModel.text.length)
      range.location = self.activeModel.text.length;
    if (range.length > (self.activeModel.text.length - range.location))
      range.length = self.activeModel.text.length - range.location;
    [self.activeModel.text replaceCharactersInRange:range withString:string];
    self.activeModel.selectedRange = NSMakeRange(range.location + ((NSString *)string).length, 0);
    [self updateEditState];
  }
}

- (void)doCommandBySelector:(SEL)selector {
  if ([self respondsToSelector:selector]) {
    // Note: The more obvious [self performSelector...] doesn't give ARC enough information to
    // handle retain semantics properly. See https://stackoverflow.com/questions/7017281/ for more
    // information.
    IMP imp = [self methodForSelector:selector];
    void (*func)(id, SEL, id) = (void *)imp;
    func(self, selector, nil);
  }
}

- (void)insertNewline:(id)sender {
  // This method is called when the user hits the Enter key. Since the embedder can't distinguish
  // if the current widget is multiline or not, this method will be considered a "submit" action,
  // To insert a new line, the user should hit ctrl + Enter to call insertLineBreak.
  // There is a PR in Flutter to identify if the widget is multiline, and act accordingly
  // (https://github.com/flutter/flutter/pull/23015). Once merged, this action should be changed
  // to kNewLine.
  [_controller invokeMethod:kPerformAction
                  arguments:@[ _activeClientID, kDone ]
                  onChannel:kTextInputChannel];
}

- (void)setMarkedText:(id)string
        selectedRange:(NSRange)selectedRange
     replacementRange:(NSRange)replacementRange {
  if (self.activeModel != nil) {
    [self.activeModel.text replaceCharactersInRange:replacementRange withString:string];
    self.activeModel.selectedRange = selectedRange;
    [self updateEditState];
  }
}

- (void)unmarkText {
  if (self.activeModel != nil) {
    self.activeModel.markedRange = NSMakeRange(NSNotFound, 0);
    [self updateEditState];
  }
}

- (NSRange)selectedRange {
  return (self.activeModel == nil) ? NSMakeRange(NSNotFound, 0) : self.activeModel.selectedRange;
}

- (NSRange)markedRange {
  return (self.activeModel == nil) ? NSMakeRange(NSNotFound, 0) : self.activeModel.markedRange;
}

- (BOOL)hasMarkedText {
  return (self.activeModel == nil) ? NO : self.activeModel.markedRange.location != NSNotFound;
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)range
                                                actualRange:(NSRangePointer)actualRange {
  if (self.activeModel) {
    if (actualRange != nil) *actualRange = range;
    NSString *substring = [self.activeModel.text substringWithRange:range];
    return [[NSAttributedString alloc] initWithString:substring attributes:nil];
  } else {
    return nil;
  }
}

- (NSArray<NSString *> *)validAttributesForMarkedText {
  return @[];
}

- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(NSRangePointer)actualRange {
  // TODO: Implement.
  // Note: This function can't easily be implemented under the system-message architecture.
  return CGRectZero;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)point {
  // TODO: Implement.
  // Note: This function can't easily be implemented under the system-message architecture.
  return 0;
}

@end
