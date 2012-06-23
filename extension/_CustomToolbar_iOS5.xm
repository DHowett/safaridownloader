#import "Safari/RotatablePopoverController.h"

#import <objc/runtime.h>
#import "SDMCommon.h"
#import "SDResources.h"

#import "Safari/BrowserController.h"
#import "UIKitExtra/UIToolbarButton.h"
#import "SDDownloadButtonItem.h"

@interface BrowserToolbar: UIToolbar
- (SDDownloadButtonItem *)_downloadButtonItem;
@end

@interface BrowserController (SDMAdditions)
- (void)toggleDownloadManagerFromButtonBar;
- (BrowserToolbar *)buttonBar;
@end

@interface UIBarButtonItem (SDMPrivate)
- (UIToolbarButton *)view;
@end

%subclass SDDownloadButtonItem: SpacedBarButtonItem
static NSString * const kSDDownloadButtonItemAssociatedBadgeKey = @"kSDDownloadButtonItemAssociatedBadgeKey";
%new(v@:@)
- (void)setBadge:(NSString *)badge {
	objc_setAssociatedObject(self, kSDDownloadButtonItemAssociatedBadgeKey, badge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[(UIToolbarButton *)[self view] _setBadgeValue:badge];
}

%new(@@:)
- (NSString *)badge {
	return objc_getAssociatedObject(self, kSDDownloadButtonItemAssociatedBadgeKey);
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

%hook BrowserToolbar
NSString * const kSDMAssociatedPresentationViewKey = @"kSDMAssociatedPresentationViewKey";

// Private
static NSString * const kSDMAssociatedButtonDictionaryKey = @"kSDMAssociatedButtonDictionaryKey";
- (NSMutableArray *)_defaultSpacedItems {
	NSMutableArray *orig = [%orig mutableCopy];
	SpacedBarButtonItem *_tabExposeItem = MSHookIvar<SpacedBarButtonItem *>(self, "_tabExposeItem");

	UIBarButtonItem *downloadButtonItem = [[%c(SDDownloadButtonItem) alloc] init];
	downloadButtonItem.image = [SDResources imageNamed:@"DownloadButton"];
	downloadButtonItem.landscapeImagePhone = [SDResources imageNamed:@"DownloadButtonSmall"];
	downloadButtonItem.style = UIBarButtonItemStylePlain;
	downloadButtonItem.target = [SDM$BrowserController sharedBrowserController];
	downloadButtonItem.action = @selector(_downloadManagerButtonShim:);
	if(SDM$WildCat)
		[orig addObject:downloadButtonItem];
	else
		[orig insertObject:downloadButtonItem atIndex:[orig indexOfObjectIdenticalTo:_tabExposeItem]];
	[downloadButtonItem release];
	[[orig objectAtIndex:0] destroyPrecedingSpace];

	objc_setAssociatedObject(self, kSDMAssociatedButtonDictionaryKey, [NSMutableDictionary dictionary], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	return [orig autorelease];
}

// Make this non-operational.
- (void)_updateFixedSpacing {
	return;
}

%new(@@:)
- (SDDownloadButtonItem *)_downloadButtonItem {
	NSArray *items = [self items];
	NSInteger index = [items indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
		if([obj isKindOfClass:%c(SDDownloadButtonItem)]) {
			*stop = YES;
			return YES;
		}
		return NO;
	}];
	return index != NSNotFound ? [items objectAtIndex:index] : nil;
}

- (void)layoutSubviews {
	SDDownloadButtonItem *downloadButton = [self _downloadButtonItem];
	NSLog(@"Setting badge %@ on view %@", [downloadButton badge], [downloadButton view]);
	[[downloadButton view] _setBadgeValue:[downloadButton badge]];

	NSMutableDictionary *buttonDictionary = objc_getAssociatedObject(self, kSDMAssociatedButtonDictionaryKey);
	UIBarButtonItem *_backItem = MSHookIvar<UIBarButtonItem *>(self, "_backItem");
	UIBarButtonItem *_forwardItem = MSHookIvar<UIBarButtonItem *>(self, "_forwardItem");
	UIBarButtonItem *_actionItem = MSHookIvar<UIBarButtonItem *>(self, "_actionItem");
	UIBarButtonItem *_bookmarksItem = MSHookIvar<UIBarButtonItem *>(self, "_bookmarksItem");

	[buttonDictionary setObject:[_backItem view] forKey:@"_backItem"];
	[buttonDictionary setObject:[_forwardItem view] forKey:@"_forwardItem"];
	[buttonDictionary setObject:[_actionItem view] forKey:@"_actionItem"];
	[buttonDictionary setObject:[_bookmarksItem view] forKey:@"_bookmarksItem"];

	%orig;
}
%end

%hook BrowserController
%new(v@:@)
- (void)_downloadManagerButtonShim:(UIBarButtonItem *)sender {
	objc_setAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedPresentationViewKey, [(UIBarButtonItem *)sender view], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self toggleDownloadManagerFromButtonBar];
}

%new(v@:@)
- (void)_sdmUpdateBadge:(NSString *)value {
	SDDownloadButtonItem *downloadButton = [[self buttonBar] _downloadButtonItem];
	[downloadButton setBadge:value];
}
%end

%group iPadHooks
%hook BrowserToolbar
- (CGRect)actionPopoverPresentationRect {
	NSMutableDictionary *buttonDictionary = objc_getAssociatedObject(self, kSDMAssociatedButtonDictionaryKey);
	return [(UIView *)[buttonDictionary objectForKey:@"_actionItem"] frame];
}

- (CGRect)backPopoverPresentationRect {
	NSMutableDictionary *buttonDictionary = objc_getAssociatedObject(self, kSDMAssociatedButtonDictionaryKey);
	return [(UIView *)[buttonDictionary objectForKey:@"_backItem"] frame];
}

- (CGRect)bookmarksPopoverPresentationRect {
	NSMutableDictionary *buttonDictionary = objc_getAssociatedObject(self, kSDMAssociatedButtonDictionaryKey);
	return [(UIView *)[buttonDictionary objectForKey:@"_bookmarksItem"] frame];
}

- (CGRect)forwardPopoverPresentationRect {
	NSMutableDictionary *buttonDictionary = objc_getAssociatedObject(self, kSDMAssociatedButtonDictionaryKey);
	return [(UIView *)[buttonDictionary objectForKey:@"_forwardItem"] frame];
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
