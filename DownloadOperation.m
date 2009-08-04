#import "DownloadManager.h"
#import "DownloadOperation.h"
#import "NSURLDownload.h"
#import "ModalAlert.h"
#import "WebUI/WebUI.h"
#import "Safari/BrowserController.h"

#ifndef DEBUG
#define NSLog(...)
#endif

@interface DownloadOperation (extra)
AuthenticationView* _authenticationView;
@end

@implementation MyAuthenticationView
@synthesize savedChallenge;

- (void)_logIn {  
  if (!_challenge) {
    _challenge = savedChallenge;
  }
  [super _logIn];
}

- (void)didShowBrowserPanel {  
  UINavigationBar* navBar = nil;
  object_getInstanceVariable(self, "_navigationBar", (void**)&navBar);
  
  UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@"Secure Website"];
  [navItem setPrompt:@"This download requires authentication"];
  UIBarButtonItem* loginItem = [[UIBarButtonItem alloc] initWithTitle:@"Log In" style:UIBarButtonItemStyleDone target:self action:@selector(_logIn)];
  UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(_cancel)];
  navItem.rightBarButtonItem = loginItem;
  navItem.leftBarButtonItem = cancelItem;
  [navBar popNavigationItemAnimated:NO];
  [navBar pushNavigationItem:navItem animated:NO];
}

@end

@implementation DownloadOperation
@synthesize delegate = _delegate;

- (id)initWithDelegate:(id)del;
{
  if (![super init]) return nil;
  self.delegate = del;
  return self;
}

- (void)dealloc {
  NSLog(@"OPERATION DEALLOC!");
  _delegate = nil;
  [_downloader release];
  [_response release];
  [super dealloc];
}

- (void)progressHeartbeat:(NSTimer*)timer
{
  NSLog(@"Heartbeat firing, _keepalive %d _response %@", _keepAlive, _response);
  if (_keepAlive && _response && !_noUpdate) {
    long long expectedLength = [_response expectedContentLength];
    if(_wasResumed) expectedLength += _resumedFrom;
    float avspd = (float)(_downloadedBytes/1024)/(float)([NSDate timeIntervalSinceReferenceDate] - _start);
    float percentComplete=(float)(_bytes/expectedLength);
    
#if 0
    if (percentComplete > 0.2) {
      NSLog(@"SIMULATING FAILURE!!");
      [_downloader cancel];
      [_timer invalidate];
      _timer = nil;
      [self download:_downloader didFailWithError:nil];
    }
#endif
    
    NSLog(@"HOLY CRAP. HEARTBEAT FIRING. PROGRESS: %f", _bytes);
    [_delegate setProgress:percentComplete speed:avspd];
  }
  else if (!_keepAlive)
  {
    [_timer invalidate];
    _timer = nil;
  }
}

static id savedPanel = nil;

-(void)cancelFromAuthenticationView:(id)authenticationView {
  [[objc_getClass("BrowserController") sharedBrowserController] hideBrowserPanel];
    
  if (savedPanel == [[DownloadManager sharedManager] browserPanel]) {
    [[objc_getClass("BrowserController") sharedBrowserController] _setBrowserPanel:savedPanel];
    NSLog(@"download manager is down!!!");
    [[DownloadManager sharedManager] view].alpha = 1;
  }
  
  [savedPanel release];
  savedPanel = nil;
  
  _requiresAuthentication = NO;
}

-(void)logInFromAuthenticationView:(id)authenticationView withCredential:(id)credential {
  [[objc_getClass("BrowserController") sharedBrowserController] hideBrowserPanel];
  [self setCredential:credential];
    
  if (savedPanel == [[DownloadManager sharedManager] browserPanel]) {
    [[objc_getClass("BrowserController") sharedBrowserController] _setBrowserPanel:savedPanel];
    NSLog(@"download manager is down!!!");
    [[DownloadManager sharedManager] view].alpha = 1;
  }
  
  [savedPanel release];
  savedPanel = nil;
  
  _requiresAuthentication = NO;
}

+ (MyAuthenticationView*)authView {
  return _authenticationView; 
}

- (BOOL)requiresAuth {
  return _requiresAuthentication; 
}

- (void)setCredential:(NSURLCredential*)cred {
  _authCredential = [cred retain]; 
}

- (void)showAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge {
  
  savedPanel = [[[objc_getClass("BrowserController") sharedBrowserController] browserPanel] retain];
  
  if (savedPanel == [[DownloadManager sharedManager] browserPanel]) {
    NSLog(@"download manager is up!!!");
    [[DownloadManager sharedManager] view].alpha = 0;
    [[objc_getClass("BrowserController") sharedBrowserController] _setBrowserPanel:nil];
  }
  
  [[objc_getClass("BrowserController") sharedBrowserController] showBrowserPanelType:88];
  [[objc_getClass("BrowserController") sharedBrowserController] _setBrowserPanel:_authenticationView];
  NSLog(@"setting challenge: %@", challenge);
  [_authenticationView setSavedChallenge:challenge];
  [_authenticationView setChallenge:challenge];
  [_authenticationView layoutSubviews];
  [_authenticationView setNeedsDisplay];
  [ModalAlert dismissLoadingAlert];
}

#pragma mark -
#pragma mark NSURLDownload Delegates

- (void)setDownloadResponse:(NSURLResponse *)aDownloadResponse
{
  [aDownloadResponse retain];
  [_response release];
  _response = aDownloadResponse;
}

-(void)download:(NSURLDownload *)download
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
  NSLog(@"didReceiveAuthenticationChallenge!: %@", challenge);
  [_delegate downloadDidReceiveAuthenticationChallenge];
  _requiresAuthentication = YES;
  _authenticationView = [[MyAuthenticationView alloc] initWithDelegate:self];
  NSLog(@"checking authview challenge: %@", [_authenticationView challenge]);
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

- (void)downloadDidBegin:(NSURLDownload *)download
{
  _keepAlive = YES;
  NSLog(@"download started!"); 
  _start = [NSDate timeIntervalSinceReferenceDate]; 
  [_delegate downloadStarted];
  _timer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(progressHeartbeat:) userInfo:nil repeats:YES];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
  NSLog(@"FILENAME SUGGESTED: %@", filename);
  if (_wasResumed) return;
  if ([_delegate useSuggest] || [_delegate filename] == nil) {
    [download setDestination:[NSString stringWithFormat:@"/var/mobile/Library/Downloads/%@", filename] allowOverwrite:YES];
  }
  [_delegate setFilename:filename];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)resp
{
  [ModalAlert dismissLoadingAlert];
  _keepAlive = YES;
  NSLog(@"Received response: %@", resp);
	long long expectedContentLength = [resp expectedContentLength];
  [_delegate setSize:expectedContentLength];
  _resumedFrom = 0.0;
	_start = [NSDate timeIntervalSinceReferenceDate];
  [self setDownloadResponse:resp];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
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

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)resp fromByte:(long long)startingByte;
{
  [ModalAlert dismissLoadingAlert];
  NSLog(@"willResumeWithResponse: %@ fromByte: %ll", resp, startingByte);
  _keepAlive = YES;
	long long expectedContentLength = [resp expectedContentLength];
  [_delegate setSize:expectedContentLength + startingByte];
	_start = [NSDate timeIntervalSinceReferenceDate];
  [self setDownloadResponse:resp];
  if (startingByte > 0) { // If we're actually resuming at all...
    _bytes = startingByte;
    _resumedFrom = startingByte;
    _wasResumed = YES;
  }
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
  NSLog(@"didFailWithError: %@", error);
  [self storeResumeData];
  NSInteger code = [error code];
  if (_retryCount < 3
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
      && code != NSURLErrorCannotMoveFile)
  {
    NSLog(@"retry count is %d, resuming", _retryCount);
    _retryCount++;
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
  
fail:
  NSLog(@"we have failed!");
  _noUpdate = YES;
  [_timer invalidate];
  _timer = nil;
  _keepAlive = NO;
  [_delegate downloadFailedWithError:error];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
  NSLog(@"DL FINISHED!");
  _keepAlive = NO;
  _start = [NSDate timeIntervalSinceReferenceDate];
  [self deleteDownload];
  [_delegate setComplete:YES];
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
  return NO;
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
  NSString *curFn = [_delegate filename];
  NSString *newFn = [path lastPathComponent];
  NSLog(@"didCreateDestination:%@", path);
  if(![newFn isEqualToString:curFn]) [_delegate setFilename:newFn];
  return;
}

- (BOOL)beginDownload
{
  BOOL resumeResult = [self resumeDownload];
  if (resumeResult)
    return YES;
  
  [self deleteDownload];
  
  [[NSFileManager defaultManager] createDirectoryAtPath:@"/var/mobile/Library/Downloads/partial" 
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
      [_downloader setDestination:[NSString stringWithFormat:@"/var/mobile/Library/Downloads/%@", [_delegate filename]] allowOverwrite:YES];
    }
    _start = [NSDate timeIntervalSinceReferenceDate];
    _bytes = 0.0;
    _resumedFrom = 0.0;
  }
  
  return YES;
}

- (BOOL)resumeDownload
{
  NSString *resumeDataPath = [NSString stringWithFormat:@"/var/mobile/Library/Downloads/partial/%@", [_delegate filename]];
  NSString *outputPath = [NSString stringWithFormat:@"/var/mobile/Library/Downloads/%@", [_delegate filename]];
  
  NSLog(resumeDataPath);
  NSLog(outputPath);
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:resumeDataPath] == NO)
  {
    NSLog(@"file not found");
    return NO;
  }
  
  NSData *resumeData = [NSData dataWithContentsOfFile:resumeDataPath];
  if (resumeData == nil || [resumeData length] == 0)
  {
    NSLog(@"data is nil");
    return NO;
  }
  
  _downloader = [[NSURLDownload alloc] initWithResumeData:resumeData delegate:self path:outputPath];
  if (_downloader == nil)
  {
    NSLog(@"downloader is nil");
    return NO;
  }
  else
  {
    NSLog(@"Resuming download from data: %@", resumeData);
    _keepAlive = YES;
    [_downloader setDeletesFileUponFailure: NO];
    _start = [NSDate timeIntervalSinceReferenceDate];
  }
  
  return YES;
}

- (void)deleteDownload
{
  NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Downloads/partial/%@", [_delegate filename]];
  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

- (void)cancelDownload
{
  _noUpdate = YES;
  [_downloader cancel];
  [self storeResumeData];
  _keepAlive = NO;
}

- (void)storeResumeData
{
  NSData *data = [_downloader resumeData];
  NSLog(@"storing resume data with length: %u", [data length]);
  if (data != nil)
  {
    NSLog(@"storing resume data OK!");
    NSString *path = [NSString stringWithFormat:@"/var/mobile/Library/Downloads/partial/%@", [_delegate filename]];
    [data writeToFile:path atomically:YES];
  }
}

- (void)cancel
{
  NSLog(@"Received Cancel!");
  [self cancelDownload];
  [_delegate downloadCancelled];
}

- (void)main 
{
  // somebody set up us the bomb
  if ([self beginDownload] == NO)
  {
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
