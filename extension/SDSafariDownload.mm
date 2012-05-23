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

NSString * const kSDSafariDownloadTemporaryDirectory = @"/tmp/.partial";

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
- (BOOL)_begin;
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
	useSuggestedFilename = _useSuggestedFilename, mimeType = _mimeType,
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
	[_mimeType release];
	[super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeInt:_status forKey:@"status"];
	[encoder encodeObject:_filename forKey:@"filename"];
	[encoder encodeObject:_path forKey:@"path"];
	[encoder encodeObject:_temporaryPath forKey:@"temporaryPath"];
	[encoder encodeObject:_startDate forKey:@"startDate"];
	[encoder encodeInt64:_totalBytes forKey:@"totalBytes"];
	[encoder encodeInt64:_downloadedBytes forKey:@"downloadedBytes"];
	[encoder encodeObject:_URLRequest forKey:@"URLRequest"];
	[encoder encodeObject:_resumeData forKey:@"resumeData"];
	[encoder encodeObject:_mimeType forKey:@"mimeType"];
	[encoder encodeBool:_useSuggestedFilename forKey:@"useSuggestedFilename"];
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
	self.mimeType = [decoder decodeObjectForKey:@"mimeType"];
	self.useSuggestedFilename = [decoder decodeBoolForKey:@"useSuggestedFilename"];
	return self;
}

- (void)setStatus:(SDDownloadStatus)status {
	_status = status;
	[_delegate downloadDidChangeStatus:self];
}

- (void)setTotalBytes:(unsigned long long)totalBytes {
	_totalBytes = totalBytes;
	[_delegate downloadDidProvideSize:self];
}

- (NSString *)_temporaryPathForFilename:(NSString *)filename {
	return [kSDSafariDownloadTemporaryDirectory stringByAppendingPathComponent:filename];
}

- (void)_createTemporaryDirectory {
	[[NSFileManager defaultManager] createDirectoryAtPath:kSDSafariDownloadTemporaryDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
}

/* {{{ NSURLDownloadDelegate */
- (void)download:(NSURLDownload *)download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {

}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
	if(_useSuggestedFilename && _filename) return;
	if(_startedFromByte > 0) return; // Do not rename resumed files.
	self.filename = [_delegate uniqueFilenameForDownload:self withSuggestion:filename];
	self.temporaryPath = [self _temporaryPathForFilename:_filename];
	[download setDestination:_temporaryPath allowOverwrite:NO];
	[_delegate downloadDidProvideFilename:self];
}

- (void)downloadDidBegin:(NSURLDownload *)download {
	self.startDate = [NSDate date];
	self.status = SDDownloadStatusWaiting;
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
		NSURL *url = _URLRequest.URL;
		NSLog(@"URL: %@, eTAG: %@", url, eTag);
		if(url && eTag) {
			self.resumeData = [NSMutableDictionary dictionary];
			[_resumeData setObject:eTag forKey:@"NSURLDownloadEntityTag"];
			if([headerFields objectForKey:@"Last-Modified"]) {
				[_resumeData setObject:[headerFields objectForKey:@"Last-Modified"] forKey:@"NSURLDownloadServerModificationDate"];
			}
			[_resumeData setObject:[url absoluteString] forKey:@"NSURLDownloadURL"];
		}
		NSLog(@"Download saved resume data %@", _resumeData);
	}
	self.totalBytes = [response expectedContentLength];
	_startedFromByte = 0;
	self.URLResponse = response;
	self.status = SDDownloadStatusRunning;
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length {
	_downloadedBytes += length;
	// TODO: Throttle?
}

- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
	return NO;
}

- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)response fromByte:(long long)startingByte {
	// We already know the size, so we do not need to recalculate it.
	self.URLResponse = response;
	self.startedFromByte = startingByte;
	self.status = SDDownloadStatusRunning;
}

- (NSURLRequest *)download:(NSURLDownload *)download willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	// Maybe set our request to the updated request?
	return request;
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
	NSLog(@"Failed with error: %@", error);
	NSInteger errorCode = error.code;

	if((errorCode != NSURLErrorCancelled
	   && errorCode != NSURLErrorBadURL
	   && errorCode != NSURLErrorUnsupportedURL
	   && errorCode != NSURLErrorDataLengthExceedsMaximum
	   && errorCode != NSURLErrorHTTPTooManyRedirects
	   && errorCode != NSURLErrorNotConnectedToInternet
	   && errorCode != NSURLErrorUserCancelledAuthentication
	   && errorCode != NSURLErrorUserAuthenticationRequired
	   && errorCode != NSURLErrorZeroByteResource
	   && errorCode != NSURLErrorNoPermissionsToReadFile
	   && errorCode != NSURLErrorCannotCreateFile
	   && errorCode != NSURLErrorCannotOpenFile
	   && errorCode != NSURLErrorCannotWriteToFile
	   && errorCode != NSURLErrorCannotCloseFile
	   && errorCode != NSURLErrorCannotRemoveFile
	   && errorCode != NSURLErrorCannotMoveFile)
	   && [_delegate downloadShouldRetry:self]) {
		_retryCount++;
		self.status = SDDownloadStatusRetrying;

		float wait = [_delegate retryDelayForDownload:self];
		if(wait > 0.f) {
			// Literally just block the thread until it's our turn.
			usleep((int)(wait * 1000000));
		}
		[self _begin];
	} else {
		self.status = SDDownloadStatusFailed;
		self.finished = YES;
	}
}

- (void)downloadDidFinish:(NSURLDownload *)download {
	NSString *finalDestination4 = [self.path stringByAppendingPathComponent:self.filename];
	[[SDM$SandCastle sharedInstance] createDirectoryAtResolvedPath:self.path];
	[[SDM$SandCastle sharedInstance] moveTemporaryFile:self.temporaryPath toResolvedPath:finalDestination4];
	self.resumeData = nil;
	self.status = SDDownloadStatusCompleted;
	self.finished = YES;
}
/* }}} */

- (void)_deleteData {
	self.resumeData = nil;
	if(self.temporaryPath)
		[[NSFileManager defaultManager] removeItemAtPath:self.temporaryPath error:NULL];
}

- (BOOL)_resume {
	if(!_resumeData) return nil;
	self.temporaryPath = [self _temporaryPathForFilename:self.filename];

	// Truncate the file to the last resume data snapshot.
	[_resumeData setObject:[NSNumber numberWithUnsignedLongLong:_downloadedBytes] forKey:@"NSURLDownloadBytesReceived"];
	truncate([_temporaryPath UTF8String], _downloadedBytes);
	
	NSData *resumeDataSerialization = [NSPropertyListSerialization dataFromPropertyList:_resumeData format:NSPropertyListXMLFormat_v1_0 errorDescription:NULL];
	self.downloader = [[[NSURLDownload alloc] initWithResumeData:resumeDataSerialization delegate:self path:_temporaryPath] autorelease];
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
	if(_filename && _useSuggestedFilename) {
		self.temporaryPath = [self _temporaryPathForFilename:self.filename];
		[_downloader setDestination:self.temporaryPath allowOverwrite:NO];
	}

	self.totalBytes = 0;
	_downloadedBytes = 0;

	return YES;
}

- (void)main {
	NSLog(@"Attempting to begin download.");
	[self _createTemporaryDirectory];
	if([self _begin] == NO) {
		NSLog(@"Begin failed");
		[self complete];
		// TODO: Notify Owner that we Failed.
		return;
	}
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	do {
		[runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
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
