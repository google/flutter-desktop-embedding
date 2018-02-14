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

#import "FLETextInputModel.h"

static NSString *const kTextAffinityDownstream = @"TextAffinity.downstream";
static NSString *const kTextAffinityUpstream = @"TextAffinity.upstream";

static NSString *const kSelectionBaseKey = @"selectionBase";
static NSString *const kSelectionExtentKey = @"selectionExtent";
static NSString *const kSelectionAffinityKey = @"selectionAffinity";
static NSString *const kSelectionIsDirectionalKey = @"selectionIsDirectional";
static NSString *const kComposingBaseKey = @"composingBase";
static NSString *const kComposingExtentKey = @"composingExtent";
static NSString *const kTextKey = @"text";

/**
 * These three static methods are necessary because Cocoa and Flutter have different idioms for
 * signalling an empty range: Flutter uses {-1, -1} while Cocoa uses {NSNotFound, 0}. Also,
 * despite the name, the "extent" fields are actually end indices, not lengths.
 */

/**
 * Updates a range given base and extent fields.
 */
static NSRange UpdateRangeFromBaseExtent(NSNumber *base, NSNumber *extent, NSRange range) {
  if (base == nil || extent == nil) {
    return range;
  }
  if (base.intValue == -1 && extent.intValue == -1) {
    range.location = NSNotFound;
    range.length = 0;
  } else {
    range.location = [base unsignedLongValue];
    range.length = [extent unsignedLongValue] - range.location;
  }
  return range;
}

/**
 * Returns the appropriate base field for a given range.
 */
static long GetBaseForRange(NSRange range) {
  if (range.location == NSNotFound) {
    return -1;
  }
  return range.location;
}

/**
 * Returns the appropriate extent field for a given range.
 */
static long GetExtentForRange(NSRange range) {
  if (range.location == NSNotFound) {
    return -1;
  }
  return range.location + range.length;
}

@implementation FLETextInputModel

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _text = [[NSMutableString alloc] init];
    _selectedRange = NSMakeRange(NSNotFound, 0);
    _markedRange = NSMakeRange(NSNotFound, 0);
    _textAffinity = FLETextAffinityUpstream;
  }
  return self;
}

- (NSDictionary *)state {
  NSString *const textAffinity =
      (_textAffinity == FLETextAffinityUpstream) ? kTextAffinityUpstream : kTextAffinityDownstream;
  NSDictionary *state = @{
    kSelectionBaseKey : @(GetBaseForRange(_selectedRange)),
    kSelectionExtentKey : @(GetExtentForRange(_selectedRange)),
    kSelectionAffinityKey : textAffinity,
    kSelectionIsDirectionalKey : @NO,
    kComposingBaseKey : @(GetBaseForRange(_markedRange)),
    kComposingExtentKey : @(GetExtentForRange(_markedRange)),
    kTextKey : _text
  };
  return state;
}

- (void)setState:(NSDictionary *)state {
  if (state == nil) return;

  _selectedRange = UpdateRangeFromBaseExtent(state[kSelectionBaseKey], state[kSelectionExtentKey],
                                             _selectedRange);
  NSString *selectionAffinity = state[kSelectionAffinityKey];
  if (selectionAffinity != nil) {
    _textAffinity = [selectionAffinity isEqualToString:kTextAffinityUpstream]
                        ? FLETextAffinityUpstream
                        : FLETextAffinityDownstream;
  }
  _markedRange =
      UpdateRangeFromBaseExtent(state[kComposingBaseKey], state[kComposingExtentKey], _markedRange);
  NSString *text = state[kTextKey];
  if (text != nil) [_text setString:text];
}

@end
