//
//  SafariDownload.h
//  SafariDownload
//
//  Created by Youssef Francis on 7/21/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadOperation.h"

@class SafariDownload;
@protocol SafariDownloadDelegate

- (void)downloadDidBegin:(SafariDownload*)download;
- (void)downloadDidFinish:(SafariDownload*)download;
- (void)downloadDidUpdate:(SafariDownload*)download;
- (void)downloadDidFail:(SafariDownload*)download;

@end

@interface SafariDownload : NSObject <NSCoding, DownloadOperationDelegate>
{
  id             _delegate;
  NSURLRequest*  _urlRequest;
  NSDate*        _startDate;
  NSString*      _filename;
  NSString*      _sizeString;
  NSString*      _timeString;
  NSInteger      _size;
  NSInteger      _time_remaining;
  float          _progress;
  float          _speed;
  BOOL           _complete;
}

@property (assign)            id<SafariDownloadDelegate> delegate;
@property (nonatomic, retain) NSURLRequest    *urlReq;
@property (nonatomic, retain) NSDate          *startDate;
@property (nonatomic, retain) NSString        *filename;
@property (nonatomic, retain) NSString        *sizeString;
@property (nonatomic, retain) NSString        *timeString;
@property (assign) NSInteger  time;
@property (assign) NSInteger  size;
@property (assign) float      progress;
@property (assign) float      speed;
@property (assign) BOOL       complete;

- (id)initWithRequest:(NSURLRequest*)urlRequest name:(NSString *)name delegate:(id)del;
- (void)downloadFailedWithError:(NSError *)err;
- (void)setProgress:(float)prog speed:(float)spd;
- (void)downloadStarted;

@end
