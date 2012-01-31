//
//  DownloadManager.m
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//
#import "DHHookCommon.h"
#import <QuartzCore/QuartzCore.h>
#import "Safari/BrowserController.h"
#import "DownloadManager.h"
#import "DownloadCell.h"
#import "DownloaderCommon.h"
#import "ModalAlert.h"
#import "SDResources.h"

#import "SDMVersioning.h"
#import "SDMCommonClasses.h"
#import "SDDownloadPromptView.h"
#import "SDFileType.h"

#import <SandCastle/SandCastle.h>

#define DL_ARCHIVE_PATH @"/var/mobile/Library/SDSafariDownloading.plist"
#define LOC_ARCHIVE_PATH @"/var/mobile/Library/SDSafariDownloaded.plist"

@interface UIDevice (Wildcat)
- (BOOL)isWildcat;
@end

@interface UIApplication (Safari)
- (void)applicationOpenURL:(id)url;
@end

@implementation SDFileBrowserPanel
- (BOOL)allowsRotation { return NO; }
- (BOOL)pausesPages { return NO; }
- (int)panelType { return 45; }
- (int)panelState { return 1; }
@end

@implementation SDDownloadManager
@synthesize 
portraitDownloadButton = _portraitDownloadButton,
landscapeDownloadButton = _landscapeDownloadButton,
userPrefs = _userPrefs,
visible = _visible,
loadingURL = _loadingURL,
currentSelectedIndexPath = _currentSelectedIndexPath;

#pragma mark -
+ (id)uniqueFilenameForFilename:(NSString *)filename atPath:(NSString *)path {
  Class $SandCastle = objc_getClass("SandCastle");
  SandCastle *sc = [$SandCastle sharedInstance];
  NSString *orig_fnpart = [filename stringByDeletingPathExtension];
  NSString *orig_ext = [filename pathExtension];
  int dup = 1;
  while([sc fileExistsAtPath:[path stringByAppendingPathComponent:filename]]) {
    filename = [NSString stringWithFormat:@"%@-%d%s%@", orig_fnpart, dup, orig_ext ? "." : "", orig_ext];
    dup++;
  }
  return filename;
}

#pragma mark -
#pragma mark Singleton Methods/*{{{*/
static id sharedManager = nil;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inter {
  return YES;
}

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
	
	[self updateUserPreferences];

	NSNumber* maxdownobj = [_userPrefs objectForKey:@"MaxConcurrentDownloads"];
	NSInteger maxdown = (maxdownobj!=nil) ? [maxdownobj intValue] : 5;
	
	_downloadQueue = [NSOperationQueue new];
  [_downloadQueue setMaxConcurrentOperationCount:maxdown];
	
	NSString* tempDL = [@"/tmp" stringByAppendingPathComponent:[DL_ARCHIVE_PATH lastPathComponent]];
	[[objc_getClass("SandCastle") sharedInstance] copyItemAtPath:DL_ARCHIVE_PATH toPath:tempDL];
	
	NSString* tempLOC = [@"/tmp" stringByAppendingPathComponent:[LOC_ARCHIVE_PATH lastPathComponent]];
	[[objc_getClass("SandCastle") sharedInstance] copyItemAtPath:LOC_ARCHIVE_PATH toPath:tempLOC];
	
	@try {
	  _currentDownloads = [[NSKeyedUnarchiver unarchiveObjectWithFile:tempDL] retain];
	}
	@catch (id nothing) {
	  _currentDownloads = nil;
	  NSLog(@"corrupt data");
	}
	
	//NSLog(@"Got CurrentDownloads: %@", _currentDownloads);
	if (!_currentDownloads)
	  _currentDownloads = [[NSMutableArray alloc] init];
	
	for (SDSafariDownload *dl in _currentDownloads) {
	  [dl setDelegate:self];
	  SDDownloadOperation *op = [[SDDownloadOperation alloc] initWithDelegate:dl];
	  dl.downloadOperation = op;
	  [_downloadQueue addOperation:op];
	  [op release];
	}
	
	@try {
	  _finishedDownloads = [[NSKeyedUnarchiver unarchiveObjectWithFile:tempLOC] retain];
	}
	@catch (id nothing) {
	  _finishedDownloads = nil;
	  NSLog(@"corrupt data");
	}
	
	//NSLog(@"Got FinishedDownloads: %@", _finishedDownloads);
	if (_finishedDownloads == nil)
	  _finishedDownloads = [[NSMutableArray alloc] init];
	
    [self updateFileTypes];
    _visible = NO;
  }
  return self;
}

- (void)loadView { 
  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear All" 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:self 
                                                                  action:@selector(clearAllDownloads)];
  self.navigationItem.rightBarButtonItem = cancelButton;
  self.navigationItem.rightBarButtonItem.enabled = YES;
  
  if(![UIDevice instancesRespondToSelector:@selector(isWildcat)] || ![[UIDevice currentDevice] isWildcat]) {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" 
                                                                   style:UIBarButtonItemStyleDone 
                                                                  target:[self navigationController]
                                                                  action:@selector(close)];
    self.navigationItem.leftBarButtonItem = doneButton;
    self.navigationItem.leftBarButtonItem.enabled = YES;
  }
  
  _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.rowHeight = 56;
  self.view = _tableView;
}

- (id)copyWithZone:(NSZone *)zone { return self; }
- (id)retain { return self; }
- (unsigned)retainCount { return UINT_MAX; }
- (void)release { }
- (id)autorelease { return self; }

- (void)dealloc {
  [_currentSelectedIndexPath release];
  [super dealloc];
}

- (NSString*)fileNameForURL:(NSURL*)url {
  NSString *filename = [[[url absoluteString] lastPathComponent] 
                        stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  NSRange range = [filename rangeOfString: @"?"];
  if (range.location != NSNotFound)
    filename = [filename substringToIndex:range.location];
  range = [filename rangeOfString: @"&"];
  if (range.location != NSNotFound)
    filename = [filename substringToIndex:range.location];
  if (filename.length == 0 || 
      [[filename pathExtension] isEqualToString:@"php"]  ||
      [[filename pathExtension] isEqualToString:@"asp"]  ||
      [[filename pathExtension] isEqualToString:@"aspx"] ||
      [[filename pathExtension] isEqualToString:@"html"])
    return nil;
  return filename;
}

- (void)updateUserPreferences {
  self.userPrefs = [NSDictionary dictionaryWithContentsOfFile:PREFERENCES_FILE];
	NSNumber* maxdownobj = [_userPrefs objectForKey:@"MaxConcurrentDownloads"];
	NSInteger maxdown = (maxdownobj!=nil) ? [maxdownobj intValue] : 5;
  [_downloadQueue setMaxConcurrentOperationCount:maxdown];
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
  
  if (![url hasPrefix:@"http://"] && 
      ![url hasPrefix:@"https://"] && 
      ![url hasPrefix:@"ftp://"]) {
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
  }
  else {
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
      if (req.mimeType != nil)
        [self addDownloadWithRequest:req.urlRequest andMimeType:req.mimeType browser:action==SDActionTypeDownloadAs];
      else
        [self addDownloadWithRequest:req.urlRequest browser:action==SDActionTypeDownloadAs];
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

- (void)updateFileTypes {
  return;
  NSDictionary *customTypes = [_userPrefs objectForKey:@"CustomItems"];
}

- (BOOL)supportedRequest:(NSURLRequest *)request withMimeType:(NSString *)mimeType {
  if([[_userPrefs objectForKey:@"Disabled"] boolValue]) return NO;
  SDFileType *fileType = nil;
  NSLog(@"mimetype is %@", mimeType);
  if (mimeType != nil)
    fileType = [SDFileType fileTypeForMIMEType:mimeType];
  if (!fileType) {
    NSString* extension = [[[request URL] absoluteString] pathExtension];
    if (extension) {
      SDFileType *tempFileType = [SDFileType fileTypeForExtension:extension];
      if (tempFileType && (tempFileType.forceExtensionUse || [[_userPrefs objectForKey:@"UseExtensions"] boolValue]))
        fileType = tempFileType;
    }
  }
  if (fileType) {
    if ([[_userPrefs objectForKey:@"DisabledItems"] containsObject:fileType.name])
      return NO;
  }
  return fileType != nil;
}

#pragma mark -/*}}}*/
#pragma mark Persistent Storage/*{{{*/

- (void)saveData {
  NSString* tempLOC = [@"/tmp" stringByAppendingPathComponent:[LOC_ARCHIVE_PATH lastPathComponent]];
  NSData* loc = [NSKeyedArchiver archivedDataWithRootObject:_finishedDownloads];
  if (loc) {
	[loc writeToFile:tempLOC atomically:NO];
	[[objc_getClass("SandCastle") sharedInstance] copyItemAtPath:tempLOC toPath:LOC_ARCHIVE_PATH];
  }
  
  NSString* tempDL = [@"/tmp" stringByAppendingPathComponent:[DL_ARCHIVE_PATH lastPathComponent]];
  NSData* dl = [NSKeyedArchiver archivedDataWithRootObject:_currentDownloads];
  if (dl) {
	NSLog(@"archiving to path: %@", tempDL);
	[dl writeToFile:tempDL atomically:NO];
	[[objc_getClass("SandCastle") sharedInstance] copyItemAtPath:tempDL toPath:DL_ARCHIVE_PATH];
  }
}

#pragma mark -

#pragma mark -/*}}}*/
#pragma mark Download Management/*{{{*/

- (SDSafariDownload *)downloadWithURL:(NSURL*)url {
  for (SDSafariDownload *download in _currentDownloads) {
    if ([[download.urlReq URL] isEqual:url])
      return download;
  }
  return nil; 
}

- (void)fileBrowser:(YFFileBrowser*)browser 
      didSelectPath:(NSString*)path 
            forFile:(id)file 
        withContext:(id)dl {
  SDSafariDownload* download = (SDSafariDownload*)dl;
  SDDownloadOperation *op = [[SDDownloadOperation alloc] initWithDelegate:download];
  download.downloadOperation = op;
  download.savePath = path;
  download.filename = [SDDownloadManager uniqueFilenameForFilename:download.filename atPath:download.savePath];
  [_downloadQueue addOperation:op];
  [op release];
  
  [_currentDownloads addObject:download];
  if (_currentDownloads.count == 1) {
    [_tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
  } 
  else {
    [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_currentDownloads.count-1 inSection:0]] 
                      withRowAnimation:UITableViewRowAnimationFade];
  }

  // this should only be owned by the array
  [download release];
}

- (void)fileBrowserDidCancel:(YFFileBrowser*)browser {
  NSLog(@"fileBrowserDidCancel");
}

// everything eventually goes through this method
- (BOOL)addDownload:(SDSafariDownload*)download browser:(BOOL)browser {
  if (![_currentDownloads containsObject:download]) {
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
  }
  return NO;
}

- (BOOL)addDownloadWithURL:(NSURL*)url browser:(BOOL)browser {
  if ([self downloadWithURL:url])
    return NO;
  
  BOOL use = NO;
  NSString *filename = [self fileNameForURL:url];
  if (filename == nil) {
    filename = [url absoluteString];
    use = YES;
  }
  
  SDSafariDownload* download = [[SDSafariDownload alloc] initWithRequest:[NSURLRequest requestWithURL:url]
																	name:filename
																delegate:self
															useSuggested:use];
  
  return [self addDownload:download browser:browser];
}

- (BOOL)addDownloadWithRequest:(NSURLRequest*)request browser:(BOOL)browser {
  BOOL use = NO;
  NSString *filename = [self fileNameForURL:[request URL]];
  if (filename == nil) {
    filename = [[request URL] absoluteString];
    use = YES;
  }
  
  if ([self downloadWithURL:[request URL]])
    return NO;
  
  SDSafariDownload* download = [[SDSafariDownload alloc] initWithRequest:request
																	name:filename
																delegate:self
															useSuggested:use];
  return [self addDownload:download browser:browser];
}

- (BOOL)addDownloadWithRequest:(NSURLRequest*)request 
						 andMimeType:(NSString *)mimeType 
							  browser:(BOOL)browser {
  BOOL use = NO;
  NSString *filename = [self fileNameForURL:[request URL]];
  if (filename == nil) {
    filename = [[request URL] absoluteString];
    use = YES;
  }
  
  if ([self downloadWithURL:[request URL]])
    return NO;
  
  SDSafariDownload* download = [[SDSafariDownload alloc] initWithRequest:request
																						  name:filename
																					 delegate:self
																				useSuggested:use];
  download.mimetype = mimeType;
  return [self addDownload:download browser:browser];
}

- (BOOL)addDownloadWithInfo:(NSDictionary*)info browser:(BOOL)b {
  NSURLRequest*   request  = [info objectForKey:@"request"];
  if ([self downloadWithURL:[request URL]])
    return NO;
  
  SDSafariDownload* download = [[SDSafariDownload alloc] initWithRequest:request
																	name:[info objectForKey:@"name"]
																delegate:self
															useSuggested:NO];
  return [self addDownload:download browser:b];
}

// everything eventually goes through this method
- (BOOL)cancelDownload:(SDSafariDownload *)download {
  if (download != nil) {
    @try {
      SDDownloadOperation *op = download.downloadOperation;
      [op cancel];
      download.downloadOperation = nil;
    }
    @catch (id nothing) { 
      NSLog(@"exception caught attempting to cancel operation"); 
    }
    
    NSUInteger row = [_currentDownloads indexOfObject:download];
    [_currentDownloads removeObject:download];
    
    if (_currentDownloads.count == 0) {
      [_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] 
					 withRowAnimation:UITableViewRowAnimationFade];
    } 
    else {
      [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self updateBadges];
  }
  return NO;
}

- (BOOL)cancelDownloadWithURL:(NSURL *)url
{
  if ([self cancelDownload:[self downloadWithURL:url]])
    return YES;
  return NO; 
}

- (void)deleteDownload:(SDSafariDownload*)download {
  
}

- (void)cancelAllDownloads {
  UIAlertView* alert = nil;
  if (_currentDownloads.count > 0) {
    alert = [[UIAlertView alloc] initWithTitle:@"Cancel All Downloads?"
                                       message:nil
                                      delegate:self
                             cancelButtonTitle:@"No"
                             otherButtonTitles:@"Yes", nil];
  }
  else {
    alert = [[UIAlertView alloc] initWithTitle:@"Nothing to Cancel"
                                       message:nil
                                      delegate:self
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
  }
  
  [alert show];
  [alert release];
}

- (void)clearAllDownloads {
  NSLog(@"clearAllDownloads!"); 
  [_finishedDownloads removeAllObjects];
  [self saveData];
  [_tableView reloadData];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {
    if (_currentDownloads.count > 0) {
      [_downloadQueue cancelAllOperations];
      [_currentDownloads removeAllObjects];
		[self saveData];
      [_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
  } 
}

- (SDDownloadCell*)cellForDownload:(SDSafariDownload*)download {
  NSUInteger row = [_currentDownloads indexOfObject:download];
  SDDownloadCell *cell = (SDDownloadCell*)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
  return cell;
}

#pragma mark -/*}}}*/
#pragma mark SDSafariDownloadDelegate Methods/*{{{*/

- (void)downloadDidBegin:(SDSafariDownload*)download {
  NSLog(@"DownloadManager downloadDidBegin: %@", download);
  [self updateBadges];
  SDDownloadCell *cell = [self cellForDownload:download];
  cell.nameLabel = download.filename;
  cell.progressLabel = @"Downloading...";
  cell.completionLabel = @"0%";
  [self saveData];
}

- (void)downloadDidReceiveAuthenticationChallenge:(SDSafariDownload *)download {
  SDDownloadCell *cell = [self cellForDownload:download];
  cell.progressLabel = @"Awaiting Authentication...";
}

- (void)downloadDidProvideFilename:(SDSafariDownload*)download {
  SDDownloadCell *cell = [self cellForDownload:download];
  cell.nameLabel = download.filename;
  [self saveData];
}

- (void)downloadDidFinish:(SDSafariDownload*)download {
  NSLog(@"downloadDidFinish");
  SDDownloadCell* cell = [self cellForDownload:download];
  
  download.downloadOperation = nil; // no-op atm
  // no need to update this here, it happens in cellFor...
  //cell.progressLabel = download.savePath;
  NSUInteger row = [_currentDownloads indexOfObject:download];
  [download retain];
  [_currentDownloads removeObject:download];
  [_finishedDownloads addObject:download];
  [download release];
  
  [self updateBadges];
  [self saveData];
  
  if (cell == nil) {
    NSLog(@"cell is nil!");
    return;
  }
  
  [_tableView beginUpdates];
  {
    if (_currentDownloads.count == 0) {
      [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_finishedDownloads.count-1 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
      [_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } 
    else {
      [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
      [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_finishedDownloads.count-1 inSection:1]]
                        withRowAnimation:UITableViewRowAnimationFade];
    }
  }
  [_tableView endUpdates];
}

// not used, too much of an overhead :<
- (void)updateProgressForDownload:(SDSafariDownload*)download {
  SDDownloadCell* cell = [self cellForDownload:download];
  float progress = cell.progressView.progress;
  progress += (download.progress - progress)/4;
  cell.progressView.progress = progress;
  if (progress < download.progress) { // :o recursive method with delay :o
    [self performSelector:@selector(updateProgressForDownload:) 
               withObject:download 
               afterDelay:0.1];
  }
}

- (void)downloadWillRetry:(SDSafariDownload*)download {
  SDDownloadCell* cell = [self cellForDownload:download];
  cell.progressView.progress = 0.0f;
  cell.progressLabel = download.timeString;
}

- (void)downloadDidUpdate:(SDSafariDownload*)download {
  SDDownloadCell* cell = [self cellForDownload:download];
  cell.progressView.progress = download.progress;
  cell.completionLabel = [NSString stringWithFormat:@"%d%%", (int)(download.progress*100.0f)];
  cell.progressLabel = [NSString stringWithFormat:@"Downloading @ %.1fKB/sec", download.speed];
  cell.sizeLabel = download.sizeString;
}

- (void)downloadDidCancel:(SDSafariDownload*)download {   
  [self updateBadges];
  [self saveData];  
  download.downloadOperation = nil;
}

- (void)downloadDidFail:(SDSafariDownload*)download {
  NSLog(@"downloadDidFail");
  SDDownloadCell* cell = [self cellForDownload:download];
  
  download.downloadOperation = nil;
  cell.progressLabel = @"Download Failed";
  NSUInteger row = [_currentDownloads indexOfObject:download];
  [download retain];
  [_currentDownloads removeObject:download];
  [_finishedDownloads addObject:download];
  [download release];
  
  [self updateBadges];
  [self saveData];
  
  if (cell == nil) {
    return;
  }
  
  [_tableView beginUpdates];
  {
    if (_currentDownloads.count == 0) {
      [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_finishedDownloads.count-1 inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
      [_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } 
    else {
      [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
      [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_finishedDownloads.count-1 inSection:1]]
                        withRowAnimation:UITableViewRowAnimationFade];
    }
  }
  [_tableView endUpdates];
}

#pragma mark -/*}}}*/
#pragma mark UIViewController Methods/*{{{*/

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning]; 
}

- (void)viewDidLoad {
  [super viewDidLoad]; 
}

- (void)viewDidUnload {
  [super viewDidUnload]; 
}

- (void)viewWillAppear:(BOOL)animated {
  [_tableView reloadData];
  [super viewWillAppear:animated];
}

- (id)title {
  return @"Downloads";
}

#pragma mark -/*}}}*/
#pragma mark UITableView methods/*{{{*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (_currentDownloads.count > 0) {
	self.navigationItem.rightBarButtonItem.title = @"Cancel All";
	self.navigationItem.rightBarButtonItem.action = @selector(cancelAllDownloads);
	return 2;
  }
  else {
	self.navigationItem.rightBarButtonItem.title = @"Clear All";
	self.navigationItem.rightBarButtonItem.action = @selector(clearAllDownloads);
	return 1;
  }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (tableView.numberOfSections == 2 && section == 0)
    return @"Active Downloads";
  else
    return @"Finished Downloads";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (tableView.numberOfSections == 2 && section == 0)
    return [_currentDownloads count];
  else
    return [_finishedDownloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"SDDownloadCell";
  BOOL finished = NO;
  SDSafariDownload *download = nil;
  
  if(tableView.numberOfSections == 2 && indexPath.section == 0) {
    download = [_currentDownloads objectAtIndex:indexPath.row];
    finished = NO;
  } else {
    CellIdentifier = @"FinishedSDDownloadCell";
    download = [_finishedDownloads objectAtIndex:indexPath.row];
    finished = YES;
  }
  
  SDDownloadCell *cell = (SDDownloadCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[SDDownloadCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
  }
  
  // Set up the cell...
  cell.finished = finished;
  cell.failed = download.failed;
  cell.icon = [SDResources iconForFileType:[SDFileType fileTypeForExtension:[download.filename pathExtension] orMIMEType:download.mimetype]];
  cell.nameLabel = download.filename;
  cell.sizeLabel = download.sizeString;
  if(!finished && !download.failed) {
    if([download.downloadOperation isExecuting]) {
      cell.progressLabel = [NSString stringWithFormat:@"Downloading @ %.1fKB/sec", download.speed];
    } else {
      cell.progressLabel = @"Waiting...";
    }
    cell.progressView.progress = download.progress;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  } 
  else {
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    if (download.failed) {
      cell.progressLabel = @"Download Failed";
    }
    else {
      cell.progressLabel = [download.savePath stringByAbbreviatingWithTildeInPath];
    }
  }
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if(tableView.numberOfSections == 2 && indexPath.section == 0) return 74;
  else return 58;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.numberOfSections == 2 && indexPath.section == 0) {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    return;
  }
  self.currentSelectedIndexPath = indexPath;
  if (tableView.numberOfSections == 1 || indexPath.section == 1) {
    id download = [_finishedDownloads objectAtIndex:indexPath.row];
    id launch = [[SDDownloadActionSheet alloc] initWithDownload:download delegate:self];
    [launch showInView:self.view];
    [launch release];
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (NSString *)tableView:(UITableView *)tableView 
titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.numberOfSections == 2 && indexPath.section == 0)
    return @"Cancel"; 
  else // local files
    return @"Clear";
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
 forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    if (tableView.numberOfSections == 2 && indexPath.section == 0) {
	  id download = [_currentDownloads objectAtIndex:indexPath.row];
	  NSLog(@"cancel download: %@", download);
      [self cancelDownload:download];
	}
    else {
      [_finishedDownloads removeObjectAtIndex:indexPath.row];
      [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationFade];
    }
  }
  [self saveData];
}
/*}}}*/

- (void)downloadActionSheet:(SDDownloadActionSheet *)actionSheet retryDownload:(SDSafariDownload *)download {
  int row = [_finishedDownloads indexOfObject:download];
  int section = (_currentDownloads.count > 0) ? 1 : 0;
  [download retain];
  [_finishedDownloads removeObjectAtIndex:row];
  [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:section]] 
                    withRowAnimation:UITableViewRowAnimationFade];
  download.failed = NO;
  download.useSuggest = NO;
  [self addDownload:download browser:NO];
}

- (void)downloadActionSheet:(SDDownloadActionSheet *)actionSheet deleteDownload:(SDSafariDownload *)download {
NSLog(@"downloadActionSheet:%@ deleteDownload:%@", actionSheet, download);
  NSString *path = [NSString stringWithFormat:@"%@/%@", download.savePath, download.filename];
  int row = [_finishedDownloads indexOfObject:download];
  int section = (_currentDownloads.count > 0) ? 1 : 0;

  [_finishedDownloads removeObjectAtIndex:row];
  [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:section]] 
                    withRowAnimation:UITableViewRowAnimationFade];

  [[objc_getClass("SandCastle") sharedInstance] removeItemAtResolvedPath:path];
}

- (void)downloadActionSheetWillDismiss:(SDDownloadActionSheet *)actionSheet {
  [(UITableView *)self.view deselectRowAtIndexPath:self.currentSelectedIndexPath animated:YES];
  self.currentSelectedIndexPath = nil;
}

- (void)updateBadges {
  NSString *val = nil;
  if(_currentDownloads.count > 0) val = [NSString stringWithFormat:@"%d", _currentDownloads.count];
  [_portraitDownloadButton _setBadgeValue:val];
  [_landscapeDownloadButton _setBadgeValue:val];
  //[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (int)downloadsRunning {
  return _currentDownloads.count;
}
@end

// vim:filetype=objc:ts=2:sw=2:expandtab
