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
SETLOCAL ENABLEDELAYEDEXPANSION

set BASE_DIR=%~dp0
set CONFIG_FILE_DIR=%BASE_DIR%..\..\
set CONFIG_FILE=%CONFIG_FILE_DIR%.flutter_location_config

:: Default to a sibling directory to this repository.
set FLUTTER_DIR=%BASE_DIR%..\..\flutter

:: If the config file is present, use that instead.
if exist %CONFIG_FILE% (
  set /p OVERRIDE_DIR=<%CONFIG_FILE%

  :: If the path is realative, treat it as relative to the directory containing the config file.
  if "!OVERRIDE_DIR:~0,2!"==".." (
    set OVERRIDE_DIR=%CONFIG_FILE_DIR%!OVERRIDE_DIR!
  ) else if "!OVERRIDE_DIR:~0,1!"=="." (
    set OVERRIDE_DIR=%CONFIG_FILE_DIR%!OVERRIDE_DIR:~2!
  )
  
  set FLUTTER_DIR=!OVERRIDE_DIR!
)

:: Normalize the path if possible.
if exist %FLUTTER_DIR% (
  cd %FLUTTER_DIR%
  set FLUTTER_DIR=!CD!
)

echo %FLUTTER_DIR%