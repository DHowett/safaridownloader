#import "DownloaderCommon.h"
#import "SDMVersioning.h"
#import "SDMCommonClasses.h"
#import "DownloadManager.h"
#import "SDDownloadPromptView.h"
Class SDM$BrowserController;
Class SDM$SandCastle;
bool SDM$WildCat = false;

static bool _wildCat = NO;
static bool _fourPointOh = NO;

#import "SDFileType.h"
#import "SDUserSettings.h"

/* {{{ Private and Additional Categories */
@interface UIActionSheet (SDMPrivate)
- (id)buttons;
@end

@interface UIDevice (Wildcat)
- (BOOL)isWildcat;
@end

@interface UIScreen (iOS4)
- (CGFloat)scale;
@end

/* }}} */

void _reloadPreferences(void);

#pragma mark General Hooks/*{{{*/
%hook Application
- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[SDFileType loadAllFileTypes];
	[SDDownloadManager sharedManager]; // Initialize the Download Manager.
	_reloadPreferences();
	%orig;
}

- (void)applicationResume:(void *)event {
	%orig;
	_reloadPreferences();
}

%end
#pragma mark -/*}}}*/

%hook Application
%group Backgrounding
- (BOOL)_suspendForEventsOnly:(BOOL)x {
	return [[SDDownloadManager sharedManager] downloadsRunning] > 0 ? YES : %orig;
}
- (void)applicationWillSuspend {
	if([[SDDownloadManager sharedManager] downloadsRunning] == 0) %orig;
}
%end

- (void)applicationSuspend:(void *)event {
	if([[SDDownloadManager sharedManager] downloadsRunning] == 0) %orig;
	return;
}

- (void)applicationSuspend:(void *)event settings:(id)settings {
	if([[SDDownloadManager sharedManager] downloadsRunning] == 0) %orig;
	return;
}
%end

void _reloadPreferences() {
	[[SDUserSettings sharedInstance] reloadSettings];
}

static void ReloadPrefsNotification (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	_reloadPreferences();
}

// Imported from the other Hook modules.
void _init_customToolbar_legacy(void);
void _init_customToolbar(void);
void _init_browserPanel(void);
void _init_interaction_legacy(void);
void _init_interaction(void);
void _init_webPolicyDelegate(void);

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	%init;
	%init(Backgrounding);

	SDM$BrowserController = %c(BrowserController);
	SDM$SandCastle = %c(SandCastle);
	if([UIDevice instancesRespondToSelector:@selector(isWildcat)] && [[UIDevice currentDevice] isWildcat]) {
		SDM$WildCat = true;
	}

	if(SDMSystemVersionLT(_SDM_iOS_5_0)) {
		_init_customToolbar_legacy();
		_init_interaction_legacy();
	} else {
		_init_customToolbar();
		_init_interaction();
	}
	_init_browserPanel();
	_init_webPolicyDelegate();

	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
	CFNotificationCenterAddObserver(r, NULL, &ReloadPrefsNotification, CFSTR("net.howett.safaridownloader/ReloadPrefs"), NULL, 0);

	[pool drain];
}

// vim:filetype=logos:sw=8:ts=8:noet
