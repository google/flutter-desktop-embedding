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

:: This script does a Windows build using msbuild.
::
:: Having this file in this location, with this name, enables the current
:: experimental 'flutter build' support for desktop.

@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set FLUTTER_ROOT=%1
set FLUTTER_CONFIG=%2
set TRACK_WIDGET_CREATION=%3

set SOLUTION_NAME=Runner

set BASE_DIR=%~dp0
set FLUTTER_APP_DIR=%BASE_DIR%..\
set PRODUCTS_DIR=%FLUTTER_APP_DIR%build\windows\x86\

if "%FLUTTER_CONFIG%"=="release" (
  set BUILD_CONFIG=Release
) else (
  set BUILD_CONFIG=Debug
)

if "%TRACK_WIDGET_CREATION%"=="track-widget-creation" (
  set EXTRA_BUNDLE_FLAGS=--track-widget-creation
)

set DART_BIN_DIR=%FLUTTER_ROOT%\bin\cache\dart-sdk\bin\

:: Write build settings to Generated.props
call "%DART_BIN_DIR%dart" "%BASE_DIR%generate_props.dart" "%BASE_DIR%Generated.props" "%FLUTTER_ROOT%" "%EXTRA_BUNDLE_FLAGS%"

:: Attempt to locate and run vcvars64.bat
for /f "delims=" %%i in ('%DART_BIN_DIR%dart %BASE_DIR%.\find_vcvars.dart') do set VCVARS_PATH=%%i
if "%VCVARS_PATH%" == "" (
  echo #######################################################################
  echo # Warning: Unable to find vcvars64.bat. Proceeding anyway; if it fails,
  echo # run vcvars64.bat manually in this console then try again.
  echo #######################################################################
) else (
  call "%VCVARS_PATH%"
  if %errorlevel% neq 0 exit /b %errorlevel%
)

:: Build the project.
msbuild "%BASE_DIR%%SOLUTION_NAME%.sln" /p:Configuration=%BUILD_CONFIG%
