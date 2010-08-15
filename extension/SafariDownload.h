//
//  SDSafariDownload.h
//  SDSafariDownload
//
//  Created by Youssef Francis on 7/21/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadOperation.h"

@class SDSafariDownload;
@protocol SDSafariDownloadDelegate

- (void)downloadDidBegin:(SDSafariDownload*)download;
- (void)downloadDidReceiveAuthenticationChallenge:(SDSafariDownload*)download;
- (void)downloadDidProvideFilename:(SDSafariDownload*)download;
- (void)downloadDidFinish:(SDSafariDownload*)download;
- (void)downloadDidUpdate:(SDSafariDownload*)download;
- (void)downloadDidFail:(SDSafariDownload*)download;
- (void)downloadDidCancel:(SDSafariDownload*)download;
- (void)downloadWillRetry:(SDSafariDownload*)download;

@end

@interface SDSafariDownload : NSObject <NSCoding, SDDownloadOperationDelegate>
{
  id             _delegate;
  NSURLRequest*  _urlRequest;
  NSDate*        _startDate;
  NSString*      _filename;
  NSString*      _mimetype;
  NSString*      _sizeString;
  NSString*      _timeString;
  NSString*      _savePath;
  NSInteger      _size;
  NSInteger      _time_remaining;
  float          _progress;
  float          _speed;
  BOOL           _useSuggested;
  BOOL           _complete;
  BOOL           _failed;
  SDDownloadOperation *downloadOperation;
}

@property (assign)            id<SDSafariDownloadDelegate> delegate;
@property (nonatomic, retain) SDDownloadOperation *downloadOperation;
@property (nonatomic, retain) NSURLRequest    *urlReq;
@property (nonatomic, retain) NSDate          *startDate;
@property (nonatomic, retain) NSString        *filename;
@property (nonatomic, retain) NSString        *mimetype;
@property (nonatomic, retain) NSString        *sizeString;
@property (nonatomic, retain) NSString        *timeString;
@property (nonatomic, retain) NSString        *savePath;
@property (assign) NSInteger  time;
@property (assign) NSInteger  size;
@property (assign) float      progress;
@property (assign) float      speed;
@property (assign) BOOL       useSuggest;
@property (assign) BOOL       complete;
@property (assign) BOOL       failed;

- (id)initWithRequest:(NSURLRequest*)urlRequest name:(NSString *)name delegate:(id)del useSuggested:(BOOL)use;
- (void)downloadFailedWithError:(NSError *)err;
- (void)setProgress:(float)prog speed:(float)spd;
- (void)downloadStarted;
- (void)setRetryString:(NSString*)status;

@end
