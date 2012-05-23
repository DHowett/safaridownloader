//
//  DownloadManager.m
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "Safari/BrowserController.h"
#import "SDDownloadManager.h"
#import "SDSafariDownload.h"
#import "DownloaderCommon.h"
#import "ModalAlert.h"
#import "SDResources.h"

#import "SDMVersioning.h"
#import "SDMCommonClasses.h"
#import "SDDownloadPromptView.h"
#import "SDFileType.h"
#import "SDUserSettings.h"

#import "SDDownloadModel.h"

#import <SandCastle/SandCastle.h>

#define LOC_ARCHIVE_PATH @"/var/mobile/Library/SDSafariDownloaded.plist"

@implementation SDDownloadManager
@synthesize dataModel = _model, downloadObserver = _downloadObserver;

#pragma mark -
+ (id)uniqueFilenameForFilename:(NSString *)filename atPath:(NSString *)path {
	SandCastle *sc = [SDM$SandCastle sharedInstance];
	NSString *orig_fnpart = [filename stringByDeletingPathExtension];
	NSString *orig_ext = [filename pathExtension];
	int dup = 1;
	while([sc fileExistsAtPath:[path stringByAppendingPathComponent:filename]]
	      || [sc fileExistsAtPath:[kSDSafariDownloadTemporaryDirectory stringByAppendingPathComponent:filename]]) {
		filename = [NSString stringWithFormat:@"%@ (%d)%s%@", orig_fnpart, dup, orig_ext ? "." : "", orig_ext];
		dup++;
	}
	return filename;
}

#pragma mark -
#pragma mark Singleton Methods/*{{{*/
static id sharedManager = nil;

+ (void)initialize  {
	if (self == [SDDownloadManager class]) {
		sharedManager = [[self alloc] init];
	}
}

+ (id)sharedManager {
	return sharedManager;
}

- (id)init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self 
							 selector:@selector(saveData) 
							     name:UIApplicationWillTerminateNotification object:nil];

		[[NSNotificationCenter defaultCenter] addObserver:self 
							 selector:@selector(preferencesReloadedNotification:) 
							     name:kSDUserSettingsReloadedNotification object:nil];
		
		_downloadQueue = [[NSOperationQueue alloc] init];
		[_downloadQueue setMaxConcurrentOperationCount:0];
		
		_model = [[SDDownloadModel alloc] init];
		[_model loadData];
		for(SDSafariDownload *dl in _model.runningDownloads) {
			dl.delegate = self;
			if(dl.status != SDDownloadStatusFailed) // Don't re-enqueue failed downloads.
				[_downloadQueue addOperation:dl];
		}
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone { return self; }
- (id)retain { return self; }
- (unsigned)retainCount { return UINT_MAX; }
- (void)release { }
- (id)autorelease { return self; }

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (NSString*)fileNameForURL:(NSURL*)url {
	NSString *filename = [[[url absoluteString] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	NSRange range = [filename rangeOfString:@"?"];
	if(range.location != NSNotFound)
		filename = [filename substringToIndex:range.location];

	range = [filename rangeOfString:@"&"];
	if(range.location != NSNotFound)
		filename = [filename substringToIndex:range.location];

	if(filename.length == 0
		|| [[filename pathExtension] isEqualToString:@"php"]
		|| [[filename pathExtension] isEqualToString:@"asp"]
		|| [[filename pathExtension] isEqualToString:@"aspx"]
		|| [[filename pathExtension] isEqualToString:@"html"])
		return nil;

	return filename;
}

- (void)preferencesReloadedNotification:(NSNotification *)notification {
	[_downloadQueue setMaxConcurrentOperationCount:[[SDUserSettings sharedInstance] integerForKey:@"MaxConcurrentDownloads" default:5]];
	[SDFileType reloadCustomFileTypes];
}
#pragma mark -/*}}}*/
#pragma mark WebKit WebPolicyDelegate Methods/*{{{*/

// WebPolicyDelegate SDSafariDownloader Addition
- (BOOL) webView:(WebView *)webView 
    decideAction:(NSDictionary*)action
      forRequest:(NSURLRequest *)request 
    withMimeType:(NSString *)mimeType 
	 inFrame:(WebFrame *)frame
    withListener:(id<WebPolicyDecisionListener>)listener
	 context:(id)context {
	NSString *url = [[request URL] absoluteString];
	NSString *scheme = [[request URL] scheme];
	
	if (![scheme hasPrefix:@"http"] && 
			![scheme hasPrefix:@"ftp"]) {
		NSLog(@"not a valid url, continue.");
		return YES;
	}
	
	if (SDDownloadRequest *oldRequest = [SDDownloadRequest pendingRequestForContext:context]) {
		if([oldRequest matchesURLRequest:request]) {
			if(mimeType) {
				// We only do this for mimeType because it is the final request we will receive.
				[oldRequest detachFromContext];
			}
			return YES;
		}
		// The request has changed, so the old request is no longer necessary.
		[oldRequest detachFromContext];
	}

	if ([self supportedRequest:request withMimeType:mimeType]) {
		NSLog(@"WE SUPPORT THE REQUEST: %@", request);
		
		NSString *filename = [self fileNameForURL:[request URL]];
		if (filename == nil) {
			filename = [[request URL] absoluteString];
		}
		
		SDDownloadRequest *downloadRequest = [[SDDownloadRequest alloc] initWithURLRequest:request filename:filename mimeType:mimeType webFrame:frame context:context];
		[downloadRequest attachToContext];

		if(mimeType)
			downloadRequest.supportsViewing = [WebView canShowMIMEType:mimeType];

		[[SDM$BrowserController sharedBrowserController] showBrowserPanelType:SDPanelTypeDownloadPrompt];
		[downloadRequest release];
		return NO;
	} else {
		NSLog(@"Request %@ unsupported", request);
		return YES;
	}
	return YES;
}

#pragma mark - SDDownloadPromptViewDelegate

- (void)downloadPromptView:(SDDownloadPromptView *)promptView didCompleteWithAction:(SDActionType)action {
	SDDownloadRequest *req = [promptView.downloadRequest retain];
	switch(action) {
		case SDActionTypeView:
			[req.webFrame loadRequest:req.urlRequest];
			break;
		case SDActionTypeDownload:
		case SDActionTypeDownloadAs:
			[self addDownloadWithRequest:req.urlRequest andMimeType:req.mimeType browser:action==SDActionTypeDownloadAs];
			[req detachFromContext];
			break;
		default:
		case SDActionTypeNone:
			[req detachFromContext];
			break;
	}
	[req release];
}

#pragma mark -/*}}}*/
#pragma mark Filetype Support Management/*{{{*/

- (BOOL)supportedRequest:(NSURLRequest *)request withMimeType:(NSString *)mimeType {
	if([[SDUserSettings sharedInstance] boolForKey:@"Disabled" default:NO]) return NO;
	SDFileType *fileType = nil;
	NSLog(@"mimetype is %@", mimeType);
	if (mimeType != nil)
		fileType = [SDFileType fileTypeForMIMEType:mimeType];
	if (!fileType) {
		NSString* extension = [[[request URL] absoluteString] pathExtension];
		if (extension) {
			SDFileType *tempFileType = [SDFileType fileTypeForExtension:extension];
			if (tempFileType && (tempFileType.forceExtensionUse || [[SDUserSettings sharedInstance] boolForKey:@"UseExtensions" default:NO]))
				fileType = tempFileType;
		}
	}
	if (fileType) {
		if ([[[SDUserSettings sharedInstance] arrayForKey:@"DisabledItems"] containsObject:fileType.name])
			return NO;
	}
	return fileType != nil;
}

#pragma mark -/*}}}*/
#pragma mark Download Management/*{{{*/

- (SDSafariDownload *)downloadWithURL:(NSURL*)url {
	return [_model downloadWithURL:url];
}

- (void)fileBrowser:(YFFileBrowser*)browser 
			didSelectPath:(NSString*)path 
						forFile:(id)file 
				withContext:(id)dl {
	SDSafariDownload* download = (SDSafariDownload*)dl;
	download.path = path;
	download.filename = [SDDownloadManager uniqueFilenameForFilename:download.filename atPath:download.path];
	[_downloadQueue addOperation:download];
	
	[_model addDownload:download toList:SDDownloadModelRunningList];

	// this should only be owned by the array
#warning the fuck?
	[download release];
}

- (void)fileBrowserDidCancel:(YFFileBrowser*)browser {
	NSLog(@"fileBrowserDidCancel");
}

// everything eventually goes through this method
- (BOOL)addDownload:(SDSafariDownload*)download browser:(BOOL)browser {
	//if (![_currentDownloads containsObject:download]) {
	if (browser) {
		YFFileBrowser* f = [[YFFileBrowser alloc] initWithFile:download.filename 
							       context:download
							      delegate:self];
		[f show];
		[f release];
	}
	else {
		[self fileBrowser:nil 
			didSelectPath:@"/var/mobile/Media/Downloads" 
				forFile:download.filename 
			withContext:download];
	}
	
		return YES;
	//}
	//return NO;
}

- (BOOL)addDownloadWithRequest:(NSURLRequest*)request 
		   andMimeType:(NSString *)mimeType 
		       browser:(BOOL)browser {
	if ([self downloadWithURL:[request URL]] != nil)
		return NO;

	NSString *filename = [self fileNameForURL:[request URL]];
	
	SDSafariDownload *download = [[SDSafariDownload alloc] init];
	download.URLRequest = request;
	download.filename = filename;
	download.mimeType = mimeType;
	download.delegate = self;
	return [self addDownload:download browser:browser];
}

// everything eventually goes through this method
- (BOOL)cancelDownload:(SDSafariDownload *)download {
	if (download != nil) {
		[download cancel];
		[_model removeDownload:download fromList:SDDownloadModelRunningList];
		[self updateBadges];
	}
	return NO;
}

- (void)retryDownload:(SDSafariDownload *)download {
	SDSafariDownload *newDownload = [[[SDSafariDownload alloc] initWithDownload:download] autorelease];
	download.useSuggestedFilename = YES;
	[_model removeDownload:download fromList:SDDownloadModelFinishedList];
	[_downloadQueue addOperation:newDownload];
	[_model addDownload:newDownload toList:SDDownloadModelRunningList];
}

- (void)deleteDownload:(SDSafariDownload*)download {
	[download retain];
	[_model removeDownload:download fromList:SDDownloadModelFinishedList];
	[[objc_getClass("SandCastle") sharedInstance] removeItemAtResolvedPath:[download.path stringByAppendingPathComponent:download.filename]];
	[download release];
}

- (void)cancelAllDownloads {
	[_downloadQueue cancelAllOperations];
	[_model emptyList:SDDownloadModelRunningList];
}

#pragma mark -/*}}}*/
#pragma mark SDSafariDownloadDelegate Methods/*{{{*/

- (void)downloadDidChangeStatus:(SDSafariDownload *)download {
	NSLog(@"Got status for download! %d", download.status);
	if(download.status == SDDownloadStatusCompleted
	   || download.status == SDDownloadStatusFailed) {
		[_model moveDownload:download toList:SDDownloadModelFinishedList]; // Implicit save.
	} else if([_model.finishedDownloads indexOfObjectIdenticalTo:download] != NSNotFound
		&& (download.status == SDDownloadStatusFailed
		|| download.status == SDDownloadStatusCompleted)) { // If it's in the finished list, but transitioning to a non-finished state.
		[_model moveDownload:download toList:SDDownloadModelRunningList]; // Implicit save.
	} else {
		[_model saveData];
	}
	[_downloadObserver downloadDidChangeStatus:download];
	//[_model downloadUpdated:download];
	// waiting, authenticationwaiting, running, paused, completed, cancelled, failed
	// auth challenge handled by other delegate method
	// completed: badges, UI, remove from operation queue possibly
	// running: badges, ui
	 // paused: is this a thing?
      // cancelled: remove completely?
	 // failed: drop everything and run away.
}

- (void)downloadDidProvideFilename:(SDSafariDownload *)download {
	NSLog(@"Got filename for download! %@", download.filename);
	[_downloadObserver downloadDidProvideFilename:download];
	[_model saveData];
}

- (void)downloadDidProvideSize:(SDSafariDownload *)download {
	[_downloadObserver downloadDidProvideSize:download];
	[_model saveData];
}

- (NSString *)uniqueFilenameForDownload:(SDSafariDownload *)download withSuggestion:(NSString *)suggestedFilename {
	return [[self class] uniqueFilenameForFilename:suggestedFilename atPath:download.path];
}

- (BOOL)downloadShouldRetry:(SDSafariDownload *)download {
	return !([[SDUserSettings sharedInstance] boolForKey:@"AutoRetryDisabled" default:NO])
	       && (unsigned int)[[SDUserSettings sharedInstance] integerForKey:@"AutoRetryCount" default:3] > download.retryCount;	
}

- (float)retryDelayForDownload:(SDSafariDownload *)download {
	return [[SDUserSettings sharedInstance] floatForKey:@"AutoRetryInterval" default:1.f];
}

- (void)downloadDidReceiveData:(SDSafariDownload *)download {
	//[_downloadObserver downloadDidReceiveData:download];
}

- (void)_handleAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	[[SDM$BrowserController sharedBrowserController] _addAuthenticationChallenge:challenge displayNow:YES];
}

- (void)download:(SDSafariDownload *)download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	[self performSelectorOnMainThread:@selector(_handleAuthenticationChallenge:) withObject:challenge waitUntilDone:NO];
}

#pragma mark -/*}}}*/

- (void)updateBadges {
	/*
	NSString *val = nil;
	if(_currentDownloads.count > 0) val = [NSString stringWithFormat:@"%d", _currentDownloads.count];
	[_portraitDownloadButton _setBadgeValue:val];
	[_landscapeDownloadButton _setBadgeValue:val];
	*/
	//[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}
@end

// vim:filetype=objc:ts=8:sw=8:noexpandtab
