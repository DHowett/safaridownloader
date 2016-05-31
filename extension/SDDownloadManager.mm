//
//  DownloadManager.m
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "SDMCommon.h"
#import "SDMVersioning.h"
#import "Safari/BrowserController.h"
#import "SDDownloadManager.h"
#import "SDSafariDownload.h"
#import "SDResources.h"

#import "SDFileType.h"
#import "SDUserSettings.h"

#import "SDDownloadModel.h"

#import <SandCastle/SandCastle.h>

static const NSString *const kSDMAssociatedIgnoreRequestKey = @"kSDMAssociatedIgnoreRequestKey";
NSString * const kSDMAssociatedOverrideAuthenticationChallenge = @"kSDMAssociatedOverrideAuthenticationChallenge";

@interface BrowserController (Additions)
- (void)_addAuthenticationChallenge:(id)challenge displayNow:(BOOL)now;
- (void)_sdmUpdateBadge:(NSString *)badge;
@end

@interface SDDownloadManager ()
- (void)_updateBadges;
@end

@implementation SDDownloadManager
@synthesize dataModel = _model, downloadObserver = _downloadObserver, authenticationManager = _authenticationManager;

#pragma mark -
+ (id)uniqueFilenameForFilename:(NSString *)filename atPath:(NSString *)path {
	NSString *orig_fnpart = [filename stringByDeletingPathExtension];
	NSString *orig_ext = [filename pathExtension];
	int dup = 1;
	while([SandCastle fileExistsAtPath:[path stringByAppendingPathComponent:filename]]
	      || [SandCastle fileExistsAtPath:[kSDSafariDownloadTemporaryDirectory stringByAppendingPathComponent:filename]]) {
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
		[self _updateBadges];
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
	[_authenticationManager release];
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

	if(filename.length == 0) return nil;

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
	NSString *scheme = [[request URL] scheme];

	NSNumber *navigationTypeObject = [action objectForKey:WebActionNavigationTypeKey];
	if(navigationTypeObject) {
		int navigationType = [navigationTypeObject intValue];
		// Don't prompt to download later if this is a navigation/loading action.
		if(navigationType == WebNavigationTypeBackForward
		|| navigationType == WebNavigationTypeReload) {
			objc_setAssociatedObject(context, kSDMAssociatedIgnoreRequestKey, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		}
		return YES;
	}

	if([objc_getAssociatedObject(context, kSDMAssociatedIgnoreRequestKey) boolValue]) {
		objc_setAssociatedObject(context, kSDMAssociatedIgnoreRequestKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		return YES;
	}

	
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
		downloadRequest.savePath = (NSString *)[[SDUserSettings sharedInstance] objectForKey:@"DefaultDownloadDirectory" default:[NSHomeDirectory() stringByAppendingPathComponent:@"Media/Downloads"]];
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

- (SDDownloadRequest *)downloadRequestForImmediateURLRequest:(NSURLRequest *)request context:(id)context {
	NSString *filename = [self fileNameForURL:[request URL]];
	if (filename == nil) {
		filename = [[request URL] absoluteString];
	}
	
	SDDownloadRequest *downloadRequest = [[SDDownloadRequest alloc] initWithURLRequest:request filename:filename mimeType:nil webFrame:nil context:context];
	downloadRequest.savePath = (NSString *)[[SDUserSettings sharedInstance] objectForKey:@"LastUsedImmediateDownloadDirectory" default:[NSHomeDirectory() stringByAppendingPathComponent:@"Media/Downloads"]];
	[downloadRequest attachToContext];
	return downloadRequest;
}

#pragma mark - SDDownloadPromptDelegate

- (void)downloadPrompt:(NSObject<SDDownloadPrompt> *)downloadPrompt didCompleteWithAction:(SDActionType)action {
	SDDownloadRequest *req = [downloadPrompt.downloadRequest retain];
	switch(action) {
		case SDActionTypeView:
			[req.webFrame loadRequest:req.urlRequest];
			break;
		case SDActionTypeDownload:
		case SDActionTypeDownloadAs:
			[self addDownloadFromDownloadRequest:req];
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
	if(![[SDUserSettings sharedInstance] boolForKey:@"Enabled" default:YES]) return NO;
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
		NSNumber *preferredAction = [(NSDictionary *)[[SDUserSettings sharedInstance] objectForKey:@"FileActions" default:nil] objectForKey:[fileType primaryMIMEType]];
		SDFileTypeAction fileAction;
		if(!preferredAction) fileAction = [fileType defaultAction];
		else fileAction = (SDFileTypeAction)[preferredAction intValue];
		return fileAction == SDFileTypeActionDownload;
	}
	return fileType != nil;
}

#pragma mark -/*}}}*/
#pragma mark Download Management/*{{{*/

- (SDSafariDownload *)downloadWithURL:(NSURL*)url {
	return [_model downloadWithURL:url];
}

- (void)addDownloadFromDownloadRequest:(SDDownloadRequest *)downloadRequest {
	SDSafariDownload *download = [[SDSafariDownload alloc] init];
	download.URLRequest = downloadRequest.urlRequest;
	download.mimeType = downloadRequest.mimeType;
	download.path = downloadRequest.savePath;
	@synchronized([SDSafariDownload fileManager]) {
		download.filename = [SDDownloadManager uniqueFilenameForFilename:downloadRequest.filename atPath:downloadRequest.savePath];
	}
	download.delegate = self;

	[_downloadQueue addOperation:download];
	[_model addDownload:download toList:SDDownloadModelRunningList];
	[self _updateBadges];

	[download release];
}

// everything eventually goes through this method
- (BOOL)cancelDownload:(SDSafariDownload *)download {
	if (download != nil) {
		[download cancel];
		[_model removeDownload:download fromList:SDDownloadModelRunningList];
		[self _updateBadges];
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
	[SandCastle removeItemAtResolvedPath:[download.path stringByAppendingPathComponent:download.filename]];
	[download release];
}

- (void)cancelAllDownloads {
	[_downloadQueue cancelAllOperations];
	[_model emptyList:SDDownloadModelRunningList];
}

#pragma mark -/*}}}*/
#pragma mark SDFileBrowserDelegate Methods/*{{{*/

- (void)fileBrowserDidCancel:(SDFileBrowserNavigationController *)fileBrowser {
	[fileBrowser.downloadRequest detachFromContext];
	[fileBrowser close];
}

- (void)fileBrowser:(SDFileBrowserNavigationController *)fileBrowser didSelectPath:(NSString *)path {
	fileBrowser.downloadRequest.savePath = path;
	[[SDUserSettings sharedInstance] setObject:path forKey:@"LastUsedImmediateDownloadDirectory"];
	[[SDUserSettings sharedInstance] commit];
	[self addDownloadFromDownloadRequest:fileBrowser.downloadRequest];
	[fileBrowser.downloadRequest detachFromContext];
	[fileBrowser close];
}

#pragma mark -/*}}}*/
#pragma mark SDSafariDownloadDelegate Methods/*{{{*/

- (void)downloadDidChangeStatus:(SDSafariDownload *)download {
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
	[self _updateBadges];
	//[_model downloadUpdated:download];
	// waiting, authenticationwaiting, running, paused, completed, cancelled, failed
	// auth challenge handled by other delegate method
	// completed: badges, UI, remove from operation queue possibly
	// running: badges, ui
	 // paused: is this a thing?
      // cancelled: remove completely?
	 // failed: drop everything and run away.
}

- (void)downloadDidUpdateMetadata:(SDSafariDownload *)download {
	[_downloadObserver downloadDidUpdateMetadata:download];
	[_model saveData];
}

- (NSString *)uniqueFilenameForDownload:(SDSafariDownload *)download withSuggestion:(NSString *)suggestedFilename {
	return [[self class] uniqueFilenameForFilename:suggestedFilename atPath:download.path];
}

- (BOOL)downloadShouldRetry:(SDSafariDownload *)download {
	return ([[SDUserSettings sharedInstance] boolForKey:@"AutoRetryEnabled" default:YES])
	       && (unsigned int)[[SDUserSettings sharedInstance] integerForKey:@"AutoRetryCount" default:3] > download.retryCount;	
}

- (float)retryDelayForDownload:(SDSafariDownload *)download {
	return [[SDUserSettings sharedInstance] floatForKey:@"AutoRetryInterval" default:1.f];
}

- (void)downloadDidReceiveData:(SDSafariDownload *)download {
	//[_downloadObserver downloadDidReceiveData:download];
}

- (void)_handleAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if([SDM$BrowserController instancesRespondToSelector:@selector(_addAuthenticationChallenge:displayNow:)]) {
		// New method.
		[[SDM$BrowserController sharedBrowserController] _addAuthenticationChallenge:challenge displayNow:YES];
	} else if([objc_getClass("WebUIAuthenticationManager") instancesRespondToSelector:@selector(addAuthenticationChallenge:displayPanel:)]) {
		// Old method.
		if(!self.authenticationManager) {
			self.authenticationManager = [[objc_getClass("WebUIAuthenticationManager") alloc] init];
		}
		[self.authenticationManager setDelegate:self];
		[self.authenticationManager addAuthenticationChallenge:challenge displayPanel:YES];
	} else {
		// Oldest method.
		objc_setAssociatedObject([SDM$BrowserController sharedBrowserController], kSDMAssociatedOverrideAuthenticationChallenge, challenge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		[[SDM$BrowserController sharedBrowserController] showBrowserPanelType:5];

	}
}

/* WebUIAuthenticationManager Delegate {{{ */
- (void)cancelFromAuthenticationManager:(WebUIAuthenticationManager *)authenticationManager forChallenge:(NSURLAuthenticationChallenge *)challenge {
	[[challenge sender] cancelAuthenticationChallenge:challenge];
}

- (void)logInFromAuthenticationManager:(WebUIAuthenticationManager *)authenticationManager withCredential:(NSURLCredential *)credential forChallenge:(NSURLAuthenticationChallenge *)challenge {
	[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
}
/* }}} */

- (void)download:(SDSafariDownload *)download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	[self performSelectorOnMainThread:@selector(_handleAuthenticationChallenge:) withObject:challenge waitUntilDone:NO];
}

#pragma mark -/*}}}*/

- (int)downloadsRunning {
	return _model.runningDownloads.count;
}

- (void)_updateBadges {
	NSString *valueString = nil;
	if(_model.runningDownloads.count > 0) valueString = [NSString stringWithFormat:@"%d", _model.runningDownloads.count];
	[[SDM$BrowserController sharedBrowserController] _sdmUpdateBadge:valueString];
}
@end

// vim:filetype=objc:ts=8:sw=8:noexpandtab
