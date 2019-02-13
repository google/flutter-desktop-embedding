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
#include "../common/internal/text_input_model.h"

#include <algorithm>
#include <iostream>

// InputType keys.
// https://docs.flutter.io/flutter/services/TextInputType-class.html
static constexpr char kMultilineInputType[] = "TextInputType.multiline";

static constexpr char kLineBreakKey = '\n';

namespace flutter_desktop_embedding {

TextInputModel::TextInputModel(std::string input_type, std::string input_action)
    : input_type_(input_type), input_action_(input_action) {}

TextInputModel::~TextInputModel() {}

State TextInputModel::GetState() const { return state_; }

void TextInputModel::UpdateState(State state) { state_ = state; }

void TextInputModel::ReplaceString(std::string string, Range range) {
  EraseSelected();
  if (range.begin == std::string::npos || range.end == std::string::npos) {
    return;
  }
  state_.text.replace(range.begin, range.end, string);
  MoveCursorToLocation(range.begin + string.length());
}

void TextInputModel::AddCharacter(char c) {
  std::string s(1, c);
  AddString(s);
}

void TextInputModel::AddString(std::string string) {
  EraseSelected();
  state_.text.insert(state_.selection.begin, string);
  MoveCursorToLocation(++state_.selection.begin);
}

bool TextInputModel::EraseSelected() {
  if (state_.selection.begin == state_.selection.end) {
    return false;
  }
  size_t base = std::min(state_.selection.begin, state_.selection.end);
  size_t extent = std::max(state_.selection.begin, state_.selection.end);
  state_.text.erase(base, extent);
  MoveCursorToLocation(base);
  return true;
}

bool TextInputModel::Backspace() {
  // If a selection was deleted, don't delete more characters.
  if (EraseSelected()) {
    return true;
  }
  if (LocationIsAtBeginning(state_.selection.begin)) {
    return false;
  }
  state_.text.erase(state_.selection.begin - 1, 1);
  MoveCursorToLocation(--state_.selection.begin);

  return true;
}

bool TextInputModel::Delete() {
  // If a selection was deleted, don't delete more characters.
  if (EraseSelected()) {
    return true;
  }
  if (LocationIsAtEnd(state_.selection.begin)) {
    return false;
  }
  state_.text.erase(state_.selection.begin, 1);

  return true;
}

bool TextInputModel::LocationIsAtEnd(size_t location) {
  return (location == state_.text.length());
}

bool TextInputModel::LocationIsAtBeginning(size_t location) {
  return (location == 0);
}

bool TextInputModel::MoveCursorToLocation(size_t location) {
  if (location == state_.selection.begin && location == state_.selection.end) {
    return false;
  }
  if (location > state_.text.length() || location == std::string::npos) {
    return false;
  }
  state_.selection.begin = location;
  state_.selection.end = location;
  return true;
}

bool TextInputModel::MoveCursorToBeginning() {
  if (LocationIsAtBeginning(state_.selection.begin)) {
    return false;
  }
  MoveCursorToLocation(0);

  return true;
}

bool TextInputModel::MoveCursorToEnd() {
  if (LocationIsAtEnd(state_.selection.begin)) {
    return false;
  }
  MoveCursorToLocation(state_.text.length());

  return true;
}

bool TextInputModel::MoveCursorForward() {
  if (LocationIsAtEnd(state_.selection.begin)) {
    return false;
  }
  MoveCursorToLocation(++state_.selection.begin);
  return true;
}

bool TextInputModel::MoveCursorBack() {
  if (LocationIsAtBeginning(state_.selection.begin)) {
    return false;
  }
  MoveCursorToLocation(--state_.selection.begin);
  return true;
}

bool TextInputModel::MoveCursorUp() {
  // Only perform for multiline models.
  // Trying to find a line break before position 0 will find the last line
  // break, which is undesired behavior.
  if (input_type_ != kMultilineInputType ||
      LocationIsAtBeginning(state_.selection.begin)) {
    return false;
  }

  // rfind will get the line break before or at the given location. Substract 1
  // to avoid finding the line break the cursor is standing on.
  size_t previous_break =
      state_.text.rfind(kLineBreakKey, state_.selection.begin - 1);
  if (previous_break == std::string::npos) {
    return false;
  }
  // Attempt to find a line break before the previous one. Finding this break
  // helps in the calculation to adjust the cursor to the previous line break,
  // in case there are more than one.
  size_t before_previous = state_.text.rfind(kLineBreakKey, previous_break - 1);

  // |before_previous| will return an unsigned int with the position of the
  // character found. If none is found, std::string::npos is returned,
  // which is a constant to -1. When a line break is found, it includes the line
  // break position. If -1 is returned, it's used to compensate for the missing
  // line break we would otherwise get.
  size_t new_location =
      state_.selection.begin - previous_break + before_previous;

  // It is possible that the calculation above results in a new location further
  // from the previous break. e.g. 'aaaaa\na\naaaaa|a' where | is the position
  // of the cursor. The expected behavior would be to move to the end of the
  // previous line.
  if (new_location > previous_break) {
    new_location = previous_break;
  }
  if (new_location == std::string::npos) {
    new_location = 0;
  }
  MoveCursorToLocation(new_location);
  return true;
}

bool TextInputModel::MoveCursorDown() {
  // Only perform for multiline models.
  if (input_type_ != kMultilineInputType ||
      LocationIsAtEnd(state_.selection.begin))
    return false;

  size_t next_break = state_.text.find(kLineBreakKey, state_.selection.begin);
  if (next_break == std::string::npos) {
    // No need to continue if there's no new line below.
    return false;
  }
  size_t previous_break = std::string::npos;
  if (!LocationIsAtBeginning(state_.selection.begin)) {
    // Avoid looking for line break before position -1.
    previous_break =
        state_.text.rfind(kLineBreakKey, state_.selection.begin - 1);
  }

  // std::string::npos is a constant to -1. When a line break is found, it
  // includes the line break position. If |previous_break| is npos, it's used to
  // compensate for the missing line break we would otherwise get.
  size_t new_location = state_.selection.begin - previous_break + next_break;

  // Find the next break to avoid going over more than one line.
  size_t further_break = state_.text.find(kLineBreakKey, next_break + 1);
  if (further_break != std::string::npos && new_location > further_break) {
    new_location = further_break;
  }
  if (LocationIsAtEnd(new_location) || new_location > state_.text.length()) {
    new_location = state_.text.length();
  }

  MoveCursorToLocation(new_location);
  return true;
}

bool TextInputModel::InsertNewLine() {
  if (input_type_ != kMultilineInputType) {
    return false;
  }
  AddCharacter(kLineBreakKey);
  return true;
}

void TextInputModel::MarkText(Range range) {
  if (range.begin == std::string::npos || range.end > state_.text.length()) {
    std::cerr << "Attempting to mark text out of bounds" << std::endl;
    return;
  }
  state_.composing = range;
}

void TextInputModel::SelectText(Range range) {
  if (range.begin == std::string::npos || range.end > state_.text.length()) {
    std::cerr << "Attempting to select text out of bounds" << std::endl;
    return;
  }
  state_.selection = range;
}

std::string TextInputModel::input_action() const { return input_action_; }

}  // namespace flutter_desktop_embedding
