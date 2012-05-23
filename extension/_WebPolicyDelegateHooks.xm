#import <substrate.h>
#import "SDMCommonClasses.h"
#import "DownloaderCommon.h"
#import "SDDownloadManager.h"

//#import "Safari/BrowserController.h"
//#import "Safari/PageLoad.h"
#import "Safari/TabDocument.h"
#import "WebPolicyDelegate.h"

%hook TabDocument
               - (void)webView:(WebView *)view
decidePolicyForNewWindowAction:(NSDictionary *)action
                       request:(NSURLRequest *)request
                  newFrameName:(NSString *)newFrameName
              decisionListener:(id<WebPolicyDecisionListener>)decisionListener {
	%log;
	SDDownloadManager* downloader = [SDDownloadManager sharedManager];

	BOOL load = [downloader webView:view decideAction:action forRequest:request withMimeType:nil inFrame:nil withListener:decisionListener context:self];

	if(load) {
		NSLog(@"WDW: not handled");
		%orig;
	} else {
		NSLog(@"WDW: handled");
		[decisionListener ignore];
		[self _setLoading:NO withError:nil];
	}
	NSLog(@"#####################################################");
}

                - (void)webView:(WebView *)view
decidePolicyForNavigationAction:(NSDictionary *)action
                        request:(NSURLRequest *)request
                          frame:(WebFrame *)frame
               decisionListener:(id<WebPolicyDecisionListener>)decisionListener {
	%log;

	SDDownloadManager* downloader = [SDDownloadManager sharedManager];

	BOOL load = [downloader webView:view decideAction:action forRequest:request withMimeType:nil inFrame:frame withListener:decisionListener context:self];

	if(load) {
		NSLog(@"NAV: not handled");
		%orig;
	} else {
		NSLog(@"NAV: handled");
		[decisionListener ignore];
		[self _setLoading:NO withError:nil];
	}
	NSLog(@"#####################################################");
}

        - (void)webView:(WebView *)view
decidePolicyForMIMEType:(NSString *)type
                request:(NSURLRequest *)request
                  frame:(WebFrame *)frame
       decisionListener:(id<WebPolicyDecisionListener>)decisionListener {
	%log;

	SDDownloadManager* downloader = [SDDownloadManager sharedManager];

	BOOL load = [downloader webView:view decideAction:nil forRequest:request withMimeType:type inFrame:frame withListener:decisionListener context:self];

	if(load) {
		NSLog(@"MIME: not handled");
		%orig;
	} else {
		NSLog(@"MIME: handled");
		[decisionListener ignore];
		[self _setLoading:NO withError:nil];
	}
	NSLog(@"#####################################################");
}
%end

void _init_webPolicyDelegate() {
	%init;
}

// vim:filetype=logos:sw=8:ts=8:noet
