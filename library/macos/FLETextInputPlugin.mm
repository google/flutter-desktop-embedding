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

#import "FLEJSONMethodCodec.h"
#import "FLEViewController+Internal.h"

#include "../common/internal/text_input_model.h"

#include <iostream>
#include <map>
#include <memory>

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
static NSString *const kMultilineInputType = @"TextInputType.multiline";

// State keys.
static NSString *const kComposingBaseKey = @"composingBase";
static NSString *const kComposingExtentKey = @"composingExtent";
static NSString *const kSelectionBaseKey = @"selectionBase";
static NSString *const kSelectionExtentKey = @"selectionExtent";
static NSString *const kSelectionAffinityKey = @"selectionAffinity";
static NSString *const kSelectionIsDirectionalKey = @"selectionIsDirectional";
static NSString *const kTextKey = @"text";

// Client config  keys.
static NSString *const kTextInputAction = @"inputAction";
static NSString *const kTextInputType = @"inputType";
static NSString *const kTextInputTypeName = @"name";

// Text affinity options keys.
static constexpr char kTextAffinityDownstream[] = "TextAffinity.downstream";
static constexpr char kTextAffinityUpstream[] = "TextAffinity.upstream";

/**
 * Private properties of FlutterTextInputPlugin.
 */
@interface FLETextInputPlugin () <NSTextInputClient> {
  /**
   * The currently active text input model.
   */
  std::unique_ptr<flutter_desktop_embedding::TextInputModel> active_model;
}

/**
 * A text input context, representing a connection to the Cocoa text input system.
 */
@property(nonatomic) NSTextInputContext *textInputContext;

/**
 * The currently active client connection ID.
 */
@property(nonatomic, nullable) NSNumber *activeClientID;

/**
 * The channel used to communicate with Flutter.
 */
@property(nonatomic) FLEMethodChannel *channel;

/**
 * The FLEViewController to manage input for.
 */
@property(nonatomic, weak) FLEViewController *flutterViewController;

/**
 * Handles a Flutter system message on the text input channel.
 */
- (void)handleMethodCall:(FLEMethodCall *)call result:(FLEMethodResult)result;

@end

@implementation FLETextInputPlugin

- (instancetype)initWithViewController:(FLEViewController *)viewController {
  self = [super init];
  if (self != nil) {
    _flutterViewController = viewController;
    _channel = [FLEMethodChannel methodChannelWithName:kTextInputChannel
                                       binaryMessenger:viewController
                                                 codec:[FLEJSONMethodCodec sharedInstance]];
    __weak FLETextInputPlugin *weakSelf = self;
    [_channel setMethodCallHandler:^(FLEMethodCall *call, FLEMethodResult result) {
      [weakSelf handleMethodCall:call result:result];
    }];
    _textInputContext = [[NSTextInputContext alloc] initWithClient:self];
  }
  return self;
}

#pragma mark - Private
/**
 * Converts an NSDictionary to a State object. Will raise an exception if the dictionary is not
 * configured properly.
 */
- (flutter_desktop_embedding::State)stateFromDictionary:(NSDictionary *)dict {
  flutter_desktop_embedding::State new_state;
  NSString *text = dict[kTextKey];
  if (!text) {
    throw std::invalid_argument("Set editing state has been invoked, but without text.");
  }
  new_state.text = [text UTF8String];

  NSNumber *selection_base = dict[kSelectionBaseKey];
  NSNumber *selection_extent = dict[kSelectionExtentKey];
  if (!selection_base || !selection_extent) {
    throw std::invalid_argument("Selection base/extent values invalid.");
  }
  new_state.selection.begin = [selection_base unsignedLongValue];
  new_state.selection.end = [selection_extent unsignedLongValue];

  NSNumber *composing_base = dict[kComposingBaseKey];
  NSNumber *composing_extent = dict[kComposingExtentKey];

  new_state.composing.begin =
      composing_base ? [composing_base unsignedLongValue] : new_state.selection.begin;
  new_state.composing.end =
      composing_extent ? [composing_extent unsignedLongValue] : new_state.selection.end;

  NSString *text_affinity = dict[kSelectionAffinityKey];
  new_state.text_affinity = text_affinity ? [text_affinity UTF8String] : kTextAffinityDownstream;

  new_state.isDirectional = [dict[kSelectionIsDirectionalKey] boolValue];

  return new_state;
}

/**
 * Creates a dictionary from a given State;
 */
- (NSDictionary *)dictionaryFromState:(flutter_desktop_embedding::State)state {
  std::string affinity = state.text_affinity.compare(kTextAffinityUpstream) == 0
                             ? kTextAffinityUpstream
                             : kTextAffinityDownstream;
  NSString *affinityString = [NSString stringWithCString:affinity.c_str()
                                                encoding:[NSString defaultCStringEncoding]];
  NSNumber *composingBase =
      state.composing.begin == std::string::npos ? @-1 : @(state.composing.begin);
  NSNumber *composingExtent =
      state.composing.end == std::string::npos ? @-1 : @(state.composing.end);
  NSNumber *selectionBase =
      state.selection.begin == std::string::npos ? @-1 : @(state.selection.begin);
  NSNumber *selectionExtent =
      state.selection.end == std::string::npos ? @-1 : @(state.selection.end);
  return @{
    kComposingBaseKey : composingBase,
    kComposingExtentKey : composingExtent,
    kSelectionAffinityKey : affinityString,
    kSelectionBaseKey : selectionBase,
    kSelectionExtentKey : selectionExtent,
    kSelectionIsDirectionalKey : @NO,
    kTextKey : [NSString stringWithCString:state.text.c_str()
                                  encoding:[NSString defaultCStringEncoding]]
  };
}

- (flutter_desktop_embedding::Range)rangeFromNSRange:(NSRange)range {
  flutter_desktop_embedding::Range new_range;
  if (range.location == NSNotFound) {
    new_range.begin = std::string::npos;
  } else {
    new_range.begin = range.location;
  }
  new_range.end = range.location + range.length;
  return new_range;
}

- (NSRange)NSRangeFromRange:(flutter_desktop_embedding::Range)range {
  return NSMakeRange(range.begin, range.end - range.begin);
}

#pragma MARK - Plugin

- (void)handleMethodCall:(FLEMethodCall *)call result:(FLEMethodResult)result {
  BOOL handled = YES;
  NSString *method = call.methodName;
  if ([method isEqualToString:kSetClientMethod]) {
    if (!call.arguments[0] || !call.arguments[1]) {
      result([[FLEMethodError alloc]
          initWithCode:@"error"
               message:@"Missing arguments"
               details:@"Missing arguments while trying to set a text input client"]);
      return;
    }
    NSNumber *clientID = call.arguments[0];
    if (clientID != nil &&
        (_activeClientID == nil || ![_activeClientID isEqualToNumber:clientID])) {
      _activeClientID = clientID;
      // TODO: Do we need to preserve state across setClient calls?
      NSDictionary *client_config = call.arguments[1];
      NSDictionary *inputTypeInfo = client_config[kTextInputType];
      NSString *inputType = inputTypeInfo[kTextInputTypeName];
      NSString *inputAction = client_config[kTextInputAction];
      if (!inputType || !inputAction) {
        result([[FLEMethodError alloc] initWithCode:@"error"
                                            message:@"Failed to create an input model"
                                            details:@"Configuration arguments might be missing"]);
        return;
      }
      active_model = std::make_unique<flutter_desktop_embedding::TextInputModel>(
          [inputType UTF8String], [inputAction UTF8String]);
    }
  } else if ([method isEqualToString:kShowMethod]) {
    [self.flutterViewController addKeyResponder:self];
    [_textInputContext activate];
  } else if ([method isEqualToString:kHideMethod]) {
    [self.flutterViewController removeKeyResponder:self];
    [_textInputContext deactivate];
  } else if ([method isEqualToString:kClearClientMethod]) {
    _activeClientID = nil;
  } else if ([method isEqualToString:kSetEditingStateMethod]) {
    NSDictionary *args = call.arguments;
    flutter_desktop_embedding::State state = [self stateFromDictionary:args];
    active_model->UpdateState(state);
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
  NSDictionary *state = [self dictionaryFromState:active_model->GetState()];
  [_channel invokeMethod:kUpdateEditStateResponseMethod arguments:@[ _activeClientID, state ]];
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
  active_model->MoveCursorBack();
  [self updateEditState];
}

- (void)moveRight:(nullable id)sender {
  active_model->MoveCursorForward();
  [self updateEditState];
}

- (void)deleteForward:(id)sender {
  active_model->Delete();
  [self updateEditState];
}

- (void)deleteBackward:(id)sender {
  active_model->Backspace();
  [self updateEditState];
}

#pragma mark -
#pragma mark NSTextInputClient

- (void)insertText:(id)string replacementRange:(NSRange)range {
  if (range.location == NSNotFound && range.length == 0) {
    active_model->AddString([string UTF8String]);
  } else {
    active_model->ReplaceString([string UTF8String], [self rangeFromNSRange:range]);
  }
  [self updateEditState];
}

- (void)moveUp:(id)sender {
  active_model->MoveCursorUp();
  [self updateEditState];
}

- (void)moveDown:(id)sender {
  active_model->MoveCursorDown();
  [self updateEditState];
}

- (void)doCommandBySelector:(SEL)selector {
  if ([self respondsToSelector:selector]) {
    // Note: The more obvious [self performSelector...] doesn't give ARC enough information to
    // handle retain semantics properly. See https://stackoverflow.com/questions/7017281/ for more
    // information.
    IMP imp = [self methodForSelector:selector];
    typedef void (*Command)(id, SEL, id);
    Command command = (Command)imp;
    command(self, selector, nil);
  }
}

- (void)insertNewline:(id)sender {
  active_model->InsertNewLine();
  [self updateEditState];
  NSString *action = [NSString stringWithCString:active_model->input_action().c_str()
                                        encoding:[NSString defaultCStringEncoding]];
  [_channel invokeMethod:kPerformAction arguments:@[ _activeClientID, action ]];
}

- (void)setMarkedText:(id)string
        selectedRange:(NSRange)selectedRange
     replacementRange:(NSRange)replacementRange {
  if (replacementRange.location != NSNotFound) {
    active_model->ReplaceString([string UTF8String], [self rangeFromNSRange:replacementRange]);
  }
  active_model->SelectText([self rangeFromNSRange:selectedRange]);
  [self updateEditState];
}

- (void)unmarkText {
  flutter_desktop_embedding::Range range;
  range.begin = std::string::npos;
  range.end = std::string::npos;
  active_model->MarkText(range);
}

- (NSRange)selectedRange {
  return [self NSRangeFromRange:active_model->GetState().selection];
}

- (NSRange)markedRange {
  return [self NSRangeFromRange:active_model->GetState().composing];
}

- (BOOL)hasMarkedText {
  flutter_desktop_embedding::State state = active_model->GetState();
  return (state.composing.begin != std::string::npos && state.composing.end != std::string::npos);
}

- (NSAttributedString *)attributedSubstringForProposedRange:(NSRange)range
                                                actualRange:(NSRangePointer)actualRange {
  if (actualRange != nil) *actualRange = range;
  flutter_desktop_embedding::State state = active_model->GetState();
  NSString *text = [NSString stringWithCString:state.text.c_str()
                                      encoding:[NSString defaultCStringEncoding]];
  NSString *substring = [text substringWithRange:range];
  return [[NSAttributedString alloc] initWithString:substring attributes:nil];
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
