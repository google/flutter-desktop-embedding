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
set RUNNER_OUT_DIR=%FLUTTER_APP_DIR%\build\windows_fde
set TOOLS_DIR=%FDE_ROOT%\tools
set GN_OUT_DIR=%FDE_ROOT%\out
for /f "delims=" %%i in ('%TOOLS_DIR%\flutter_location') do set FLUTTER_DIR=%%i

:: Build the Flutter assets.
call %TOOLS_DIR%\build_flutter_assets %FLUTTER_APP_DIR%
if %errorlevel% neq 0 exit /b %errorlevel%

:: TODO: Change the paths below, and add the exe, to make a self-contained bundle,
:: as is done on Linux.

:: Copy the icudtl.dat file from the Flutter tree to the runner directory.
call xcopy /y /d /q %FLUTTER_DIR%\bin\cache\artifacts\engine\windows-x64\icudtl.dat %RUNNER_OUT_DIR%
if %errorlevel% neq 0 exit /b %errorlevel%

:: Copy the embedder DLLs to the target location provided to the script.
call xcopy /y /d /q %GN_OUT_DIR%\flutter_engine.dll %*
if %errorlevel% neq 0 exit /b %errorlevel%
call xcopy /y /d /q %GN_OUT_DIR%\flutter_embedder.dll %*
if %errorlevel% neq 0 exit /b %errorlevel%

