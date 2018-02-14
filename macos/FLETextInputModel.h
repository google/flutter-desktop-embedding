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

#import <Foundation/Foundation.h>

/**
 * The affinity of the current cursor position. If the cursor is at a position representing
 * a line break, the cursor may be drawn either at the end of the current line (upstream)
 * or at the beginning of the next (downstream).
 */
typedef NS_ENUM(NSUInteger, FLETextAffinity) { FLETextAffinityUpstream, FLETextAffinityDownstream };

/**
 * Data model representing text input state during an editing session.
 */
@interface FLETextInputModel : NSObject

/**
 * The full text being edited.
 */
@property(nonnull, copy) NSMutableString *text;
/**
 * The range of text currently selected. This may have length zero to represent a single
 * cursor position.
 */
@property NSRange selectedRange;
/**
 * The affinity for the current cursor position.
 */
@property FLETextAffinity textAffinity;
/**
 * The range of text that is marked for edit, i.e. under the effects of a multi-keystroke input
 * combination.
 */
@property NSRange markedRange;

/**
 * Representation of the model's data as a state dictionary suitable for interchange with the
 * Flutter Dart layer.
 */
@property(nonnull) NSDictionary *state;

@end
