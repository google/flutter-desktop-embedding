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

cd %~dp0..\dependencies\GLFW\

:: Check that GLFW isn't already setup.
set EXISTS=true
if not exist glfw3.h set EXISTS=false
if not exist glfw3.lib set EXISTS=false

if %EXISTS%==false (
  :: Download zip folder with correct TLS version.
  PowerShell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri http://github.com/glfw/glfw/releases/download/3.2.1/glfw-3.2.1.bin.WIN64.zip -OutFile GLFW.zip"
  
  :: Expand folder.
  PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive GLFW.zip -DestinationPath GLFW"
  
  :: Copy required files into GLFW directory.
  COPY GLFW\glfw-3.2.1.bin.WIN64\include\GLFW\glfw3.h >NUL
  COPY GLFW\glfw-3.2.1.bin.WIN64\lib-vc2015\glfw3.lib >NUL
  
  :: Cleanup.
  DEL GLFW.zip
  RD /S /Q GLFW
)