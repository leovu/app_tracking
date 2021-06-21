#import "AppTrackingPlugin.h"
#if __has_include(<app_tracking/app_tracking-Swift.h>)
#import <app_tracking/app_tracking-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "app_tracking-Swift.h"
#endif

@implementation AppTrackingPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAppTrackingPlugin registerWithRegistrar:registrar];
}
@end
