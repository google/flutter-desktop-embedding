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

set INTERMEDIATE_DIR=%~1
set LOCAL_COPY_DIR=%INTERMEDIATE_DIR%flutter_library\
set FLUTTER_CACHE_DIR=%FLUTTER_ROOT%\bin\cache\artifacts\engine\windows-x64\

:: Sync the Flutter library, removing previous copies to ensure
:: that stale files don't stay in the copy.
call %FLUTTER_ROOT%\bin\flutter precache --windows --no-android --no-ios
if %errorlevel% neq 0 exit /b %errorlevel%
echo rmdir /s /q "%LOCAL_COPY_DIR%"
rmdir /s /q "%LOCAL_COPY_DIR%"
echo mkdir "%LOCAL_COPY_DIR%"
mkdir "%LOCAL_COPY_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

xcopy /q /i "%FLUTTER_CACHE_DIR%"flutter_windows.* "%LOCAL_COPY_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%
xcopy /q /i "%FLUTTER_CACHE_DIR%"flutter_*.h "%LOCAL_COPY_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%
xcopy /q /i /s "%FLUTTER_CACHE_DIR%"cpp_client_wrapper "%LOCAL_COPY_DIR%"cpp_client_wrapper
if %errorlevel% neq 0 exit /b %errorlevel%
