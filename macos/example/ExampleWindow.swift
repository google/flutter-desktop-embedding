// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Cocoa

class ExampleWindow: NSWindow {
  @IBOutlet weak var flutterViewController: FLEViewController!

  override func awakeFromNib() {
    // TODO: Package all the Flutter resources, and use bundle-relative paths. For now, the path to
    // the sample Flutter app in the source tree is passed as a command-line argument.
    let baseURL = NSURL.fileURL(withPath: CommandLine.arguments.remove(at: 1))
    let assets = NSURL.fileURL(withPath: "build/flutter_assets", relativeTo: baseURL)
    let main = NSURL.fileURL(withPath: "lib/main.dart", relativeTo: baseURL)
    let packages = NSURL.fileURL(withPath: ".packages", relativeTo: baseURL)
    flutterViewController.launchEngine(
      withMainPath: main,
      assetsPath: assets,
      packagesPath: packages,
      asHeadless: false,
      commandLineArguments: [CommandLine.arguments[0], "--dart-non-checked-mode"])

    super.awakeFromNib()
  }
}

