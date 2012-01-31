#import <objc/runtime.h>
#import "Safari/BrowserController.h"
#import "Safari/Application.h"
#import "DownloadManager.h"
#import "UIKitExtra/UIToolbarButton.h"

#import "SDMVersioning.h"
#import "SDMCommonClasses.h"

static UIToolbarButton *_actionButton;
static UIToolbarButton *_bookmarksButton;

@interface BrowserController (SDMAdditions)
- (void)toggleDownloadManagerFromButtonBar;
@end

static NSString *portraitIconFilename(void) {
	NSString *name = @"Download";
	if(SDM$WildCat) return @"DownloadT.png";
	return SDMSystemVersionGE(_SDM_iOS_4_0) ? name : [name stringByAppendingString:@".png"];
}

static NSString *landscapeIconFilename(void) {
	NSString *name = @"DownloadSmall";
	return SDMSystemVersionGE(_SDM_iOS_4_0) ? name : [name stringByAppendingString:@".png"];
}

static void initCustomToolbar(void) {
	Class BrowserController = objc_getClass("BrowserController");
	Class BrowserButtonBar = objc_getClass("BrowserButtonBar");
	BrowserController *bcont = [BrowserController sharedBrowserController];
	BrowserButtonBar *buttonBar = MSHookIvar<BrowserButtonBar *>(bcont, "_buttonBar");
	CFMutableDictionaryRef _groups = MSHookIvar<CFMutableDictionaryRef>(buttonBar, "_groups");
	int cg = MSHookIvar<int>(buttonBar, "_currentButtonGroup");
	NSArray *_buttonItems = [buttonBar buttonItems];
	
	NSMutableArray *mutButtonItems = [_buttonItems mutableCopy];

	id x = [BrowserButtonBar imageButtonItemWithName:portraitIconFilename()
						     tag:61
						  action:@selector(toggleDownloadManagerFromButtonBar)
						  target:[NSValue valueWithNonretainedObject:[%c(BrowserController) sharedBrowserController]]];

	[mutButtonItems addObject:x];
	CFDictionaryRemoveValue(_groups, (void*)1);

	if(!SDM$WildCat) {
		// Landscape (non-iPad)
		id y = [BrowserButtonBar imageButtonItemWithName:landscapeIconFilename()
							     tag:62
							  action:@selector(toggleDownloadManagerFromButtonBar)
							  target:[NSValue valueWithNonretainedObject:[%c(BrowserController) sharedBrowserController]]];
		[mutButtonItems addObject:y];
		CFDictionaryRemoveValue(_groups, (void*)2);
	}

	
	[buttonBar setButtonItems:mutButtonItems];
	[mutButtonItems release];
	
	int portraitGroup[]  = {5, 7, 15, 1, 61, 3};
	int landscapeGroup[] = {6, 8, 16, 2, 62, 4};

	if(SDM$WildCat) { // The iPad has a different button order than the iPhone.
		portraitGroup[0] = 5;
		portraitGroup[1] = 7;
		portraitGroup[2] = 3;
		portraitGroup[3] = 1;
		portraitGroup[4] = 15;
		portraitGroup[5] = 61;
	}
	
	[buttonBar registerButtonGroup:1 
			   withButtons:portraitGroup 
			     withCount:6];
	if(!SDM$WildCat) {
		[buttonBar registerButtonGroup:2 
				   withButtons:landscapeGroup 
				     withCount:6];
	}
	
	if (cg == 1 || cg == 2)
		[buttonBar showButtonGroup:cg
			      withDuration:0];
}

%hook Application
- (void)applicationDidFinishLaunching:(UIApplication *)application {
	%orig;
	initCustomToolbar();
}
%end

%hook BrowserButtonBar
- (void)positionButtons:(NSArray *)buttons tags:(int *)tags count:(int)count group:(int)group {
	%orig;

	if(group != 1 && group != 2) {
		return;
	}

	NSLog(@"Button array: %@", [buttons description]);
	float maxWidth = self.frame.size.width;
	float buttonBoxWidth = floorf(maxWidth / count);
	if((int)buttonBoxWidth % 2 == 1) buttonBoxWidth -= 1.0f;
	float curX = 0;
	float maxX = buttonBoxWidth;
	int curButton = 0;
	float YOrigin = SDM$WildCat ? 10 : 2;
	for(UIToolbarButton *button in buttons) {
		curX = curButton * buttonBoxWidth;
		maxX = curX + buttonBoxWidth;
		float curWidth = button.frame.size.width;
		float curHeight = button.frame.size.height;
		float newXOrigin = maxX - (buttonBoxWidth / 2.0) - (curWidth / 2.0);
		[button setFrame:CGRectMake(newXOrigin, YOrigin, curWidth, curHeight)];

		int tag = button.tag;
		if(tag == 61)
			[[SDDownloadManager sharedManager] setPortraitDownloadButton:button];
		else if(tag == 62)
			[[SDDownloadManager sharedManager] setLandscapeDownloadButton:button];
		else if(tag == 1)
			_bookmarksButton = button;
		else if(tag == 15)
			_actionButton = button;

		curButton++;
	}
	return;
}
%end

void _init_customToolbar_legacy() {
	%init;
}

// vim:filetype=logos:ts=8:sw=8:noet
