#import <objc/runtime.h>
#import "SDMCommon.h"
#import "SDMVersioning.h"

#import "Safari/BrowserController.h"
#import "Safari/Application.h"
#import "SDDownloadManager.h"
#import "UIKitExtra/UIToolbarButton.h"

NSString * const kSDMAssociatedPortraitDownloadButton = @"kSDMAssociatedPortraitDownloadButton";
NSString * const kSDMAssociatedActionButton = @"kSDMAssociatedActionButton";
NSString * const kSDMAssociatedBookmarksButton = @"kSDMAssociatedBookmarksButton";

@interface BrowserController (SDMAdditions)
- (void)toggleDownloadManagerFromButtonBar;
@end

@interface BrowserButtonBar (Private)
- (NSArray *)buttonItems;
- (void)setButtonItems:(NSArray *)buttonItems;
- (void)registerButtonGroup:(int)group withButtons:(int *)buttons withCount:(int)count;
- (void)showButtonGroup:(int)group withDuration:(NSTimeInterval)duration;
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
	BrowserController *bcont = [SDM$BrowserController sharedBrowserController];
	BrowserButtonBar *buttonBar = MSHookIvar<BrowserButtonBar *>(bcont, "_buttonBar");
	CFMutableDictionaryRef _groups = MSHookIvar<CFMutableDictionaryRef>(buttonBar, "_groups");
	int cg = MSHookIvar<int>(buttonBar, "_currentButtonGroup");
	NSArray *_buttonItems = [buttonBar buttonItems];
	
	NSMutableArray *mutButtonItems = [_buttonItems mutableCopy];

	id x = [%c(BrowserButtonBar) imageButtonItemWithName:portraitIconFilename()
						     tag:61
						  action:@selector(toggleDownloadManagerFromButtonBar)
						  target:[NSValue valueWithNonretainedObject:[SDM$BrowserController sharedBrowserController]]];

	[mutButtonItems addObject:x];
	CFDictionaryRemoveValue(_groups, (void*)1);

	if(!SDM$WildCat) {
		// Landscape (non-iPad)
		id y = [%c(BrowserButtonBar) imageButtonItemWithName:landscapeIconFilename()
							     tag:62
							  action:@selector(toggleDownloadManagerFromButtonBar)
							  target:[NSValue valueWithNonretainedObject:[SDM$BrowserController sharedBrowserController]]];
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
		float newXOrigin = floorf(maxX - (buttonBoxWidth / 2.0) - (curWidth / 2.0));
		[button setFrame:CGRectMake(newXOrigin, YOrigin, curWidth, curHeight)];

		int tag = button.tag;
		if(tag == 61)
			objc_setAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedPortraitDownloadButton, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		else if(tag == 1)
			objc_setAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedBookmarksButton, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		else if(tag == 15)
			objc_setAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedActionButton, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		curButton++;
	}
	return;
}
%end

void _init_customToolbar_legacy() {
	%init;
}

// vim:filetype=logos:ts=8:sw=8:noet
