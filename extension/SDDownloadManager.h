//
//  DownloadManager.h
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebUI/WebUIAuthenticationManager.h>
#import "Safari/BrowserButtonBar.h"
#import "WebPolicyDelegate.h"
#import "UIKitExtra/UIToolbarButton.h"
#import "SDDownloadActionSheet.h"

#import "SDDownloadPromptViewController.h"
#import "SDFileBrowserNavigationController.h"

@interface WebView : NSObject 
+ (BOOL)canShowMIMEType:(NSString*)type;
@end

@class BrowserButtonBar;
@class SDDownloadModel;

@interface SDDownloadManager : UIViewController <SDSafariDownloadDelegate, UIAlertViewDelegate, SDDownloadPromptDelegate, SDFileBrowserDelegate> {
	NSOperationQueue *_downloadQueue;
	BOOL _visible;
	SDDownloadModel *_model;
	NSObject<SDSafariDownloadDelegate> *_downloadObserver;
	id _authenticationManager;
}
@property (nonatomic, readonly, retain) SDDownloadModel *dataModel;
@property (nonatomic, assign) NSObject<SDSafariDownloadDelegate> *downloadObserver;
@property (nonatomic, retain) WebUIAuthenticationManager *authenticationManager;

+ (id)uniqueFilenameForFilename:(NSString *)filename atPath:(NSString *)path;

+ (id)sharedManager;
- (BOOL)supportedRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType;

- (NSString*)fileNameForURL:(NSURL*)url;
- (BOOL) webView:(WebView *)webView 
            decideAction:(NSDictionary*)action
              forRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType 
                 inFrame:(WebFrame *)frame
            withListener:(id<WebPolicyDecisionListener>)listener
		 context:(id)context;

- (SDDownloadRequest *)downloadRequestForImmediateURLRequest:(NSURLRequest *)request context:(id)context;
- (void)addDownloadFromDownloadRequest:(SDDownloadRequest *)downloadRequest;
- (BOOL)cancelDownload:(SDSafariDownload *)download;
- (void)retryDownload:(SDSafariDownload *)download;
- (void)deleteDownload:(SDSafariDownload *)download;
- (void)cancelAllDownloads;

- (int)downloadsRunning;
@end
