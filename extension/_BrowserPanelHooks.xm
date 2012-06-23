#import "SDMCommon.h"
#import "SDMVersioning.h"
#import "SDDownloadManager.h"

#import "SDNavigationController.h"
#import "SDDownloadListViewController.h"
#import "SDDownloadPromptViewController.h"
#import "SDFileBrowserNavigationController.h"

#import "Safari/BrowserController.h"
#import "Safari/TabController.h"
#import "Safari/RotatablePopoverController.h"

/* {{{ Private and Additional Categories */
@interface BrowserController (SDMAdditions)
- (void)_setShowingDownloads:(BOOL)showing animate:(BOOL)animate;
- (void)_presentModalViewController:(id)viewController fromButton:(UIView *)button;
- (void)_presentModalViewControllerFromDownloadsButton:(id)x;
- (void)toggleDownloadManagerFromButtonBar;
- (void)_setBrowserPanel:(id)panel;
- (void)setBrowserPanel:(id)panel;
- (id)browserLayer;
- (void)_forceDismissModalViewController:(BOOL)animate;
@end

@interface BrowserController (SafariFour)
- (void)setCurrentPopoverController:(UIPopoverController *)p;
@end

@interface UIActionSheet (Private2)
- (void)presentFromRect:(CGRect)rect inView:(UIView *)view direction:(NSInteger)direction allowInteractionWithViews:(NSArray *)views backgroundStyle:(NSInteger)backgroundStyle animated:(BOOL)animated;
@end
/* }}} */

%hook BrowserController
- (id)_panelForPanelType:(int)type {
	%log;
	if(type == SDPanelTypeDownloadManager) {
		UIViewController *rootViewController = [[[SDDownloadListViewController alloc] init] autorelease];
		return [[[SDNavigationController alloc] initWithRootViewController:rootViewController] autorelease];
	} else if(type == SDPanelTypeDownloadPrompt) {
		SDDownloadRequest *req = [SDDownloadRequest pendingRequestForContext:[[self tabController] activeTabDocument]];
		if(!req)
			req = [SDDownloadRequest pendingRequestForContext:MSHookIvar<id>([self tabController], "_destinationTabDocument")];
		if(!req) return nil;
		UIViewController *rootViewController = [[[SDDownloadPromptViewController alloc] initWithDownloadRequest:req delegate:[SDDownloadManager sharedManager]] autorelease];
		return [[[SDNavigationController alloc] initWithRootViewController:rootViewController] autorelease];
	} else if(type == SDPanelTypeFileBrowser) {
		SDDownloadRequest *req = [SDDownloadRequest pendingRequestForContext:[[self tabController] activeTabDocument]];
		SDFileBrowserNavigationController *fileBrowser = [[[SDFileBrowserNavigationController alloc] initWithMode:SDFileBrowserModeImmediateDownload downloadRequest:req] autorelease];
		fileBrowser.fileBrowserDelegate = [SDDownloadManager sharedManager];
		return fileBrowser;
	}
	return %orig;
}

static void _setShowingCurrentPanel_animate_core(id self, BOOL showing, BOOL animate) {
	id<BrowserPanel> panel = MSHookIvar<id>(self, "_browserPanel");
	if([panel panelType] == SDPanelTypeDownloadManager) {
		if(SDMSystemVersionGE(_SDM_iOS_3_2))
			[MSHookIvar<id>(self, "_browserView") resignFirstResponder];
		if(SDMSystemVersionLT(_SDM_iOS_5_0))
			[self _resizeNavigationController:panel small:NO];
		[self _setShowingDownloads:showing animate:animate];
	} else if([panel panelType] == SDPanelTypeDownloadPrompt || [panel panelType] == SDPanelTypeFileBrowser) {
		UIViewController *presentationController = SDMSystemVersionLT(_SDM_iOS_5_0) ? [self _modalViewController] : MSHookIvar<UIViewController *>(self, "_rootViewController");
		if(showing) {
			if(SDMSystemVersionLT(_SDM_iOS_5_0))
				[self _resizeNavigationController:panel small:NO];
			[presentationController presentModalViewController:(UIViewController *)panel animated:animate];
			//[self _presentModalViewController:panel fromRectInToolbar:CGRectZero];
		} else {
			[self willHideBrowserPanel:panel];
			[presentationController dismissModalViewControllerAnimated:animate];
			//[self _forceDismissModalViewController:animate]; // 3.2+
		}
	}
}

- (void)_setShowingCurrentPanel:(BOOL)showing animate:(BOOL)animate {
	%log;
	%orig;
	_setShowingCurrentPanel_animate_core(self, showing, animate);
}

%group Firmware_lt_32
- (void)_setShowingCurrentPanel:(BOOL)showing {
	%log;
	%orig;
	_setShowingCurrentPanel_animate_core(self, showing, YES);
}
%end

%group Firmware_ge_32
%new(v@:)
- (void)toggleDownloadManagerFromButtonBar {
	if([[self browserPanel] panelType] == SDPanelTypeDownloadManager) {
		[[self browserPanel] performSelector:@selector(close)];
	} else {
		[self showBrowserPanelType:SDPanelTypeDownloadManager];
	}
}
%end

%group Firmware_lt_32
%new(v@:)
- (void)toggleDownloadManagerFromButtonBar {
	if([[self browserPanel] panelType] == SDPanelTypeDownloadManager) {
		[self hideBrowserPanelType:SDPanelTypeDownloadManager];
	} else {
		[self showBrowserPanelType:SDPanelTypeDownloadManager];
	}
}
%end

%new(v@:ii)
- (void)_setShowingDownloads:(BOOL)showing animate:(BOOL)animate {
	id controller = [self browserPanel];
	if(showing) {
		if(SDMSystemVersionLT(_SDM_iOS_5_0))
			[self _resizeNavigationController:controller small:NO];
		[self _presentModalViewControllerFromDownloadsButton:controller];
	} else {
		[self willHideBrowserPanel:controller];
		[self _forceDismissModalViewController:animate]; // 3.2+
	}
}

%new(v@:@@)
- (void)_presentModalViewController:(id)viewController fromButton:(UIView *)button {
	if(SDM$WildCat) {
		id rpc = [[%c(RotatablePopoverController) alloc] initWithContentViewController:viewController];
		[rpc setPresentationRect:[button frame]];
		[rpc setPresentationView:[self buttonBar]];
		[rpc setPermittedArrowDirections:1];
		[rpc setPassthroughViews:[NSArray arrayWithObject:[self buttonBar]]];
		[rpc presentPopoverAnimated:NO];
		[self setCurrentPopoverController:rpc];
		[rpc release];
	} else {
		if(SDMSystemVersionLT(_SDM_iOS_5_0))
			[[self _modalViewController] presentModalViewController:viewController animated:YES];
		else
			[MSHookIvar<UIViewController *>(self, "_rootViewController") presentModalViewController:viewController animated:YES];
	}
}

%group Firmware_lt_50
%new(v@:@)
- (void)_presentModalViewControllerFromDownloadsButton:(id)x {
	[self _presentModalViewController:x fromButton:objc_getAssociatedObject(self, kSDMAssociatedPortraitDownloadButton)];
}
%end

%group Firmware_ge_50
%new(v@:@)
- (void)_presentModalViewControllerFromDownloadsButton:(id)x {
	UIView *view = objc_getAssociatedObject(self, kSDMAssociatedPresentationViewKey);
	[self _presentModalViewController:x fromButton:view];
	objc_setAssociatedObject(self, kSDMAssociatedPresentationViewKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%end

%group iPadHooks_Firmware_lt_50
- (void)_presentModalViewControllerFromActionButton:(id)x {
	[self _presentModalViewController:x fromButton:objc_getAssociatedObject(self, kSDMAssociatedActionButton)];
}

- (void)_presentModalViewControllerFromBookmarksButton:(id)x {
	[self _presentModalViewController:x fromButton:objc_getAssociatedObject(self, kSDMAssociatedBookmarksButton)];
}

- (void)popupAlert:(UIActionSheet *)alert {
	[alert presentFromRect:[objc_getAssociatedObject(self, kSDMAssociatedActionButton) frame] inView:[self buttonBar] direction:1 allowInteractionWithViews:[NSArray arrayWithObjects:[self buttonBar], nil] backgroundStyle:0 animated:YES];
}
%end

- (BOOL)showBrowserPanelType:(int)arg1 {
	%log;
	if(arg1 == 5 && [[self browserPanel] panelType] == SDPanelTypeDownloadManager) {
		[self hideBrowserPanelType:SDPanelTypeDownloadManager];
	}
	BOOL x = %orig;
	return x;
}

- (BOOL)hideBrowserPanelType:(int)arg1 {
	%log;
	if(arg1 == SDPanelTypeDownloadManager) {
		[self _setShowingDownloads:NO animate:YES];
		return YES;
	}
	BOOL x = %orig;
	NSLog(@"------- hideBrowserPanelType: %d", arg1);
	return x;
}

%group Firmware_lt_32
%new(v@:i) // Missing on < 4.0
- (void)_forceDismissModalViewController:(BOOL)animated {
  [self _forceDismissModalViewController];
}
%end

%group Firmware_ge_32
%new(@@:)
- (id)browserLayer {
	return MSHookIvar<id>(self, "_transitionView");
}
%end
%end

%group Firmware_lt_50
%hook Application
- (void)applicationWillSuspend {
	BrowserController *sbc = [%c(BrowserController) sharedBrowserController];
	if([[sbc browserPanel] panelType] == SDPanelTypeDownloadManager) {
		[sbc hideBrowserPanelType:SDPanelTypeDownloadManager];
		[sbc _setShowingDownloads:NO animate:YES];
	}
	%orig;
}
%end
%end

void _init_browserPanel() {
	%init;
	if(SDMSystemVersionLT(_SDM_iOS_3_2))
		%init(Firmware_lt_32);
	else
		%init(Firmware_ge_32);

	if(SDMSystemVersionLT(_SDM_iOS_5_0)) {
		%init(Firmware_lt_50);
	} else {
		%init(Firmware_ge_50);
	}

	if(SDM$WildCat) {
		if(SDMSystemVersionLT(_SDM_iOS_5_0)) {
			%init(iPadHooks_Firmware_lt_50);
		}
	}
}

// vim:filetype=logos:sw=8:ts=8:noet
