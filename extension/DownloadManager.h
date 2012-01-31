//
//  DownloadManager.h
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SafariDownload.h"
#import "Safari/BrowserButtonBar.h"
#import "WebPolicyDelegate.h"
#import "UIKitExtra/UIToolbarButton.h"
#import "FileBrowser.h"
#import "SDDownloadActionSheet.h"

@interface WebView : NSObject 
+ (BOOL)canShowMIMEType:(NSString*)type;
@end

@class BrowserButtonBar;

@interface SDFileBrowserPanel : NSObject <BrowserPanel>
@end

typedef enum
{
  SDActionTypeNone = 0,
  SDActionTypeView = 1,
  SDActionTypeDownload = 2,
  SDActionTypeCancel = 3,
  SDActionTypeDownloadAs = 4,
} SDActionType;

@interface SDDownloadManager : UIViewController <SDSafariDownloadDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate, SDDownloadActionSheetDelegate, SDDownloadPromptViewDelegate> {
  UITableView*			  _tableView;
  NSMutableArray*		  _currentDownloads;
  NSMutableArray*		  _finishedDownloads;
  NSOperationQueue*	  _downloadQueue;
  UIToolbarButton*	  _portraitDownloadButton;
  UIToolbarButton*	  _landscapeDownloadButton;
  NSDictionary			  *_userPrefs;
  BOOL					  _visible;
  NSURL					  *_loadingURL;
  NSIndexPath *_currentSelectedIndexPath;
}

@property (nonatomic, assign) UIToolbarButton*  portraitDownloadButton;
@property (nonatomic, assign) UIToolbarButton*  landscapeDownloadButton;

@property (nonatomic, retain) NSDictionary*	userPrefs;

@property (nonatomic, assign, getter=isVisible) BOOL visible;
@property (nonatomic, retain) NSURL *loadingURL;

@property (nonatomic, retain) NSIndexPath *currentSelectedIndexPath;

+ (id)uniqueFilenameForFilename:(NSString *)filename atPath:(NSString *)path;

+ (id)sharedManager;
- (void)updateUserPreferences;
- (void)updateFileTypes;
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

- (BOOL)addDownloadWithInfo:(NSDictionary*)info browser:(BOOL)b;
- (BOOL)addDownloadWithURL:(NSURL*)url browser:(BOOL)b;
- (BOOL)addDownloadWithRequest:(NSURLRequest*)url browser:(BOOL)b;
- (BOOL)addDownloadWithRequest:(NSURLRequest*)request andMimeType:(NSString *)mimeType browser:(BOOL)b;
- (BOOL)addDownload:(SDSafariDownload *)download browser:(BOOL)b;
- (BOOL)cancelDownload:(SDSafariDownload *)download;
- (BOOL)cancelDownloadWithURL:(NSURL *)url;
- (IBAction)cancelAllDownloads;

- (void)updateBadges;
- (int)downloadsRunning;
@end
