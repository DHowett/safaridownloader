#import "Safari/RotatablePopoverController.h"

#import <objc/runtime.h>
#import "SDMCommonClasses.h"
#import "SDResources.h"

#import "Safari/BrowserController.h"
#import "UIKitExtra/UIToolbarButton.h"

%hook UIView
%new(@@:)
- (id)sdButtonItem { return objc_getAssociatedObject(self, @"xxx"); }
%new(v@:@)
- (void)setSdButtonItem:(id)item { objc_setAssociatedObject(self, @"xxx", item, OBJC_ASSOCIATION_ASSIGN); }
%end
%hook UIBarButtonItem
- (void)_updateView {
	%orig;
	NSLog(@"setting on update view...");
	[MSHookIvar<UIView *>(self, "_view") setSdButtonItem:self];
}
%end

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

- (void)_updateFixedSpacing {
	return;
	%orig;
	SpacedBarButtonItem *_backItem = MSHookIvar<SpacedBarButtonItem *>(self, "_backItem");
	SpacedBarButtonItem *_forwardItem = MSHookIvar<SpacedBarButtonItem *>(self, "_forwardItem");
	SpacedBarButtonItem *_actionItem = MSHookIvar<SpacedBarButtonItem *>(self, "_actionItem");
	SpacedBarButtonItem *_bookmarksItem = MSHookIvar<SpacedBarButtonItem *>(self, "_bookmarksItem");
	SpacedBarButtonItem *_tabExposeItem = MSHookIvar<SpacedBarButtonItem *>(self, "_tabExposeItem");
	UIBarButtonItem *_downloadButtonItem = objc_getAssociatedObject(self, kSDMAssociatedDownloadButtonKey);
	NSArray *buttons = [NSArray arrayWithObjects:_backItem, _forwardItem, _actionItem, _bookmarksItem, _downloadButtonItem, _tabExposeItem, nil];
	for(SpacedBarButtonItem *i in buttons) {
		UIView *buttonImageView = MSHookIvar<UIView *>(i, "_view");
		NSLog(@"setting on view %@", buttonImageView);
		[buttonImageView setSdButtonItem:i];
	}
	return;

	CGFloat maxWidth = [self bounds].size.width;
	CGFloat cellWidth = maxWidth / buttons.count;
	CGFloat lastRightSlack = 0.f;

	for(SpacedBarButtonItem *i in buttons) {
		//UIView *buttonImageView = MSHookIvar<UIView *>(i, "_view");
		//CGFloat remainingWidth = cellWidth - buttonImageView.bounds.size.width;
		//NSLog(@"remaining width is %f of cell %f and image %f", remainingWidth, cellWidth, buttonImageView.bounds.size.width);
		//NSLog(@"preceding space has to be %f (last righthand slack is %f)", remainingWidth/2.f + lastRightSlack, lastRightSlack);
		//[[i precedingFixedSpace] setWidth:remainingWidth/2.f + lastRightSlack];
		[[i precedingFixedSpace] setWidth:0];
		//lastRightSlack = remainingWidth/2.f;
		//NSLog(@"Width of space for %@ is %f", i, [[i precedingFixedSpace] width]);
	}
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
