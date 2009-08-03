#import <UIKit/UIKit.h>
#import "NSURLDownload.h"

@protocol DownloadOperationDelegate
- (NSURLRequest *)urlReq;
- (NSString *)filename;
- (BOOL)useSuggest;
- (void)setFilename:(NSString *)filename;
- (void)setComplete:(BOOL)comp;
- (void)setSize:(long long)size;
- (void)setProgress:(float)prg speed:(float)spd;
- (void)downloadStarted;
- (void)downloadFailedWithError:(NSError *)err;
- (void)downloadCancelled;
@end

@interface DownloadOperation : NSOperation {
  id             _delegate;
  NSURLDownload* _downloader;
  NSURLResponse* _response;
  NSTimeInterval _start;
  BOOL           _keepAlive;
  float          _bytes;
  NSTimer*       _timer;
  int            _retryCount;
  BOOL           _noUpdate;
}

@property (assign) id<DownloadOperationDelegate> delegate;

- (id)initWithDelegate:(id)del;
- (void)deleteDownload;
- (void)storeResumeData;
- (BOOL)beginDownload;
- (BOOL)resumeDownload;
- (void)cancelDownload;
@end
