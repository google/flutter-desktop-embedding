// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'arg_parser.dart';
import 'arg_results.dart';
import 'option.dart';
import 'parser.dart';

/// An ArgParser that treats *all input* as non-option arguments.
class AllowAnythingParser implements ArgParser {
  Map<String, Option> get options => const {};
  Map<String, ArgParser> get commands => const {};
  bool get allowTrailingOptions => false;
  bool get allowsAnything => true;

  ArgParser addCommand(String name, [ArgParser parser]) {
    throw new UnsupportedError(
        "ArgParser.allowAnything().addCommands() isn't supported.");
  }

  void addFlag(String name,
      {String abbr,
      String help,
      bool defaultsTo: false,
      bool negatable: true,
      void callback(bool value),
      bool hide: false}) {
    throw new UnsupportedError(
        "ArgParser.allowAnything().addFlag() isn't supported.");
  }

  void addOption(String name,
      {String abbr,
      String help,
      String valueHelp,
      Iterable<String> allowed,
      Map<String, String> allowedHelp,
      String defaultsTo,
      Function callback,
      bool allowMultiple: false,
      bool splitCommas,
      bool hide: false}) {
    throw new UnsupportedError(
        "ArgParser.allowAnything().addOption() isn't supported.");
  }

  void addMultiOption(String name,
      {String abbr,
      String help,
      String valueHelp,
      Iterable<String> allowed,
      Map<String, String> allowedHelp,
      Iterable<String> defaultsTo,
      void callback(List<String> values),
      bool splitCommas: true,
      bool hide: false}) {
    throw new UnsupportedError(
        "ArgParser.allowAnything().addMultiOption() isn't supported.");
  }

  void addSeparator(String text) {
    throw new UnsupportedError(
        "ArgParser.allowAnything().addSeparator() isn't supported.");
  }

  ArgResults parse(Iterable<String> args) =>
      new Parser(null, this, args.toList()).parse();

  String getUsage() => usage;

  String get usage => "";

  getDefault(String option) {
    throw new ArgumentError('No option named $option');
  }

  Option findByAbbreviation(String abbr) => null;
}
