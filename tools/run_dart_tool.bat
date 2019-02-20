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
@echo off

for /f "delims=" %%i in ('%~dp0flutter_location') do set FLUTTER_DIR=%%i
set FLUTTER_BIN_DIR=%FLUTTER_DIR%\bin
set DART_BIN_DIR=%FLUTTER_BIN_DIR%\cache\dart-sdk\bin

if not exist %FLUTTER_DIR%\ (
  echo No Flutter directory at %FLUTTER_DIR%.
  echo Please see the setup instructions in the README.
  exit /b
)

:: Ensure that the Dart SDK has been downloaded.
if not exist %DART_BIN_DIR%\ call %FLUTTER_BIN_DIR%\flutter precache
if %errorlevel% neq 0 exit /b %errorlevel%

set DART_TOOL=%1
for /f "tokens=1,*" %%a in ("%*") do set TOOL_PARAMS=%%b

call %DART_BIN_DIR%\dart %~dp0.\dart_tools\bin\%DART_TOOL%.dart %TOOL_PARAMS%
