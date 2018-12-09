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

:: Find where VS lives and start a VC command prompt
set pre=Microsoft.VisualStudio.Product.
set ids=%pre%Community %pre%Professional %pre%Enterprise %pre%BuildTools
 
pushd "C:\Program Files (x86)\Microsoft Visual Studio\Installer\"
for /f "usebackq tokens=1* delims=: " %%i in (`vswhere -latest -products *`) do (if /i "%%i"=="installationPath" set InstallDir=%%j)
popd

pushd %InstallDir%\VC\Auxiliary\Build
call vcvarsall.bat x86_amd64
popd

set DEPENDDIREXISTS=true
if not exist %~dp0..\dependencies\json\allocator.h set DEPENDDIREXISTS=false

if %DEPENDDIREXISTS% == true (
    echo jsoncpp found.
    goto DONE
)

set THIRDPARTYDIREXISTS=true
if not exist %~dp0..\third_party set THIRDPARTYDIREXISTS=false

if %THIRDPARTYDIREXISTS% == false (
    mkdir %~dp0..\third_party
)

set JSONDIREXISTS=true
if not exist %~dp0..\third_party\jsoncpp set JSONDIREXISTS=false

if %JSONDIREXISTS% == false (
    mkdir %~dp0..\third_party\jsoncpp
)

set JSONEXISTS=true
if not exist %~dp0..\third_party\jsoncpp\README.md set JSONEXISTS=false

:: Clone source
if %JSONEXISTS% == false (
    echo Cloning via git clone --branch supportvs2017 https://github.com/clarkezone/jsoncpp.git %~dp0..\third_party\jsoncpp
    call git clone --branch supportvs2017 https://github.com/clarkezone/jsoncpp.git %~dp0..\third_party\jsoncpp
)

:: Copy headers
copy %~dp0..\third_party\jsoncpp\include\json\*.h %~dp0..\dependencies\json\.


:: Build debug lib
echo Building debug lib: msbuild %~dp0..\third_party\jsoncpp\makefiles\msvc2017\lib_json.vcxproj 
msbuild %~dp0..\third_party\jsoncpp\makefiles\msvc2017\lib_json.vcxproj

set DEPBINDIREXISTS=true
if not exist %~dp0..\dependencies\json\x64 set DEPBINDIREXISTS=false

if %DEPBINDIREXISTS% == false (
    mkdir %~dp0..\dependencies\json\x64
)

set DEPBINDBGDIREXISTS=true
if not exist %~dp0..\dependencies\json\x64\debug set DEPBINDBGDIREXISTS=false

if %DEPBINDBGDIREXISTS% == false (
    mkdir %~dp0..\dependencies\json\x64\debug
)

copy %~dp0..\third_party\jsoncpp\makefiles\msvc2017\x64\debug\json_vc71_libmtd.lib %~dp0..\dependencies\json\x64\debug\.

:: Build release lib
echo Building release lib: msbuild %~dp0..\third_party\jsoncpp\makefiles\msvc2017\lib_json.vcxproj /p:Configuration=Release
msbuild %~dp0..\third_party\jsoncpp\makefiles\msvc2017\lib_json.vcxproj /p:Configuration=Release

set DEPBINRELDIREXISTS=true
if not exist %~dp0..\dependencies\json\x64\release set DEPBINRELDIREXISTS=false

if %DEPBINRELDIREXISTS% == false (
    mkdir %~dp0..\dependencies\json\x64\release
)

copy %~dp0..\third_party\jsoncpp\makefiles\msvc2017\x64\release\json_vc71_libmt.lib %~dp0..\dependencies\json\x64\release\.

:: Remove source
rmdir /s /q %~dp0..\third_party

:DONE
echo jsoncpplib complete.