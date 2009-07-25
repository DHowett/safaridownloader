#import "DownloadOperation.h"
#import "NSURLDownload.h"

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

#pragma mark -
#pragma mark NSURLDownload Delegates

- (void)setDownloadResponse:(NSURLResponse *)aDownloadResponse
{
  [aDownloadResponse retain];
  [_response release];
  _response = aDownloadResponse;
}

- (void)downloadDidBegin:(NSURLDownload *)download
{
  _keepAlive = YES;
  NSLog(@"download started!"); 
  _start = [NSDate timeIntervalSinceReferenceDate]; 
  [_delegate downloadStarted];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
  NSLog(@"FILENAME SUGGESTED: %@", filename);
  [download setDestination:[NSString stringWithFormat:@"/var/mobile/Library/Downloads/%@", filename] allowOverwrite:YES];
  [_delegate setFilename:filename];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)resp
{
  _keepAlive = YES;
  NSLog(@"Received response: %@", resp);
	long long expectedContentLength = [resp expectedContentLength];
  [_delegate setSize:expectedContentLength];
	_start = [NSDate timeIntervalSinceReferenceDate];
  [self setDownloadResponse:resp];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
  _keepAlive = YES;
  _bytes += length;
  long long expectedLength = [_response expectedContentLength];
  float avspd = (float)(_bytes/1024)/(float)([NSDate timeIntervalSinceReferenceDate] - _start);
	float percentComplete=(float)(_bytes/expectedLength);
  [_delegate setProgress:percentComplete speed:avspd];
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)resp fromByte:(long long)startingByte;
{
  NSLog(@"willResumeWithResponse: %@ fromByte: %ll", resp, startingByte);
  _keepAlive = YES;
	long long expectedContentLength = [resp expectedContentLength];
  [_delegate setSize:expectedContentLength + startingByte];
	_start = [NSDate timeIntervalSinceReferenceDate];
  [self setDownloadResponse:resp];
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
  NSLog(@"DL FAILED! %@", [error description]);
  [self storeResumeData];
  _keepAlive = NO;
  _start = [NSDate timeIntervalSinceReferenceDate];
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

- (BOOL)beginDownload
{
  if ([self resumeDownload] == YES)
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
    NSLog(@"Restarting download from scratch - 114!");
    _keepAlive = YES;
    [_downloader setDeletesFileUponFailure: NO];
//    [_downloader setDestination:[NSString stringWithFormat:@"/var/mobile/Library/Downloads/%@", [_delegate filename]] allowOverwrite:YES];
    _start = [NSDate timeIntervalSinceReferenceDate];
    _bytes = 0.0;
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
    NSLog(@"Resuming download - 141! from length: %u", [resumeData length]);
    _keepAlive = YES;
    [_downloader setDeletesFileUponFailure: NO];
    _start = [NSDate timeIntervalSinceReferenceDate];
    _bytes =[resumeData length]; 
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
  [_downloader cancel];
  [self storeResumeData];
  _keepAlive = NO;
}

- (void) storeResumeData
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
    [theRL runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3]];
  }
  NSLog(@"Terminating Runloop!");
}

@end

// vim:filetype=objc:ts=2:sw=2:expandtab
