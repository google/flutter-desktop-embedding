# Copyright 2018 Google LLC
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

$CHANNEL = 'stable'
$VERSION = '1.0.0'

$DOWNLOAD_BASE = 'https://storage.googleapis.com/flutter_infra/releases'
$DOWNLOAD_URI = '{0}/{1}/windows/flutter_windows_v{2}-{1}.zip' -f $DOWNLOAD_BASE, $CHANNEL, $VERSION
$TEMP_LOCATION = '{0}\flutter.zip' -f $env:temp

if (!(Test-Path $env:temp)) {
  New-Item -ItemType Directory -Path $env:temp | Out-Null
}

Write-Output ('Downloading {0}' -f $DOWNLOAD_URI)
(New-Object System.Net.WebClient).DownloadFile($DOWNLOAD_URI, $TEMP_LOCATION)
Expand-Archive $TEMP_LOCATION -DestinationPath $args[0]
