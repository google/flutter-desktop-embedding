//
//  Generated file. Do not edit.
//

#import "GeneratedPluginRegistrant.h"
#import <color_panel/ColorPanelPlugin.h>
#import <example_plugin/ExamplePlugin.h>
#import <file_chooser/FileChooserPlugin.h>
#import <menubar/MenubarPlugin.h>
#import <window_size/WindowSizePlugin.h>

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FLEColorPanelPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLEColorPanelPlugin"]];
  [FDEExamplePlugin registerWithRegistrar:[registry registrarForPlugin:@"FDEExamplePlugin"]];
  [FLEFileChooserPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLEFileChooserPlugin"]];
  [FLEMenubarPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLEMenubarPlugin"]];
  [FLEWindowSizePlugin registerWithRegistrar:[registry registrarForPlugin:@"FLEWindowSizePlugin"]];
}

@end
