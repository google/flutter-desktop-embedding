// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import '../args.dart';

/// Takes an [ArgParser] and generates a string of usage (i.e. help) text for
/// its defined options.
///
/// Internally, it works like a tabular printer. The output is divided into
/// three horizontal columns, like so:
///
///     -h, --help  Prints the usage information
///     |  |        |                                 |
///
/// It builds the usage text up one column at a time and handles padding with
/// spaces and wrapping to the next line to keep the cells correctly lined up.
class Usage {
  static const NUM_COLUMNS = 3; // Abbreviation, long name, help.

  /// A list of the [Option]s intermingled with [String] separators.
  final List optionsAndSeparators;

  /// The working buffer for the generated usage text.
  StringBuffer buffer;

  /// The column that the "cursor" is currently on.
  ///
  /// If the next call to [write()] is not for this column, it will correctly
  /// handle advancing to the next column (and possibly the next row).
  int currentColumn = 0;

  /// The width in characters of each column.
  List<int> columnWidths;

  /// The number of sequential lines of text that have been written to the last
  /// column (which shows help info).
  ///
  /// We track this so that help text that spans multiple lines can be padded
  /// with a blank line after it for separation. Meanwhile, sequential options
  /// with single-line help will be compacted next to each other.
  int numHelpLines = 0;

  /// How many newlines need to be rendered before the next bit of text can be
  /// written.
  ///
  /// We do this lazily so that the last bit of usage doesn't have dangling
  /// newlines. We only write newlines right *before* we write some real
  /// content.
  int newlinesNeeded = 0;

  Usage(this.optionsAndSeparators);

  /// Generates a string displaying usage information for the defined options.
  /// This is basically the help text shown on the command line.
  String generate() {
    buffer = new StringBuffer();

    calculateColumnWidths();

    for (var optionOrSeparator in optionsAndSeparators) {
      if (optionOrSeparator is String) {
        // Ensure that there's always a blank line before a separator.
        if (buffer.isNotEmpty) buffer.write("\n\n");
        buffer.write(optionOrSeparator);
        newlinesNeeded = 1;
        continue;
      }

      var option = optionOrSeparator as Option;
      if (option.hide) continue;

      write(0, getAbbreviation(option));
      write(1, getLongOption(option));

      if (option.help != null) write(2, option.help);

      if (option.allowedHelp != null) {
        var allowedNames = option.allowedHelp.keys.toList(growable: false);
        allowedNames.sort();
        newline();
        for (var name in allowedNames) {
          write(1, getAllowedTitle(option, name));
          write(2, option.allowedHelp[name]);
        }
        newline();
      } else if (option.allowed != null) {
        write(2, buildAllowedList(option));
      } else if (option.isFlag) {
        if (option.defaultsTo == true) {
          write(2, '(defaults to on)');
        }
      } else if (option.isMultiple) {
        if (option.defaultsTo != null && option.defaultsTo.isNotEmpty) {
          write(
              2,
              '(defaults to ' +
                  option.defaultsTo.map((value) => '"$value"').join(', ') +
                  ')');
        }
      } else {
        if (option.defaultsTo != null) {
          write(2, '(defaults to "${option.defaultsTo}")');
        }
      }

      // If any given option displays more than one line of text on the right
      // column (i.e. help, default value, allowed options, etc.) then put a
      // blank line after it. This gives space where it's useful while still
      // keeping simple one-line options clumped together.
      if (numHelpLines > 1) newline();
    }

    return buffer.toString();
  }

  String getAbbreviation(Option option) =>
      option.abbr == null ? '' : '-${option.abbr}, ';

  String getLongOption(Option option) {
    var result;
    if (option.negatable) {
      result = '--[no-]${option.name}';
    } else {
      result = '--${option.name}';
    }

    if (option.valueHelp != null) result += "=<${option.valueHelp}>";

    return result;
  }

  String getAllowedTitle(Option option, String allowed) {
    var isDefault = option.defaultsTo is List
        ? option.defaultsTo.contains(allowed)
        : option.defaultsTo == allowed;
    return '      [$allowed]' + (isDefault ? ' (default)' : '');
  }

  void calculateColumnWidths() {
    var abbr = 0;
    var title = 0;
    for (var option in optionsAndSeparators) {
      if (option is! Option) continue;
      if (option.hide) continue;

      // Make room in the first column if there are abbreviations.
      abbr = max(abbr, getAbbreviation(option).length);

      // Make room for the option.
      title = max(title, getLongOption(option).length);

      // Make room for the allowed help.
      if (option.allowedHelp != null) {
        for (var allowed in option.allowedHelp.keys) {
          title = max(title, getAllowedTitle(option, allowed).length);
        }
      }
    }

    // Leave a gutter between the columns.
    title += 4;
    columnWidths = [abbr, title];
  }

  void newline() {
    newlinesNeeded++;
    currentColumn = 0;
    numHelpLines = 0;
  }

  void write(int column, String text) {
    var lines = text.split('\n');

    // Strip leading and trailing empty lines.
    while (lines.length > 0 && lines[0].trim() == '') {
      lines.removeRange(0, 1);
    }

    while (lines.length > 0 && lines[lines.length - 1].trim() == '') {
      lines.removeLast();
    }

    for (var line in lines) {
      writeLine(column, line);
    }
  }

  void writeLine(int column, String text) {
    // Write any pending newlines.
    while (newlinesNeeded > 0) {
      buffer.write('\n');
      newlinesNeeded--;
    }

    // Advance until we are at the right column (which may mean wrapping around
    // to the next line.
    while (currentColumn != column) {
      if (currentColumn < NUM_COLUMNS - 1) {
        buffer.write(padRight('', columnWidths[currentColumn]));
      } else {
        buffer.write('\n');
      }
      currentColumn = (currentColumn + 1) % NUM_COLUMNS;
    }

    if (column < columnWidths.length) {
      // Fixed-size column, so pad it.
      buffer.write(padRight(text, columnWidths[column]));
    } else {
      // The last column, so just write it.
      buffer.write(text);
    }

    // Advance to the next column.
    currentColumn = (currentColumn + 1) % NUM_COLUMNS;

    // If we reached the last column, we need to wrap to the next line.
    if (column == NUM_COLUMNS - 1) newlinesNeeded++;

    // Keep track of how many consecutive lines we've written in the last
    // column.
    if (column == NUM_COLUMNS - 1) {
      numHelpLines++;
    } else {
      numHelpLines = 0;
    }
  }

  String buildAllowedList(Option option) {
    var isDefault = option.defaultsTo is List
        ? option.defaultsTo.contains
        : (value) => value == option.defaultsTo;

    var allowedBuffer = new StringBuffer();
    allowedBuffer.write('[');
    var first = true;
    for (var allowed in option.allowed) {
      if (!first) allowedBuffer.write(', ');
      allowedBuffer.write(allowed);
      if (isDefault(allowed)) {
        allowedBuffer.write(' (default)');
      }
      first = false;
    }
    allowedBuffer.write(']');
    return allowedBuffer.toString();
  }
}

/// Pads [source] to [length] by adding spaces at the end.
String padRight(String source, int length) {
  final result = new StringBuffer();
  result.write(source);

  while (result.length < length) {
    result.write(' ');
  }

  return result.toString();
}
