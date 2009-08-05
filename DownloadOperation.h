#import <UIKit/UIKit.h>
#import "NSURLDownload.h"
#import "WebUI/AuthenticationView.h"

@protocol DownloadOperationDelegate
- (NSURLRequest *)urlReq;
- (NSString *)filename;
- (BOOL)useSuggest;
- (void)setFilename:(NSString *)filename;
- (void)setComplete:(BOOL)comp;
- (void)setDownloadSize:(NSInteger)length;
- (void)setProgress:(float)prg speed:(float)spd;
- (void)downloadDidReceiveAuthenticationChallenge;
- (void)downloadStarted;
- (void)downloadFailedWithError:(NSError *)err;
- (void)downloadCancelled;
@end

@interface DownloadOperation : NSOperation {
  id             _delegate;
  NSURLDownload* _downloader;
  NSURLCredential*  _authCredential;
  NSURLResponse* _response;
  NSTimeInterval _start;
  BOOL           _keepAlive;
  float          _bytes;
  NSTimer*       _timer;
  int            _retryCount;
  BOOL           _noUpdate;
  BOOL           _wasResumed;
  long long      _resumedFrom;
  float          _downloadedBytes;
  BOOL           _requiresAuthentication;
}

+ (id)authView;

@property (assign) id<DownloadOperationDelegate> delegate;

- (id)initWithDelegate:(id)del;
- (void)deleteDownload;
- (void)storeResumeData;
- (BOOL)beginDownload;
- (BOOL)resumeDownload;
- (void)cancelDownload;
@end

@interface MyAuthenticationView : AuthenticationView
{
  NSURLAuthenticationChallenge* savedChallenge;
}

@property (retain) NSURLAuthenticationChallenge* savedChallenge;

@end
