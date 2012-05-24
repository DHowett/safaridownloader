#import "SDMCommon.h"
#import "SDMVersioning.h"

#import "UIKitExtra/UIWebDocumentView.h"
#import "UIKitExtra/UIWebViewWebViewDelegate.h"
#import "UIWebElementAction.h"

#import "SDResources.h"
#import "SDDownloadManager.h"

@interface DOMNode: NSObject
- (DOMNode *)parentNode;
- (NSURL *)absoluteImageURL;
@end

%hook BrowserController
- (NSMutableArray *)_actionsForElement:(DOMNode *)domElement withTargetURL:(NSURL *)url suggestedActions:(NSArray *)suggestedActions {
	NSMutableArray *actions = %orig;
	DOMNode *anchorNode = domElement;
	while(anchorNode && ![anchorNode isKindOfClass:%c(DOMHTMLAnchorElement)]) {
		anchorNode = [anchorNode parentNode];
	}

	if(anchorNode) {
		domElement = anchorNode;
	}

	NSMutableArray *downloadActions = [NSMutableArray array];
	if(url) {
		NSString *scheme = [url scheme];
		if([scheme hasPrefix:@"http"]
		|| [scheme isEqualToString:@"ftp"]) {
			[downloadActions addObject:[%c(UIWebElementAction) customElementActionWithTitle:SDLocalizedString(@"DOWNLOAD_TARGET") actionHandler:^{
				NSURLRequest *request = [NSURLRequest requestWithURL:url];
				[[SDDownloadManager sharedManager] addDownloadWithRequest:request andMimeType:nil browser:YES];
			}]];
		}
	}
	if([domElement isKindOfClass:%c(DOMHTMLImageElement)]) {
		[downloadActions addObject:[%c(UIWebElementAction) customElementActionWithTitle:SDLocalizedString(@"DOWNLOAD_IMAGE") actionHandler:^{
			NSURL *url = [domElement absoluteImageURL];
			NSURLRequest *request = [NSURLRequest requestWithURL:url];
			[[SDDownloadManager sharedManager] addDownloadWithRequest:request andMimeType:nil browser:YES];
		}]];
	}

	[actions insertObjects:downloadActions atIndexes:[NSIndexSet indexSetWithIndexesInRange:(NSRange){0, downloadActions.count}]];
	return actions;
}
%end

void _init_interaction() {
	%init;
}
