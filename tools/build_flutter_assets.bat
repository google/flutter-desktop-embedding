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

:: This script runs the necessary Flutter commands to build the Flutter assets
:: than need to be packaged in an embedding application.
:: It should be called with one argument, which is the directory of the
:: Flutter application to build.
SETLOCAL ENABLEDELAYEDEXPANSION

for /f "delims=" %%i in ('%~dp0flutter_location') do set FLUTTER_DIR=%%i
set FLUTTER_BINARY=%FLUTTER_DIR%\bin\flutter

:: To use a custom Flutter engine, uncomment the following variables, and set
:: ENGINE_SRC_PATH to the path on your machine to your Flutter engine tree's
:: src\ directory (and BUILD_TYPE if your engine build is not debug).
::set ENGINE_SRC_PATH=path\to\engine\src
::set BUILD_TYPE=host_debug_unopt
::set EXTRA_FLAGS=--local-engine-src-path %ENGINE_SRC_PATH% --local-engine=%BUILD_TYPE%

cd %1
echo Running %FLUTTER_BINARY% %EXTRA_FLAGS% build bundle
call %FLUTTER_BINARY% %EXTRA_FLAGS% build bundle
