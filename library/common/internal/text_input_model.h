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
#ifndef LIBRARY_COMMON_INTERNAL_TEXT_INPUT_MODEL_H_
#define LIBRARY_COMMON_INTERNAL_TEXT_INPUT_MODEL_H_

#include <string>

#ifdef __cplusplus
extern "C" {
#endif

namespace flutter_desktop_embedding {

struct Range {
  size_t begin = std::string::npos;
  size_t end = std::string::npos;
};

struct State {
  std::string text = "";
  std::string text_affinity = "";
  bool isDirectional = false;
  Range selection;
  Range composing;
};

// Handles underlying text input state, using a simple ASCII model.
//
// Ignores special states like "insert mode" for now.
class TextInputModel {
 public:
  // Constructor for TextInputModel. Keeps track of the client's input type and
  // action. There are more values that the client can provide. Add more as
  // needed.
  explicit TextInputModel(const std::string input_type,
                          const std::string input_action);
  virtual ~TextInputModel();

  // Returns the current state.
  State GetState() const;

  // Replace the current state with a new one.
  void UpdateState(State state);

  // Replaces a section of the stored string with a given |string|. |location|
  // is the starting point where the new string will be added. |length| is the
  // number of characters to be substituted from the stored string, starting
  // from |location|. Deletes any previously selected text.
  void ReplaceString(std::string string, Range range);
  // Adds a character.
  //
  // Either appends after the cursor (when selection base and extent are the
  // same), or deletes the selected characters, replacing the text with the
  // character specified.
  void AddCharacter(char c);

  // Adds a string.
  //
  // Either appends after the cursor (when selection base and extent are the
  // same), or deletes the selected characters, replacing the text with the
  // character specified.
  void AddString(std::string string);

  // Erases the currently selected text. Return true if any deletion ocurred.

  // Deletes either the selection, or one character behind the cursor.
  //
  // Deleting one character behind the cursor occurs when the selection base
  // and extent are the same.
  bool Backspace();

  // Deletes either the selection, or one character ahead of the cursor.
  //
  // Deleting one character ahead of the cursor occurs when the selection base
  // and extent are the same.
  //
  // Returns true if any deletion actually occurred.
  bool Delete();

  // Attempts to move the cursor to the beginning.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorToBeginning();

  // Attempts to move the cursor to the end.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorToEnd();

  // Attempts to move the cursor forward.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorForward();

  // Attempts to move the cursor backward.
  //
  // Returns true if the cursor could be moved. Changes base and extent to be
  // equal to either the extent (if extent is at the end of the string), or
  // for extent to be equal to the base.
  bool MoveCursorBack();

  // Attempts to move the cursor to a line above, if any.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorUp();

  // Attempts to move the cursor to a line below, if any.
  //
  // Returns true if the cursor could be moved.
  bool MoveCursorDown();

  // Inserts a new line to the text if the |input_type| is multiline.
  bool InsertNewLine();
  void MarkText(Range range);
  void SelectText(Range range);

  // An action requested by the user on the input client. See available options:
  // https://docs.flutter.io/flutter/services/TextInputAction-class.html
  std::string input_action() const;

 private:
  bool MoveCursorToLocation(size_t location);
  bool EraseSelected();
  bool LocationIsAtEnd(size_t location);
  bool LocationIsAtBeginning(size_t location);

  State state_;

  std::string input_type_;
  std::string input_action_;
};

}  // namespace flutter_desktop_embedding

#ifdef __cplusplus
}
#endif

#endif  // LIBRARY_COMMON_INTERNAL_TEXT_INPUT_MODEL_H_
