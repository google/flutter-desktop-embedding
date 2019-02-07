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

set FDE_ROOT=%~dp0..\..\..
set GN_OUT_DIR=%FDE_ROOT%\out

call %FDE_ROOT%\tools\gn_dart gen %GN_OUT_DIR%
if %errorlevel% neq 0 exit /b %errorlevel%
ninja -C %GN_OUT_DIR%
