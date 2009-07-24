//
//  DownloadManager.h
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SafariDownload.h"

#define kProgressViewTag 238823
#define progressViewForCell(cell) ((UIProgressView*)[cell viewWithTag:kProgressViewTag])

@interface DownloadManager : UITableViewController <SafariDownloadDelegate, UITableViewDelegate, UITableViewDataSource> {
  UITableView*      _tableView;
  NSArray*          _mimeTypes;
  NSMutableArray*   _currentDownloads;
  NSOperationQueue* _downloadQueue;
}

+ (id)sharedManager;

- (BOOL)supportedRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType;

- (BOOL)addDownloadWithInfo:(NSDictionary*)info;
- (BOOL)addDownloadWithURL:(NSURL*)url;
- (BOOL)addDownloadWithRequest:(NSURLRequest*)url;
- (BOOL)addDownload:(SafariDownload *)download;
- (BOOL)cancelDownload:(SafariDownload *)download;
- (BOOL)cancelDownloadWithURL:(NSURL *)url;
- (void)cancelAllDownloads;

@end
