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
set FLUTTER_APP_DIR=%~dp0..\..
set TOOLS_DIR=%FDE_ROOT%\tools
set GN_OUT_DIR=%FDE_ROOT%\out
for /f "delims=" %%i in ('%TOOLS_DIR%\flutter_location') do set FLUTTER_DIR=%%i
set ICU_DATA_SOURCE=%FLUTTER_DIR%\bin\cache\artifacts\engine\windows-x64\icudtl.dat
set ASSET_DIR_NAME=flutter_assets

set BUNDLE_DIR=%~1
set DATA_DIR=%BUNDLE_DIR%data
set TARGET_ASSET_DIR=%DATA_DIR%\%ASSET_DIR_NAME%

if not exist "%DATA_DIR%" call mkdir "%DATA_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Build the Flutter assets.
call %TOOLS_DIR%\build_flutter_assets %FLUTTER_APP_DIR%
if %errorlevel% neq 0 exit /b %errorlevel%
:: Copy them to the data directory.
if exist "%TARGET_ASSET_DIR%" call rmdir /s /q "%TARGET_ASSET_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%
call xcopy /s /e /i /q "%FLUTTER_APP_DIR%\build\%ASSET_DIR_NAME%" "%TARGET_ASSET_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Copy the icudtl.dat file from the Flutter tree to the data directory.
call xcopy /y /d /q %ICU_DATA_SOURCE% "%DATA_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Copy the embedder DLLs to the target location.
call xcopy /y /d /q %GN_OUT_DIR%\flutter_engine.dll "%BUNDLE_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%
call xcopy /y /d /q %GN_OUT_DIR%\flutter_embedder.dll "%BUNDLE_DIR%"
if %errorlevel% neq 0 exit /b %errorlevel%

