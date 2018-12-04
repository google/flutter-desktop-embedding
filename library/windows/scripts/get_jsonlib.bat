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

set DEPENDSDIREXISTS=true
if not exist %~dp0..\dependencies set DEPENDSDIREXISTS=false

if %DEPENDSDIREXISTS% == false (
    mkdir %~dp0..\dependencies
)

set JSONEXISTS=true
if not exist %~dp0..\dependencies\json\json.h set JSONEXISTS=false

if %JSONEXISTS%==false (
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri https://github.com/clarkezone/jsoncpp/releases/download/1.8.4/jsoncpp.zip -OutFile "%~dp0..\dependencies\jsoncpp.zip
    PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath %~dp0..\dependencies\jsoncpp.zip -DestinationPath "%~dp0..\dependencies\json
    DEL %~dp0..\dependencies\jsoncpp.zip
) else (
    ECHO JSON dependencies found.
)

:DONE

