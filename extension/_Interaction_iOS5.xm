#import "SDMCommon.h"
#import "SDMVersioning.h"

#import "UIKitExtra/UIWebDocumentView.h"
#import "UIKitExtra/UIWebViewWebViewDelegate.h"
#import "UIWebElementAction.h"

#import "SDResources.h"
#import "SDDownloadManager.h"

#import "Safari/BrowserController.h"
#import "Safari/TabController.h"

@interface DOMNode: NSObject
- (DOMNode *)parentNode;
- (NSURL *)absoluteImageURL;
@end

%hook BrowserController
- (NSMutableArray *)_actionsForElement:(DOMNode *)domElement withTargetURL:(NSURL *)url suggestedActions:(NSArray *)suggestedActions {
	NSMutableArray *actions = %orig;

	NSMutableArray *downloadActions = [NSMutableArray array];
	if(url) {
		NSString *scheme = [url scheme];
		if([scheme hasPrefix:@"http"]
		|| [scheme isEqualToString:@"ftp"]) {
			[downloadActions addObject:[%c(UIWebElementAction) customElementActionWithTitle:SDLocalizedString(@"DOWNLOAD_TARGET") actionHandler:^{
				NSURLRequest *request = [NSURLRequest requestWithURL:url];
				[[SDDownloadManager sharedManager] downloadRequestForImmediateURLRequest:request context:[[self tabController] activeTabDocument]];
				[self showBrowserPanelType:SDPanelTypeFileBrowser];
			}]];
		}
	}
	if([domElement isKindOfClass:%c(DOMHTMLImageElement)]) {
		[downloadActions addObject:[%c(UIWebElementAction) customElementActionWithTitle:SDLocalizedString(@"DOWNLOAD_IMAGE") actionHandler:^{
			NSURL *url = [domElement absoluteImageURL];
			NSURLRequest *request = [NSURLRequest requestWithURL:url];
			[[SDDownloadManager sharedManager] downloadRequestForImmediateURLRequest:request context:[[self tabController] activeTabDocument]];
			[self showBrowserPanelType:SDPanelTypeFileBrowser];
		}]];
	}

	[actions insertObjects:downloadActions atIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){0, downloadActions.count}]];
	return actions;
}
%end

void _init_interaction() {
	%init;
}
