//
//  DownloadManager.h
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SafariDownload.h"
#import "Safari/BrowserPanel.h"
#import "Safari/BrowserButtonBar.h"
#import "WebPolicyDelegate.h"
#import "UIKitExtra/UIToolbarButton.h"
#import "FileBrowser.h"
#import "SDDownloadActionSheet.h"

#define kProgressViewTag 238823
#define progressViewForCell(cell) ((UIProgressView*)[cell viewWithTag:kProgressViewTag])

@interface WebView : NSObject 
+ (BOOL)canShowMIMEType:(NSString*)type;
@end

@class BrowserButtonBar;
@interface BrowserButtonBar (hidden)
- (NSArray*)buttonItems;
- (void)setButtonItems:(NSArray *)its;
- (void)showButtonGroup:(int)group withDuration:(double)duration;
- (void)registerButtonGroup:(int)group withButtons:(int*)buttons withCount:(int)count;
- (id)$$createButtonWithDescription:(id)description;
@end

@interface UIActionSheet (hidden)
- (void)setMessage:(id)message;
@end

@interface SDFileBrowserPanel : NSObject <BrowserPanel>
@end

@interface SDDownloadManagerNavigationController : UINavigationController <BrowserPanel> {
	BOOL _isDismissible;
}
+ (id)sharedInstance;
- (BOOL)isDismissible;
- (void)close;
@end

typedef enum
{
  SDActionTypeNone = 0,
  SDActionTypeView = 1,
  SDActionTypeDownload = 2,
  SDActionTypeCancel = 3,
  SDActionTypeDownloadAs = 4,
} SDActionType;

@interface SDDownloadManager : UIViewController <SDSafariDownloadDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate, SDDownloadActionSheetDelegate> {
  UITableView*			  _tableView;
  NSMutableSet*		  _mimeTypes;
  NSMutableSet*		  _extensions;
  NSMutableDictionary* _classMappings;
  NSMutableArray*		  _currentDownloads;
  NSMutableArray*		  _finishedDownloads;
  NSOperationQueue*	  _downloadQueue;
  UIToolbarButton*	  _portraitDownloadButton;
  UIToolbarButton*	  _landscapeDownloadButton;
  NSURLRequest*		  currentRequest;
  SDSafariDownload*	  curDownload;
  NSDictionary			  *_userPrefs;
  BOOL					  _visible;
  NSURL					  *_loadingURL;
  BOOL					  _isDismissible;
  SDFileBrowserPanel*  _fbPanel;
  NSIndexPath *_currentSelectedIndexPath;
  id<BrowserPanel>	  _oldPanel;
}

@property (nonatomic, assign) UIToolbarButton*  portraitDownloadButton;
@property (nonatomic, assign) UIToolbarButton*  landscapeDownloadButton;
@property (nonatomic, retain) NSURLRequest*     currentRequest;

@property (nonatomic, retain) NSDictionary*	userPrefs;

@property (nonatomic, assign, getter=isVisible) BOOL visible;
@property (nonatomic, retain) NSURL *loadingURL;

+ (id)uniqueFilenameForFilename:(NSString *)filename atPath:(NSString *)path;

+ (id)sharedManager;
- (void)updateUserPreferences;
- (void)updateFileTypes;
- (NSString *)iconPathForName:(NSString *)name;
- (UIImage *)iconForExtension:(NSString *)extension orMimeType:(NSString *)mimeType;
- (BOOL)supportedRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType;

- (NSString*)fileNameForURL:(NSURL*)url;
- (SDActionType) webView:(WebView *)webView 
            decideAction:(NSDictionary*)action
              forRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType 
                 inFrame:(WebFrame *)frame
            withListener:(id<WebPolicyDecisionListener>)listener;

- (BOOL)addDownloadWithInfo:(NSDictionary*)info browser:(BOOL)b;
- (BOOL)addDownloadWithURL:(NSURL*)url browser:(BOOL)b;
- (BOOL)addDownloadWithRequest:(NSURLRequest*)url browser:(BOOL)b;
- (BOOL)addDownloadWithRequest:(NSURLRequest*)request andMimeType:(NSString *)mimeType browser:(BOOL)b;
- (BOOL)addDownload:(SDSafariDownload *)download browser:(BOOL)b;
- (BOOL)cancelDownload:(SDSafariDownload *)download;
- (BOOL)cancelDownloadWithURL:(NSURL *)url;
- (IBAction)cancelAllDownloads;

- (void)updateBadges;
@end
