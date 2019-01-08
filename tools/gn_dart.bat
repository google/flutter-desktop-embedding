:: Copyright 2018 Google LLC
::
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::      http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.
@echo off

:: This script wraps GN with a --script-executable pointing at the Dart binary
:: packaged with the Flutter tree.
set BASE_DIR=%~dp0
for /f "delims=" %%i in ('%~dp0flutter_location') do set FLUTTER_DIR=%%i
set FLUTTER_BIN_DIR=%FLUTTER_DIR%\bin
set DART_BIN_DIR=%FLUTTER_BIN_DIR%\cache\dart-sdk\bin

:: Ensure that the Dart SDK has been downloaded.
if not exist %DART_BIN_DIR%\ call %FLUTTER_BIN_DIR%\flutter precache

call gn --script-executable=%DART_BIN_DIR%\dart %*
