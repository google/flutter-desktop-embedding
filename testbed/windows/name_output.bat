:: Copyright 2019 Google LLC
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

:: This script outputs the path to the executable that is created by
:: build.bat for the given configuration ("debug" or "release").
::
:: Having this file in this location, with this name, enables the current
:: experimental 'flutter run' support for desktop.
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set FLUTTER_CONFIG=%1

set PROJECT_NAME=Runner
set EXE_NAME=Flutter Desktop Example

set BASE_DIR=%~dp0
set FLUTTER_APP_DIR=%BASE_DIR%..\
set PRODUCTS_DIR=%FLUTTER_APP_DIR%build\windows\x64\

if "%FLUTTER_CONFIG%"=="release" (
  set BUILD_CONFIG=Release
) else (
  set BUILD_CONFIG=Debug
)
  
echo %PRODUCTS_DIR%%BUILD_CONFIG%\%PROJECT_NAME%\%EXE_NAME%.exe
