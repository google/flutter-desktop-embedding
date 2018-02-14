#import "FLEPlugin.h"

/**
 * A FlutterPlugin to handle file choosing affordances. Owned by the FlutterViewController.
 * Responsible for creating and showing instances of NSSavePanel or NSOpenPanel and sending
 * selected file paths to flutter clients, via system channels.
 */
@interface FLEFileChooserPlugin : NSObject<FLEPlugin>

@end
