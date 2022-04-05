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

#ifndef FL_GTK_KEYMAPS_H_
#define FL_GTK_KEYMAPS_H_

#include <array>
#include <map>

#include <gtk/gtk.h>

extern const std::array<gint, 2270> gdk_keyvals;
extern std::map<uint64_t, uint64_t> gtk_keyval_to_logical_key_map;

#endif  // FL_GTK_KEYMAPS_H_
