#import <UIKit/UIKit.h>
#import "NSURLDownload.h"
#import "WebUI/AuthenticationView.h"

@protocol SDDownloadOperationDelegate
- (NSURLRequest *)urlReq;
- (NSString *)filename;
- (BOOL)useSuggest;
- (void)setFilename:(NSString *)filename;
- (void)setComplete:(BOOL)comp;
- (void)setDownloadSize:(long long)length;
- (void)setProgress:(float)prg speed:(float)spd;
- (void)downloadDidReceiveAuthenticationChallenge;
- (void)downloadStarted;
- (void)downloadFailedWithError:(NSError *)err;
- (void)downloadCancelled;
@end

@interface SDDownloadOperation : NSOperation {
  id					  _delegate;
  NSURLDownload*	  _downloader;
  NSURLCredential*  _authCredential;
  NSURLResponse*	  _response;
  NSTimeInterval	  _start;
  BOOL				  _keepAlive;
  float				  _bytes;
  NSTimer*			  _timer;
  NSUInteger		  _retryCount;
  BOOL				  _noUpdate;
  BOOL				  _wasResumed;
  long long			  _resumedFrom;
  float				  _downloadedBytes;
  BOOL				  _requiresAuthentication;
  NSString*			  _temporaryPath;
  NSMutableDictionary* _resumeData;
}

+ (id)authView;

@property (retain) id<SDDownloadOperationDelegate> delegate;
@property (nonatomic, copy) NSString* temporaryPath;

- (id)initWithDelegate:(id)del;
- (void)deleteDownload;
- (void)storeResumeData;
- (BOOL)beginDownload;
- (BOOL)resumeDownload;
- (void)cancelDownload;
@end

@interface MyAuthenticationView : AuthenticationView
- (void)setSavedChallenge:(id)savedChallenge;
@end
