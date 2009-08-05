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
#import "UIKitExtra/UIToolbarButton.h"

#define kProgressViewTag 238823
#define progressViewForCell(cell) ((UIProgressView*)[cell viewWithTag:kProgressViewTag])

@interface UIActionSheet (hidden)
- (void)setMessage:(id)message;
@end

@interface DownloadManagerPanel : NSObject <BrowserPanel>
{
  BOOL _allowsRotations; 
}
- (void)allowRotations:(BOOL)allow;
@end

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
}

@property (nonatomic, retain) UINavigationItem* navItem;
@property (nonatomic, assign) UIToolbarButton *portraitDownloadButton;
@property (nonatomic, assign) UIToolbarButton *landscapeDownloadButton;

+ (id)sharedManager;
- (void)updateFileTypes;
- (NSString *)iconPathForName:(NSString *)name;
- (UIImage *)iconForExtension:(NSString *)extension orMimeType:(NSString *)mimeType;
- (BOOL)supportedRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType;

- (NSString*)fileNameForURL:(NSURL*)url;

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
