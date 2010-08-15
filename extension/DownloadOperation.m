#import <objc/runtime.h>
#import "DownloadManager.h"
#import "DownloadOperation.h"
#import "NSURLDownload.h"
#import "ModalAlert.h"
#import "WebUI/WebUI.h"
#import "Safari/BrowserController.h"
#import "WebUI4/WebUIAuthenticationManager.h"

#import "SandCastle.h"

@interface SDDownloadOperation (extra)
id _authenticationView = nil;
@end

@implementation SDDownloadOperation
@synthesize delegate = _delegate;
@synthesize temporaryPath = _temporaryPath;

- (id)initWithDelegate:(id)del {
  if (![super init]) return nil;
  self.delegate = del;
  return self;
}

- (void)dealloc {
  NSLog(@"OPERATION DEALLOC!");
  _delegate = nil;
  [_downloader release];
  [_response release];
  [_temporaryPath release];
  [super dealloc];
}

- (void)progressHeartbeat:(NSTimer*)timer {
  //NSLog(@"Heartbeat firing, _keepalive %d _response %@", _keepAlive, _response);
  if (_keepAlive && _response && !_noUpdate) {
    long long expectedLength = [_response expectedContentLength];
    if(_wasResumed) expectedLength += _resumedFrom;
    float avspd = (float)(_downloadedBytes/1024)/(float)([NSDate timeIntervalSinceReferenceDate] - _start);
    float percentComplete=(float)(_bytes/expectedLength);
    
#if 0
	static int doTwice = 0;
    if (percentComplete > 0.2 && doTwice < 2) {
	  doTwice++;
      NSLog(@"SIMULATING FAILURE!!");
      [_downloader cancel];
      [_timer invalidate];
      _timer = nil;
      [self download:_downloader didFailWithError:nil];
    }
#endif
    
    //NSLog(@"HOLY CRAP. HEARTBEAT FIRING. PROGRESS: %f", _bytes);
    [_delegate setProgress:percentComplete speed:avspd];
  }
  else if (!_keepAlive) {
    [_timer invalidate];
    _timer = nil;
  }
  //[self storeResumeData];
}

- (void)cancelFromAuthenticationView:(id)authenticationView {
  [[objc_getClass("BrowserController") sharedBrowserController] hideBrowserPanel];  
  _requiresAuthentication = NO;
}

- (void)setCredential:(NSURLCredential*)cred {
  [_authCredential release];
  _authCredential = [cred retain]; 
}

- (void)logInFromAuthenticationView:(id)authenticationView withCredential:(id)credential {
  [[objc_getClass("BrowserController") sharedBrowserController] hideBrowserPanel];
  [self setCredential:credential];
  _requiresAuthentication = NO;
}

+ (id)authView {
  return _authenticationView; 
}

- (BOOL)requiresAuth {
  return _requiresAuthentication; 
}

- (void)showAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge {
  Class authView = objc_getClass("MyAuthenticationView");
  if(authView != nil) { // We are somewhere where we can use the old authentication view.
    _authenticationView = [[objc_getClass("MyAuthenticationView") alloc] initWithDelegate:self];
    [[objc_getClass("BrowserController") sharedBrowserController] showBrowserPanelType:88];
    NSLog(@"setting challenge: %@", challenge);
    [_authenticationView setSavedChallenge:challenge];
    [_authenticationView setChallenge:challenge];
    [_authenticationView layoutSubviews];
    [_authenticationView setNeedsDisplay];
  } else { // We have to use the new WebUIAuthenticationManager
    WebUIAuthenticationManager *authManager = [[objc_getClass("WebUIAuthenticationManager") alloc] init];
    [authManager setDelegate:self];
    [authManager addAuthenticationChallenge:challenge displayPanel:YES];
  }
}

- (void)cancelFromAuthenticationManager:(id)authenticationManager forChallenge:(id)challenge {
  [[objc_getClass("BrowserController") sharedBrowserController] hideBrowserPanel];  
  _requiresAuthentication = NO;
  [authenticationManager autorelease];
}

- (void)logInFromAuthenticationManager:(id)authenticationManager withCredential:(id)credential forChallenge:(id)challenge {
  [self setCredential:credential];
  _requiresAuthentication = NO;
  [authenticationManager autorelease];
}

#pragma mark -
#pragma mark NSURLDownload Delegates

- (void)setDownloadResponse:(NSURLResponse *)aDownloadResponse {
  [aDownloadResponse retain];
  [_response release];
  _response = aDownloadResponse;
}

-(void)download:(NSURLDownload *)download
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
  NSLog(@"didReceiveAuthenticationChallenge!: %@", challenge);
  NSLog(@"challenge sender: %@", [challenge sender]);

  [_delegate downloadDidReceiveAuthenticationChallenge];
  _requiresAuthentication = YES;
  [self performSelectorOnMainThread:@selector(showAuthenticationChallenge:) 
                         withObject:challenge
                      waitUntilDone:YES];
  
  while (_authCredential == nil && _requiresAuthentication) {
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
  }
  NSLog(@"got credential: %@", _authCredential);
    
  if (!_authCredential) {
    [[challenge sender] cancelAuthenticationChallenge:challenge];
  }
  else {
    if ([challenge previousFailureCount] == 0) {
      [[challenge sender] useCredential:_authCredential
             forAuthenticationChallenge:challenge];
    }
    else {
      [[challenge sender] cancelAuthenticationChallenge:challenge];
      // inform the user that the user name and password
      // in the preferences are incorrect
      NSLog(@"previousFailureCount FAIL!!!");
    }
  }
  _requiresAuthentication = NO;
  [_authenticationView release];
  _authenticationView = nil;
  [_authCredential release];
  _authCredential = nil;
}

- (void)downloadDidBegin:(NSURLDownload *)download {
  _keepAlive = YES;
  NSLog(@"download started!"); 
  _start = [NSDate timeIntervalSinceReferenceDate]; 
  [_delegate downloadStarted];
  _timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(progressHeartbeat:) userInfo:nil repeats:YES];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
  NSLog(@"FILENAME SUGGESTED: %@", filename);
  if (_wasResumed) return;
  if ([_delegate useSuggest] || [_delegate filename] == nil) {
      self.temporaryPath = [NSString stringWithFormat:@"/tmp/.partial/%@", filename];
      [download setDestination:_temporaryPath allowOverwrite:YES];
      [_delegate setFilename:filename];
  }
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)resp {
  _keepAlive = YES;
  NSLog(@"Received response: %@", resp);
	long long expectedContentLength = [resp expectedContentLength];
  [_delegate setDownloadSize:expectedContentLength];
  _resumedFrom = 0.0;
	_start = [NSDate timeIntervalSinceReferenceDate];
  [self setDownloadResponse:resp];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length {
  _keepAlive = YES;
  _bytes += (float)length;
  _downloadedBytes += (float)length;
  //NSLog(@"didReceiveDataOfLength: %u, _bytes now = %.1f", length, _bytes);
  
  float avspd = (float)(_downloadedBytes/1024)/(float)([NSDate timeIntervalSinceReferenceDate] - _start);
  if (avspd > 500 && avspd < 2048) { // throttle
    NSUInteger sleepTime = 50000*((avspd-500)/1000);
    usleep(sleepTime);
  }
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)resp fromByte:(long long)startingByte {
  NSLog(@"willResumeWithResponse: %@ fromByte: %ll", resp, startingByte);
  _keepAlive = YES;
	long long expectedContentLength = [resp expectedContentLength];
  [_delegate setDownloadSize:expectedContentLength + startingByte];
	_start = [NSDate timeIntervalSinceReferenceDate];
  [self setDownloadResponse:resp];
  if (startingByte > 0) { // If we're actually resuming at all...
    _bytes = startingByte;
    _resumedFrom = startingByte;
    _wasResumed = YES;
  }
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
  NSLog(@"didFailWithError: %@", error);
  
  if (_timer && [_timer isValid]) {
	[_timer invalidate];
	_timer = nil;
  }
  
  if (_bytes > 0) {
	[self storeResumeData];
  }
  else {
	[[NSFileManager defaultManager] removeItemAtPath:_temporaryPath error:nil];
  }
  
  _bytes = 0.0;
  _downloadedBytes = 0.0;
  _resumedFrom = 0;
  
  NSDictionary* prefs = [[SDDownloadManager sharedManager] userPrefs];
  BOOL doNotRetry = [[prefs objectForKey:@"AutoRetryDisabled"] boolValue];
  NSUInteger max_retries = [[prefs objectForKey:@"AutoRetryCount"] unsignedIntValue];
  if (!prefs)
	max_retries = 3;
  
  if (!doNotRetry) {
	NSInteger code = [error code];
	if (_retryCount < max_retries
		&& code != NSURLErrorCancelled
		&& code != NSURLErrorBadURL
		&& code != NSURLErrorUnsupportedURL
		&& code != NSURLErrorDataLengthExceedsMaximum
		&& code != NSURLErrorHTTPTooManyRedirects
		&& code != NSURLErrorNotConnectedToInternet
		&& code != NSURLErrorUserCancelledAuthentication
		&& code != NSURLErrorUserAuthenticationRequired
		&& code != NSURLErrorZeroByteResource
		&& code != NSURLErrorNoPermissionsToReadFile
		&& code != NSURLErrorCannotCreateFile
		&& code != NSURLErrorCannotOpenFile
		&& code != NSURLErrorCannotWriteToFile
		&& code != NSURLErrorCannotCloseFile
		&& code != NSURLErrorCannotRemoveFile
		&& code != NSURLErrorCannotMoveFile) {
	  NSLog(@"retry count is %u < %u, retrying", _retryCount, max_retries);
	  [_delegate setProgress:0 speed:0];
	  [_delegate setRetryString:[NSString stringWithFormat:@"Retrying %u of %u times", _retryCount+1, max_retries]];
	  _retryCount++;
	  
	  float wait = [[prefs objectForKey:@"AutoRetryInterval"] floatValue];
	  if (wait > 0) {
		NSLog(@"waiting for %.1f seconds before continuing");
		usleep((int)(wait*1000000));
	  }
	  
	  if ([self beginDownload] == NO) {
		NSLog(@"download failed to begin, failing");
		goto fail;
	  }
	  else {
		NSLog(@"download began successfully");
		return;
	  }
	}
	else
	  goto fail;
	
  }
  
fail:
  NSLog(@"we have failed!");
  _noUpdate = YES;
  _keepAlive = NO;
  [_delegate downloadFailedWithError:error];
}

- (void)downloadDidFinish:(NSURLDownload *)download {
    
    NSString* finalDestination4 = [NSString stringWithFormat:@"%@/%@", [_delegate savePath], [_delegate filename]];
    
  NSLog(@"DL FINISHED! (->%@)", finalDestination4);
    [[objc_getClass("SandCastle") sharedInstance] createDirectoryAtResolvedPath:[_delegate savePath]];
    [[objc_getClass("SandCastle") sharedInstance] moveTemporaryFile:_temporaryPath
                                                     toResolvedPath:finalDestination4];     
  _keepAlive = NO;
  _start = [NSDate timeIntervalSinceReferenceDate];
  [self deleteDownload];
  [_delegate setComplete:YES];
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
  return NO;
}

//- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
//  NSString *curFn = [_delegate filename];
//  NSString *newFn = [path lastPathComponent];
//  NSLog(@"didCreateDestination:%@", path);
//  if(![newFn isEqualToString:curFn]) [_delegate setFilename:newFn];
//  return;
//}

- (BOOL)beginDownload {
  BOOL resumeResult = [self resumeDownload];
  if (resumeResult)
    return YES;
  
  [self deleteDownload];
  
  [[NSFileManager defaultManager] createDirectoryAtPath:@"/tmp/.partial" 
                            withIntermediateDirectories:YES
                                             attributes:nil error:nil];
  
  _downloader = [[NSURLDownload alloc] initWithRequest:[_delegate urlReq] delegate:self];
  if (_downloader == nil)
    return NO;
  else
  {
    NSLog(@"Restarting download from scratch");
    _keepAlive = YES;
    [_downloader setDeletesFileUponFailure: NO];
    if (![_delegate useSuggest] && [_delegate filename] != nil) {
        self.temporaryPath = [NSString stringWithFormat:@"/tmp/.partial/%@", [_delegate filename]];
        [_downloader setDestination:_temporaryPath allowOverwrite:YES];
    }
    _start = [NSDate timeIntervalSinceReferenceDate];
    _bytes = 0.0;
    _resumedFrom = 0.0;
  }
  
  return YES;
}

- (BOOL)resumeDownload {
  NSString *resumeDataPath = [NSString stringWithFormat:@"/tmp/.partial/%@.plist", [_delegate filename]];
  NSString *outputPath = [NSString stringWithFormat:@"/tmp/.partial/%@", [_delegate filename]];
  
  //NSLog(resumeDataPath);
  //NSLog(outputPath);
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:resumeDataPath] == NO) {
    NSLog(@"RESUME file not found");
    [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    return NO;
  }
  
  NSData *resumeData = [NSData dataWithContentsOfFile:resumeDataPath];
  if (resumeData == nil || [resumeData length] == 0) {
    NSLog(@"RESUME data is nil");
      [[NSFileManager defaultManager] removeItemAtPath:resumeDataPath error:nil];
      [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    return NO;
  }
  
  self.temporaryPath = [NSString stringWithFormat:@"/tmp/.partial/%@", [_delegate filename]];
  _downloader = [[NSURLDownload alloc] initWithResumeData:resumeData delegate:self path:outputPath];
  if (_downloader == nil) {
    NSLog(@"downloader is nil");
    return NO;
  }
  else {
    NSLog(@"Resuming download from data: %@", resumeData);
    _keepAlive = YES;
    [_downloader setDeletesFileUponFailure: NO];
    _start = [NSDate timeIntervalSinceReferenceDate];
  }
  
  return YES;
}

- (void)deleteDownload {
  NSString *path = [NSString stringWithFormat:@"/tmp/.partial/%@", [_delegate filename]];
  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)cancelDownload {
  _noUpdate = YES;
  [_downloader cancel];
  //[self storeResumeData];
  _keepAlive = NO;
}

- (void)storeResumeData {
  NSData *data = [_downloader resumeData];
  NSLog(@"storing resume data with length: %u", [data length]);
  if (data != nil) {
    NSLog(@"storing resume data OK!");
    NSString *path = [NSString stringWithFormat:@"/tmp/.partial/%@.plist", [_delegate filename]];
    [data writeToFile:path atomically:YES];
  }
}

- (void)cancel {
  NSLog(@"Received Cancel!");
  [self cancelDownload];
  [_delegate downloadCancelled];
}

- (void)main {
  // somebody set up us the bomb
  if ([self beginDownload] == NO) {
    [_delegate downloadFailedWithError:nil];
    return;
  }
  NSLog(@"Starting runloop");
  NSRunLoop *theRL = [NSRunLoop currentRunLoop];
  while (_keepAlive) {
    [theRL runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
  }
  [_timer invalidate];
  _timer = nil;
  NSLog(@"Terminating Runloop!");
}

@end

// vim:filetype=objc:ts=2:sw=2:expandtab
