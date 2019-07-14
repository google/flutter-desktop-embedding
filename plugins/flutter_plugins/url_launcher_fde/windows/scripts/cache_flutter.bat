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

:: Caches the Flutter artifacts. This unfortunately reproduces logic from
:: Flutter's tool_backend.dart, since currently that step combines building
:: the bundle and running unpack. Future tool changes should simplify this.

set CACHE_DIR=%~1
:: Currently unused, but present now to avoid project changes when unpack needs it later.
set BUILD_MODE=%~2

if defined LOCAL_ENGINE set ENGINE_PARAM=--local-engine=%LOCAL_ENGINE%
if defined FLUTTER_ENGINE set ENGINE_SOURCE_PARAM=--local-engine-src-path=%FLUTTER_ENGINE%

"%FLUTTER_ROOT%\bin\flutter" unpack --target-platform=windows-x64 --cache-dir="%CACHE_DIR%" %ENGINE_PARAM% %ENGINE_SOURCE_PARAM%
