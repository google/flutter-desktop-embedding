// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter_linux/flutter_linux.h>

#include "include/file_selector_plugin/file_selector_plugin.h"

// TODO(stuartmorgan): Remove this private header and change the below back to
// a static function once https://github.com/flutter/flutter/issues/88724
// is fixed, and test through the public API instead.

// Creates a GtkFileChooserNative for the given method call details.
GtkFileChooserNative* create_dialog(GtkWindow* window,
                                    GtkFileChooserAction action,
                                    bool choose_directory, const gchar* title,
                                    const gchar* default_confirm_button_text,
                                    FlValue* properties);
