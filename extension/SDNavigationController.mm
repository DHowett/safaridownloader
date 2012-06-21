/*
 * SDNavigationController
 * SDM
 * Dustin Howett 2012-01-30
 */

#import "SDMCommon.h"
#import "SDMVersioning.h"
#import "SDNavigationController.h"

#import "Safari/BrowserController.h"

@protocol SDNavigationControllerSubPanel
- (int)panelType;
@end

@implementation SDNavigationController
@synthesize standalone = _standalone;
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
	return SDM$WildCat ? YES : (orientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (UIViewController<SDNavigationControllerSubPanel> *)rootViewController {
	return [self.viewControllers objectAtIndex:0];
}

- (BOOL)allowsRotation { return YES; }
- (BOOL)pausesPages { return NO; }
- (int)panelType { return [[self rootViewController] panelType]; }
- (int)panelState { return 1; }
- (BOOL)shouldShowButtonBar { return SDM$WildCat ? YES : NO; }
- (BOOL)isDismissible { return NO; } // Maybe?
- (BOOL)disablesStatusBarPress { return NO; }

- (void)close {
	[[SDM$BrowserController sharedBrowserController] hideBrowserPanelType:[self panelType]];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if(!_standalone)
		[[SDM$BrowserController sharedBrowserController] didShowBrowserPanel:[[SDM$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if(!_standalone)
		[[SDM$BrowserController sharedBrowserController] willShowBrowserPanel:[[SDM$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	if(!_standalone)
		if ([[SDM$BrowserController sharedBrowserController] browserPanel] == self)
			[[SDM$BrowserController sharedBrowserController] didHideBrowserPanel:[[SDM$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if(!_standalone)
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

- (UIModalPresentationStyle)modalPresentationStyle {
	return [[self rootViewController] modalPresentationStyle];
}
@end

// vim:filetype=objc:ts=8:sw=8:noet
