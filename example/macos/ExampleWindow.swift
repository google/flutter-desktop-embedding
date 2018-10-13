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
    flutterViewController.add(FLEColorPanelPlugin())
    flutterViewController.add(FLEFileChooserPlugin())
    flutterViewController.add(FLEMenubarPlugin())

    let assets = NSURL.fileURL(withPath: "flutter_assets", relativeTo: Bundle.main.resourceURL)
    // Pass through argument zero, since the Flutter engine expects to be processing a full
    // command line string.
    var arguments = [CommandLine.arguments[0]];
#if !DEBUG
    arguments.append("--dart-non-checked-mode");
#endif
    flutterViewController.launchEngine(
      withAssetsPath: assets,
      asHeadless: false,
      commandLineArguments: arguments)

    super.awakeFromNib()
  }
}

