# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$GN_URI = 'https://chrome-infra-packages.appspot.com/dl/gn/gn/windows-amd64/+/latest'
$NINJA_URI = 'https://github.com/ninja-build/ninja/releases/download/v1.9.0/ninja-win.zip'
$TEMP_LOCATION = '{0}\tool.zip' -f $env:temp

if (!(Test-Path $env:temp)) {
  New-Item -ItemType Directory -Path $env:temp | Out-Null
}

Write-Output ('Installing GN tools to {0}' -f $args[0])

# Ninja download requires TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Output ('Downloading {0}' -f $GN_URI)
(New-Object System.Net.WebClient).DownloadFile($GN_URI, $TEMP_LOCATION)
Expand-Archive $TEMP_LOCATION -DestinationPath $args[0]

Write-Output ('Downloading {0}' -f $NINJA_URI)
(New-Object System.Net.WebClient).DownloadFile($NINJA_URI, $TEMP_LOCATION)
Expand-Archive $TEMP_LOCATION -DestinationPath $args[0]
