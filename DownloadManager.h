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

@interface DownloadManagerPanel : NSObject <BrowserPanel>
{
  BOOL _allowsRotations; 
}
- (void)allowRotations:(BOOL)allow;
@end

typedef enum
{
  SDActionTypeNone = 0,
  SDActionTypeView = 1,
  SDActionTypeDownload = 2,
  SDActionTypeCancel = 3,
} SDActionType;

@interface DownloadManager : UITableViewController <SafariDownloadDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIActionSheetDelegate> {
  UITableView*      _tableView;
  NSMutableSet*     _mimeTypes;
  NSMutableSet*     _extensions;
  NSMutableDictionary* _classMappings;
  NSMutableDictionary* _launchActions;
  NSMutableArray*   _currentDownloads;
  NSMutableArray*   _finishedDownloads;
  NSOperationQueue* _downloadQueue;
  UIToolbarButton*  _portraitDownloadButton;
  UIToolbarButton*  _landscapeDownloadButton;
  UINavigationItem* _navItem;
  UINavigationBar*  _navBar;
  DownloadManagerPanel *_panel;
  NSURLRequest* currentRequest;
  SafariDownload* curDownload;
}

@property (nonatomic, retain) UINavigationItem* navItem;
@property (nonatomic, assign) UIToolbarButton*  portraitDownloadButton;
@property (nonatomic, assign) UIToolbarButton*  landscapeDownloadButton;
@property (nonatomic, retain) NSURLRequest*     currentRequest;

+ (id)sharedManager;
- (void)updateFileTypes;
- (NSString *)iconPathForName:(NSString *)name;
- (UIImage *)iconForExtension:(NSString *)extension orMimeType:(NSString *)mimeType;
- (BOOL)supportedRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType;

- (NSString*)fileNameForURL:(NSURL*)url;
- (void)loadCustomToolbar;
- (SDActionType) webView:(WebView *)webView 
            decideAction:(NSDictionary*)action
              forRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType 
                 inFrame:(WebFrame *)frame
            withListener:(id<WebPolicyDecisionListener>)listener;

- (BOOL)addDownloadWithInfo:(NSDictionary*)info;
- (BOOL)addDownloadWithURL:(NSURL*)url;
- (BOOL)addDownloadWithRequest:(NSURLRequest*)url;
- (BOOL)addDownloadWithRequest:(NSURLRequest*)request andMimeType:(NSString *)mimeType;
- (BOOL)addDownload:(SafariDownload *)download;
- (BOOL)cancelDownload:(SafariDownload *)download;
- (BOOL)cancelDownloadWithURL:(NSURL *)url;
- (IBAction)cancelAllDownloads;

- (DownloadManagerPanel*)browserPanel;
- (void)showDownloadManager;
- (IBAction)hideDownloadManager;

- (void)updateBadges;
@end
