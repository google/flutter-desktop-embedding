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

:: Runs sync_flutter_library.dart, using the output of flutter_location.bat as
:: --flutter_root
@echo off

for /f "delims=" %%i in ('%~dp0flutter_location') do set FLUTTER_DIR=%%i

call %~dp0.\run_dart_tool sync_flutter_library --flutter_root %FLUTTER_DIR% %*
