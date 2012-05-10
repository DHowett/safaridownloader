/*
 * SDDownloadManagerNavigationController
 * SDM
 * Dustin Howett 2012-01-30
 */

#import "SDDownloadManagerNavigationController.h"
#import "SDMVersioning.h"
#import "SDMCommonClasses.h"
#import "DownloaderCommon.h"

#import "Safari/BrowserController.h"

@implementation SDDownloadManagerNavigationController
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
	return SDM$WildCat ? YES : (orientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL)allowsRotation { return YES; }
- (BOOL)pausesPages { return NO; }
- (int)panelType { return SDPanelTypeDownloadManager; }
- (int)panelState { return 1; }
- (BOOL)shouldShowButtonBar { return SDM$WildCat ? YES : NO; }
- (BOOL)isDismissible { return NO; } // Maybe?
- (BOOL)disablesStatusBarPress { return NO; }

- (void)close {
	[[SDM$BrowserController sharedBrowserController] hideBrowserPanelType:SDPanelTypeDownloadManager];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[[SDM$BrowserController sharedBrowserController] didShowBrowserPanel:[[SDM$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[SDM$BrowserController sharedBrowserController] willShowBrowserPanel:[[SDM$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if ([[SDM$BrowserController sharedBrowserController] browserPanel] == self)
		[[SDM$BrowserController sharedBrowserController] didHideBrowserPanel:[[SDM$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if([[SDM$BrowserController sharedBrowserController] browserPanel] == self)
		[[SDM$BrowserController sharedBrowserController] closeBrowserPanel:[[SDM$BrowserController sharedBrowserController] browserPanel]];
}

- (void)didHideBrowserPanel {
	if(SDMSystemVersionLT(_SDM_iOS_5_0))
		[[[[SDM$BrowserController sharedBrowserController] _modalViewController] view] performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0];
}

- (CGSize)contentSizeForViewInPopover {
	return CGSizeMake(320.f, 480.f);
}
@end

// vim:filetype=objc:ts=8:sw=8:noet
