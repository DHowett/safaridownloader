#import "SDMVersioning.h"
#import "SDMCommonClasses.h"
#import "DownloadManager.h"

#import "UIKitExtra/UIWebDocumentView.h"
#import "UIKitExtra/UIWebViewWebViewDelegate.h"

@interface UIActionSheet (SDMPrivate)
- (NSMutableArray *)buttons;
@end

/* {{{ struct interaction on 3.2+ */
struct interaction32 {
	NSTimer *timer;
	struct CGPoint location;
	char isBlocked;
	char isCancelled;
	char isOnWebThread;
	char isDisplayingHighlight;
	char attemptedClick;
	struct CGPoint lastPanTranslation;
	DOMNode *element;
	char defersCallbacksState;
	UIInformalDelegate *delegate;
	int interactionSheetType;
	UIActionSheet *interactionSheet;
	char allowsImageSheet;
	char allowsDataDetectorsSheet;
} _interaction32;
/* }}} */

/* {{{ struct interaction on < 3.2 */
struct interactionnot32 {
	NSTimer* timer;
	CGPoint location;
	BOOL isBlocked;
	BOOL isCancelled;
	BOOL isOnWebThread;
	BOOL isDisplayingHighlight;
	BOOL attemptedClick;
	BOOL isGestureScrolling;
	CGPoint gestureScrollPoint;
	CGPoint gestureCurrentPoint;
	BOOL hasAttemptedGestureScrolling;
	UIView* candidate;
	BOOL forwardingGuard;
	SEL mouseUpForwarder;
	SEL mouseDraggedForwarder;
	DOMNode *element;
	BOOL defersCallbacksState;
	UIInformalDelegate* delegate;
	int interactionSheetType;
	UIActionSheet* interactionSheet;
	BOOL allowsImageSheet;
	BOOL allowsDataDetectorsSheet;
	struct {
		BOOL active;
		BOOL defaultPrevented;
		NSMutableArray* regions;
	} directEvents;
};
/* }}} */

static NSURL *interactionURL = nil;

@interface DOMNode : NSObject
-(DOMNode*)parentNode;
-(NSURL*)absoluteLinkURL;
-(NSURL*)absoluteImageURL;
@end

%hook UIWebDocumentView
- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(int)index {
	if(index == 1336) {
		if(interactionURL)
			[[SDDownloadManager sharedManager] addDownloadWithURL:interactionURL browser:YES];
	}
	%orig;
	[interactionURL release];
	interactionURL = nil;
}

static void showBrowserSheetHookInternals(UIWebDocumentView *self, UIActionSheet *sheet, DOMNode *&domElement) {
	NSLog(@"DOM Element is %@", domElement);
	NSMutableArray *buttons = [sheet buttons];
	NSString *downloadThing = @"";
	id myButton;

	DOMNode *anchorNode = domElement;
	while(anchorNode && ![anchorNode isKindOfClass:%c(DOMHTMLAnchorElement)]) {
		NSLog(@"not htmlanchorelement oh no %@", anchorNode);
		anchorNode = [anchorNode parentNode];
	}

	if(anchorNode) {
		NSLog(@"100%% certainty that this is an anchor node. %@", anchorNode);
		domElement = anchorNode;
	} else {
		NSLog(@"There's definitely not an anchor node here.");
	}

	if([domElement isKindOfClass:%c(DOMHTMLAnchorElement)]) {
		NSLog(@"htmlanchorelement yay %@", domElement);
		interactionURL = [[domElement absoluteLinkURL] copy];
		downloadThing = @"Target";
	} else if([domElement isKindOfClass:%c(DOMHTMLImageElement)]) {
		NSLog(@"htmlimageelement yay %@", domElement);
		interactionURL = [[domElement absoluteImageURL] copy];
		downloadThing = @"Image";
	} else {
		interactionURL = nil;
	}

	if(interactionURL) {
		NSString *scheme = [interactionURL scheme];
		NSLog(@"url is %@", interactionURL);
		if([scheme isEqualToString:@"http"]
		|| [scheme isEqualToString:@"https"]
		|| [scheme isEqualToString:@"ftp"]) {
			[sheet addButtonWithTitle:[NSString stringWithFormat:@"Download %@...", downloadThing]];
			myButton = [buttons lastObject];
			[myButton retain];
			[myButton setTag:1337];
			[buttons removeObject:myButton];
			[buttons insertObject:myButton atIndex:0];
			[myButton release];
			[sheet setDestructiveButtonIndex:0];
			[sheet setCancelButtonIndex:([buttons count] - 1)];
		} else {
			[interactionURL release];
			interactionURL = nil;
		}
	}
}

%group Firmware_ge_32
- (void)showBrowserSheet:(id)sheet atPoint:(CGPoint)p {
	%log;
	struct interaction32 i = MSHookIvar<struct interaction32>(self, "_interaction");
	showBrowserSheetHookInternals(self, sheet, i.element);
	%orig;
}
%end

%group Firmware_lt_32
- (void)showBrowserSheet:(id)sheet {
	%log;
	struct interactionnot32 i = MSHookIvar<struct interactionnot32>(self, "_interaction");
	showBrowserSheetHookInternals(self, sheet, i.element);
	%orig;
}
%end
%end

void _init_interaction_legacy() {
	%init;
	if(SDMSystemVersionLT(_SDM_iOS_3_2))
		%init(Firmware_lt_32);
	else
		%init(Firmware_ge_32);
}
// vim:filetype=logos:ts=8:sw=8:noexpandtab
