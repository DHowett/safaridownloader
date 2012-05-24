#import "Safari/RotatablePopoverController.h"

#import <objc/runtime.h>
#import "SDMCommon.h"
#import "SDResources.h"

#import "Safari/BrowserController.h"
#import "UIKitExtra/UIToolbarButton.h"

%hook SpacedBarButtonItem
- (id)init {
	if((self = %orig) != nil) {
		UIBarButtonItem *&_precedingFixedSpace = MSHookIvar<UIBarButtonItem *>(self, "_precedingFixedSpace");
		[_precedingFixedSpace release];
		_precedingFixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	} return self;
}

%new(v@:)
- (void)destroyPrecedingSpace {
	UIBarButtonItem *&_precedingFixedSpace = MSHookIvar<UIBarButtonItem *>(self, "_precedingFixedSpace");
	[_precedingFixedSpace release];
	_precedingFixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	[_precedingFixedSpace setWidth:0.f];
}
%end

//@interface SpacedBarButtonItem (SDM)
//- (void)destroyPrecedingSpace;
//@end

%hook BrowserToolbar
const NSString *const kSDMAssociatedDownloadButtonKey = @"kSDMAssociatedDownloadButtonKey";
- (NSMutableArray *)_defaultSpacedItems {
	NSMutableArray *orig = [%orig mutableCopy];
	SpacedBarButtonItem *_tabExposeItem = MSHookIvar<SpacedBarButtonItem *>(self, "_tabExposeItem");

	UIBarButtonItem *downloadButtonItem = [[%c(SpacedBarButtonItem) alloc] init];
	downloadButtonItem.image = [SDResources imageNamed:@"DownloadButton"];
	downloadButtonItem.landscapeImagePhone = [SDResources imageNamed:@"DownloadButtonSmall"];
	downloadButtonItem.style = UIBarButtonItemStylePlain;
	downloadButtonItem.target = [SDM$BrowserController sharedBrowserController];
	downloadButtonItem.action = @selector(toggleDownloadManagerFromButtonBar);
	objc_setAssociatedObject(self, kSDMAssociatedDownloadButtonKey, downloadButtonItem, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	if(SDM$WildCat)
		[orig addObject:downloadButtonItem];
	else
		[orig insertObject:downloadButtonItem atIndex:[orig indexOfObjectIdenticalTo:_tabExposeItem]];
	[downloadButtonItem release];
	[[orig objectAtIndex:0] destroyPrecedingSpace];
	return [orig autorelease];
}

// Make this non-operational.
- (void)_updateFixedSpacing {
	return;
}
%end

%group iPadHooks
%hook BrowserButtonBar
- (void)setFrame:(CGRect)frame {
  %orig(CGRectMake(frame.origin.x, frame.origin.y, frame.size.width+24, frame.size.height));
}
%end
%hook AddressView
- (CGRect)_fieldRect {
  CGRect frame = %orig;
  return CGRectMake(frame.origin.x+24, frame.origin.y, frame.size.width-24, frame.size.height);
}
%end
%end

void _init_customToolbar() {
	%init;
	if(SDM$WildCat) {
		%init(iPadHooks);
	}
}

// vim:filetype=logos:sw=8:ts=8:noet
