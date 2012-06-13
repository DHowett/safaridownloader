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
#import "FileBrowser.h"
#import "SDDownloadActionSheet.h"

#import "SDDownloadPromptViewController.h"

@interface WebView : NSObject 
+ (BOOL)canShowMIMEType:(NSString*)type;
@end

@class BrowserButtonBar;
@class SDDownloadModel;

@interface SDDownloadManager : UIViewController <SDSafariDownloadDelegate, UIAlertViewDelegate, SDDownloadPromptDelegate> {
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

//- (BOOL)addDownloadWithInfo:(NSDictionary*)info browser:(BOOL)b;
//- (BOOL)addDownloadWithURL:(NSURL*)url browser:(BOOL)b;
//- (BOOL)addDownloadWithRequest:(NSURLRequest*)url browser:(BOOL)b;
- (BOOL)addDownloadWithRequest:(NSURLRequest*)request andMimeType:(NSString *)mimeType browser:(BOOL)b;
- (BOOL)addDownload:(SDSafariDownload *)download browser:(BOOL)b;
- (BOOL)cancelDownload:(SDSafariDownload *)download;
- (void)retryDownload:(SDSafariDownload *)download;
- (void)deleteDownload:(SDSafariDownload *)download;
- (void)cancelAllDownloads;

- (int)downloadsRunning;
@end
