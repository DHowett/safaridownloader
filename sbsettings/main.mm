#import <Foundation/Foundation.h>

#define PREFERENCES_FILE @"/var/mobile/Library/Preferences/net.howett.safaridownloader.plist"

extern "C" BOOL isCapable() {
 	return YES;
}

extern "C" BOOL isEnabled() {
	NSDictionary *userPrefs = [NSDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE];
	BOOL disabled = [[userPrefs objectForKey:@"Disabled"] boolValue];
	return !disabled;
}

extern "C" float getDelayTime() { return 1.0f; }

extern "C" void setState(BOOL enabled) {
	BOOL disabled = !enabled;
	NSMutableDictionary *userPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE];
	[userPrefs setValue:[NSNumber numberWithBool:disabled] forKey:@"Disabled"];
	[userPrefs writeToFile:PREFERENCES_FILE atomically:NO];
	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterPostNotification(r, CFSTR("net.howett.safaridownloader/ReloadPrefs"), NULL, NULL, true);
	return;
}
