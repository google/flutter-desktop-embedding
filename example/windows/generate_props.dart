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

// This script creates a generated .props file containing various user
// macros needed by the Visual Studio build, adding all of them to the
// build environment for use in build scripts.
import 'dart:io';

void main(List<String> arguments) {
  final outputPath = arguments[0];
  final settings = {
    'FLUTTER_ROOT': arguments[1],
    'EXTRA_BUNDLE_FLAGS': arguments[2],
  };

  File(outputPath).writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ImportGroup Label="PropertySheets" />
  <PropertyGroup Label="UserMacros">
${getUserMacrosContent(settings)}
  </PropertyGroup>
  <PropertyGroup />
  <ItemDefinitionGroup />
  <ItemGroup>
${getItemGroupContent(settings)}
  </ItemGroup>
</Project>''');
}

String getUserMacrosContent(Map<String, String> settings) {
  final macroList = StringBuffer();
  for (final setting in settings.entries) {
    macroList.writeln('    <${setting.key}>${setting.value}</${setting.key}>');
  }
  return macroList.toString();
}

String getItemGroupContent(Map<String, String> settings) {
  final macroList = StringBuffer();
  for (final name in settings.keys) {
    macroList.writeln('''    <BuildMacro Include="$name">
      <Value>\$($name)</Value>
      <EnvironmentVariable>true</EnvironmentVariable>
    </BuildMacro>''');
  }
  return macroList.toString();
}
