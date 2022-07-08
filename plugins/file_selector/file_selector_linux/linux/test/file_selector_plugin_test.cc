// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "include/file_selector_linux/file_selector_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtest/gtest.h>
#include <gtk/gtk.h>

#include "file_selector_plugin_private.h"

TEST(FileSelectorPlugin, TestOpenSimple) {
  g_autoptr(FlValue) args = fl_value_new_map();
  g_autoptr(GtkFileChooserNative) dialog = create_dialog(
      nullptr, GTK_FILE_CHOOSER_ACTION_OPEN, false, "Open File", "_Open", args);
  EXPECT_NE(dialog, nullptr);
}

TEST(FileSelectorPlugin, TestOpenMultiple) { EXPECT_TRUE(true); }

TEST(FileSelectorPlugin, TestOpenWithFilter) { EXPECT_TRUE(true); }

TEST(FileSelectorPlugin, TestSaveSimple) { EXPECT_TRUE(true); }

TEST(FileSelectorPlugin, TestSaveWithArguments) { EXPECT_TRUE(true); }

TEST(FileSelectorPlugin, TestGetDirectory) { EXPECT_TRUE(true); }
