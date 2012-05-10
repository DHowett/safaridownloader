/*
 * SDSafariDownload
 * SDM
 *
 * Dustin L. Howett
 * 2012-02-01
 */
#import "SDSafariDownload.h"
#import "SDMCommonClasses.h"
#import <SandCastle/SandCastle.h>

@interface SDSafariDownload ()
@property (nonatomic, assign, readwrite) SDDownloadStatus status;
//@property (nonatomic, retain) NSString *filename;
//@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain, readwrite) NSString *temporaryPath;
@property (nonatomic, retain, readwrite) NSDate *startDate;
@property (nonatomic, assign, readwrite) unsigned long long totalBytes;
@property (nonatomic, assign, readwrite) unsigned long long downloadedBytes;
@property (nonatomic, assign, readwrite) unsigned int retryCount;
@property (nonatomic, retain, readwrite) NSError *lastError;
@property (nonatomic, assign, readwrite) unsigned long long startedFromByte;
//@property (nonatomic, retain) NSURLRequest *URLRequest;
@property (nonatomic, retain, readwrite) NSURLResponse *URLResponse;
@property (nonatomic, retain, readwrite) NSMutableDictionary *resumeData;
@property (nonatomic, assign, readwrite) BOOL requiresAuthentication;
@property (nonatomic, retain, readwrite) NSURLCredential *authenticationCredential;
@property (nonatomic, retain, readwrite) NSURLDownload *downloader;
@end

@implementation SDSafariDownload
@synthesize status = _status, filename = _filename,
	path = _path, temporaryPath = _temporaryPath,
	startDate = _startDate, totalBytes = _totalBytes,
	downloadedBytes = _downloadedBytes, retryCount = _retryCount,
	lastError = _lastError, startedFromByte = _startedFromByte,
	URLRequest = _URLRequest, URLResponse = _URLResponse,
	resumeData = _resumeData, requiresAuthentication = _requiresAuthentication,
	authenticationCredential = _authenticationCredential,
	downloader = _downloader, delegate = _delegate;

- (id)init {
	if((self = [super init]) != nil) {
		
	} return self;
}

- (void)dealloc {
	[_filename release];
	[_path release];
	[_temporaryPath release];
	[_startDate release];
	[_lastError release];
	[_URLRequest release];
	[_URLResponse release];
	[_resumeData release];
	[_authenticationCredential release];
	[_downloader release];
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeInt:self.status forKey:@"status"];
	[encoder encodeObject:self.filename forKey:@"filename"];
	[encoder encodeObject:self.path forKey:@"path"];
	[encoder encodeObject:self.temporaryPath forKey:@"temporaryPath"];
	[encoder encodeObject:self.startDate forKey:@"startDate"];
	[encoder encodeInt64:self.totalBytes forKey:@"totalBytes"];
	[encoder encodeInt64:self.downloadedBytes forKey:@"downloadedBytes"];
	[encoder encodeObject:self.URLRequest forKey:@"URLRequest"];
	[encoder encodeObject:self.resumeData forKey:@"resumeData"];
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if(!self) return nil;

	self.status = (SDDownloadStatus)[decoder decodeIntForKey:@"status"];
	self.filename = [decoder decodeObjectForKey:@"filename"];
	self.path = [decoder decodeObjectForKey:@"path"];
	self.temporaryPath = [decoder decodeObjectForKey:@"temporaryPath"];
	self.startDate = [decoder decodeObjectForKey:@"startDate"];
	self.totalBytes = [decoder decodeInt64ForKey:@"totalBytes"];
	self.downloadedBytes = [decoder decodeInt64ForKey:@"downloadedBytes"];
	self.URLRequest = [decoder decodeObjectForKey:@"URLRequest"];
	self.resumeData = [decoder decodeObjectForKey:@"resumeData"];
	return self;
}

- (void)setStatus:(SDDownloadStatus)status {
	_status = status;
	[_delegate downloadDidChangeStatus:self];
}

- (NSString *)_temporaryPathForFilename:(NSString *)filename {
	return [NSString stringWithFormat:@"/tmp/.partial/%@", filename];
}

- (void)_createTemporaryDirectory {
	[[NSFileManager defaultManager] createDirectoryAtPath:[self.temporaryPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
}

/* {{{ NSURLDownloadDelegate */
- (void)download:(NSURLDownload *)download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
	if(self.filename) return;
	if(_startedFromByte > 0) return; // Do not rename resumed files.
	self.temporaryPath = [self _temporaryPathForFilename:filename];
	[download setDestination:self.temporaryPath allowOverwrite:NO];
	if(_delegate) {
		self.filename = [_delegate uniqueFilenameForDownload:self withSuggestion:filename];
	} else {
		self.filename = @"";
	}
	[_delegate downloadDidProvideFilename:self];
}

- (void)downloadDidBegin:(NSURLDownload *)download {
	self.startDate = [NSDate date];
	self.status = SDDownloadStatusRunning;
#warning progress heartbeat timer.
}

- (void)download:(NSURLDownload *)download didCreateDestination:(NSString *)path {
	// TODO: This seems pointless to do:
	// self.temporaryPath = path;
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response {
	// Get the Etag for the resume data.
	// Get the expected content length.
	// Set the start date again? Why?
	// Save our response.
	NSLog(@"Download got URL response %@", response);
	if([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSDictionary *headerFields = [(NSHTTPURLResponse *)response allHeaderFields];
		NSString *eTag = [headerFields objectForKey:@"Etag"];
		NSURL *url = self.URLRequest.URL;
		NSLog(@"URL: %@, eTAG: %@", url, eTag);
		if(url && eTag) {
			self.resumeData = [NSMutableDictionary dictionary];
			[_resumeData setObject:eTag forKey:@"NSURLDownloadEntityTag"];
			if([headerFields objectForKey:@"Last-Modified"]) {
				[_resumeData setObject:[headerFields objectForKey:@"Last-Modified"] forKey:@"NSURLDownloadServerModificationDate"];
			}
			[_resumeData setObject:[url absoluteString] forKey:@"NSURLDownloadURL"];
			[_resumeData setObject:[NSNumber numberWithUnsignedInt:0] forKey:@"NSURLDownloadBytesReceived"];
		}
		NSLog(@"Download saved resume data %@", self.resumeData);
	}
	self.totalBytes = [response expectedContentLength];
	self.startedFromByte = 0;
	self.URLResponse = response;
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length {
	NSLog(@"Download received %u bytes", length);
	self.downloadedBytes += length;
	NSLog(@"I've now downloaded %llu bytes.", self.downloadedBytes);
	// TODO: Throttle?
	[self.resumeData setObject:[NSNumber numberWithUnsignedLongLong:self.downloadedBytes] forKey:@"NSURLDownloadBytesReceived"];
	[[_delegate class] cancelPreviousPerformRequestsWithTarget:_delegate selector:@selector(downloadDidReceiveData:) object:self];
	[_delegate performSelector:@selector(downloadDidReceiveData:) withObject:self afterDelay:0];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0]];
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
	return NO;
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)response fromByte:(long long)startingByte {
	// We already know the size, so we do not need to recalculate it.
	self.startDate = [NSDate date];
	self.URLResponse = response;
	self.startedFromByte = startingByte;
#warning do we get 'begin' here?
}

- (NSURLRequest *)download:(NSURLDownload *)download willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	// Maybe set our request to the updated request?
	return request;
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
	NSLog(@"Failed with error: %@", error);
	self.finished = YES;
	self.status = SDDownloadStatusFailed;
#warning oh shit.
}

- (void)downloadDidFinish:(NSURLDownload *)download {
	NSString *finalDestination4 = [self.path stringByAppendingPathComponent:self.filename];
	[[SDM$SandCastle sharedInstance] createDirectoryAtResolvedPath:self.path];
	[[SDM$SandCastle sharedInstance] moveTemporaryFile:self.temporaryPath toResolvedPath:finalDestination4];
	self.resumeData = nil;
	self.finished = YES;
	self.status = SDDownloadStatusCompleted;
}
/* }}} */

- (void)_deleteData {
	self.resumeData = nil;
	if(self.temporaryPath)
		[[NSFileManager defaultManager] removeItemAtPath:self.temporaryPath error:NULL];
}

- (BOOL)_resume {
	if(!self.resumeData) return nil;
	self.temporaryPath = [self _temporaryPathForFilename:self.filename];
	NSData *resumeDataSerialization = [NSPropertyListSerialization dataFromPropertyList:self.resumeData format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL];
	self.downloader = [[[NSURLDownload alloc] initWithResumeData:resumeDataSerialization delegate:self path:self.temporaryPath] autorelease];
	if(!self.downloader) {
		self.resumeData = nil;
		return NO;
	}

	self.downloader.deletesFileUponFailure = NO;
	return YES;
}

- (BOOL)_begin {
	if([self _resume]) return YES;

	[self _deleteData];
	self.downloader = [[[NSURLDownload alloc] initWithRequest:self.URLRequest delegate:self] autorelease];
	if(!self.downloader) return NO;
	self.downloader.deletesFileUponFailure = NO;
	if(self.filename) {
		self.temporaryPath = [self _temporaryPathForFilename:self.filename];
		[_downloader setDestination:self.temporaryPath allowOverwrite:NO];
	}

	self.totalBytes = 0;
	self.downloadedBytes = 0;

	return YES;
}

- (void)main {
	NSLog(@"Attempting to begin download.");
	if([self _begin] == NO) {
		NSLog(@"Begin failed");
		[self complete];
		// TODO: Notify Owner that we Failed.
		return;
	}
	[self _createTemporaryDirectory];
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	do {
		[runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	} while(!self.finished && ![self isCancelled]);
	if([self isCancelled]) {
		[self.downloader cancel];
		[self _deleteData];
		self.status = SDDownloadStatusCancelled;
	}
	[self complete];
	// TODO: Kill heartbeat timer.
}

@end
