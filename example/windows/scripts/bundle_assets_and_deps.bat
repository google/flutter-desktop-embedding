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

set FLUTTER_APP_DIR=%~dp0..\..
set ICU_DATA_SOURCE=%FLUTTER_ROOT%\bin\cache\artifacts\engine\windows-x64\icudtl.dat
set ASSET_DIR_NAME=flutter_assets

set FLUTTER_LIBRARY_DIR=%~1
set BUNDLE_DIR=%~2
set DATA_DIR=%BUNDLE_DIR%data
set TARGET_ASSET_DIR=%DATA_DIR%\%ASSET_DIR_NAME%

if not exist "%DATA_DIR%" call mkdir "%DATA_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Build the Flutter assets.
cd "%FLUTTER_APP_DIR%"
call %FLUTTER_ROOT%\bin\flutter build bundle %EXTRA_BUNDLE_FLAGS%
if %errorlevel% neq 0 exit /b %errorlevel%
:: Copy them to the data directory.
if exist "%TARGET_ASSET_DIR%" call rmdir /s /q "%TARGET_ASSET_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%
call xcopy /s /e /i /q "%FLUTTER_APP_DIR%\build\%ASSET_DIR_NAME%" "%TARGET_ASSET_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Copy the icudtl.dat file from the Flutter tree to the data directory.
call xcopy /y /d /q "%ICU_DATA_SOURCE%" "%DATA_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Copy the Flutter DLL to the target location.
call xcopy /y /d /q "%FLUTTER_LIBRARY_DIR%flutter_windows.dll" "%BUNDLE_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%
