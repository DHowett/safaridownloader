#import "SDMCommon.h"
#import "SDMVersioning.h"
#import "Safari/BrowserController.h"

#import "SDDownloadManager.h"

#import "SDFileType.h"
#import "SDUserSettings.h"

Class SDM$BrowserController;
Class SDM$SandCastle;
bool SDM$WildCat = false;

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

%group OldAuthenticationHooks
%hook AuthenticationView
- (void)setChallenge:(NSURLAuthenticationChallenge *)challenge {
	NSURLAuthenticationChallenge *overrideChallenge = objc_getAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedOverrideAuthenticationChallenge);
	if(overrideChallenge)
		challenge = overrideChallenge;

	%orig();
}
%end

%hook BrowserController
- (void)logInFromAuthenticationView:(id)authenticationView withCredential:(NSURLCredential *)credential {
	NSURLAuthenticationChallenge *overrideChallenge = objc_getAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedOverrideAuthenticationChallenge);
	if(!overrideChallenge) {
		%orig;
		return;
	}

	[[overrideChallenge sender] useCredential:credential forAuthenticationChallenge:overrideChallenge];
	objc_setAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedOverrideAuthenticationChallenge, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self hideBrowserPanelType:5];
}

- (void)cancelFromAuthenticationView:(id)authenticationView {
	NSURLAuthenticationChallenge *overrideChallenge = objc_getAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedOverrideAuthenticationChallenge);
	if(!overrideChallenge) {
		%orig;
		return;
	}

	[[overrideChallenge sender] cancelAuthenticationChallenge:overrideChallenge];
	objc_setAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedOverrideAuthenticationChallenge, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self _setShowingCurrentPanel:NO];
}
%end
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

	dlopen("/Library/MobileSubstrate/DynamicLibraries/sandcastleclient.dylib", RTLD_NOW);

	%init;
	%init(Backgrounding);
	if(%c(AuthenticationView) != nil) {
		%init(OldAuthenticationHooks);
	}

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
