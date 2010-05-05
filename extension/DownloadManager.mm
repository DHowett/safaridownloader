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

#define DL_ARCHIVE_PATH @"/var/mobile/Library/Downloads/safaridownloads.plist"
#define kDownloadSheet 993349
#define kActionSheet 903403

DHLateClass(Application);
DHLateClass(BrowserController);

@interface UIApplication (Safari)
- (void)applicationOpenURL:(id)url;
@end

@implementation FileBrowserPanel
- (BOOL)allowsRotation { return NO; }
- (BOOL)pausesPages { return NO; }
- (int)panelType { return 45; }
- (int)panelState { return 1; }
@end

@implementation DownloadManagerNavigationController
static id sharedNc = nil;
+ (void)initialize  {
  if (self == [DownloadManagerNavigationController class]) {
    NSLog(@"INITIALIZE!!");
    sharedNc = [[self alloc] initWithRootViewController:[DownloadManager sharedManager]];
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inter {
  return NO; 
}

+ (id)sharedInstance { return sharedNc; }
- (id)copyWithZone:(NSZone *)zone { return self; }
- (id)retain { return self; }
- (unsigned)retainCount { return UINT_MAX; }
- (void)release { }
- (id)autorelease { return self; }
- (BOOL)allowsRotation { return NO; }
- (BOOL)pausesPages { return NO; }
- (int)panelType { return 44; }
- (int)panelState { return 1; }
- (BOOL)isDismissible { return _isDismissible; }

#undef MARK
#define MARK    NSLog(@"%s", __PRETTY_FUNCTION__);

- (void)close {
  [[$BrowserController sharedBrowserController] hideBrowserPanelType:44];
}

static int markthing = 0;
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [[$BrowserController sharedBrowserController] didShowBrowserPanel:[[$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[$BrowserController sharedBrowserController] willShowBrowserPanel:[[$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  if ([[$BrowserController sharedBrowserController] browserPanel] == self)
    [[$BrowserController sharedBrowserController] didHideBrowserPanel:[[$BrowserController sharedBrowserController] browserPanel]];
}
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  if([[$BrowserController sharedBrowserController] browserPanel] == self)
    [[$BrowserController sharedBrowserController] closeBrowserPanel:[[$BrowserController sharedBrowserController] browserPanel]];
}
@end

@implementation DownloadManager
@synthesize 
portraitDownloadButton = _portraitDownloadButton,
landscapeDownloadButton = _landscapeDownloadButton,
userPrefs = _userPrefs,
visible = _visible,
loadingURL = _loadingURL,
currentRequest;

#pragma mark -
#pragma mark Singleton Methods/*{{{*/
static id sharedManager = nil;
static id resourceBundle = nil;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)inter {
  return NO; 
}

+ (void)initialize  {
  if (self == [DownloadManager class]) {
    sharedManager = [[self alloc] init];
  }
}

+ (id)sharedManager {
  return sharedManager;
}

- (id)init {
  if (self = [super init]) {
    _fbPanel = [[FileBrowserPanel alloc] init];
    resourceBundle = [[NSBundle alloc] initWithPath:SUPPORT_BUNDLE_PATH];
    _currentDownloads = [NSMutableArray new];
    _finishedDownloads = [NSMutableArray new];
    _downloadQueue = [NSOperationQueue new];
    [_downloadQueue setMaxConcurrentOperationCount:5];
    [self updateUserPreferences];
    [self updateFileTypes];
    _visible = NO;
  }
  return self;
}

- (void)loadView { 
  NSLog(@"LOADVIEW!!");
  UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel All" 
                                                                   style:UIBarButtonItemStyleBordered 
                                                                  target:self 
                                                                  action:@selector(cancelAllDownloads)];
  self.navigationItem.rightBarButtonItem = cancelButton;
  self.navigationItem.rightBarButtonItem.enabled = YES;
  
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" 
                                                                 style:UIBarButtonItemStyleDone 
                                                                target:[DownloadManagerNavigationController sharedInstance] 
                                                                action:@selector(close)];
  self.navigationItem.leftBarButtonItem = doneButton;
  self.navigationItem.leftBarButtonItem.enabled = YES;
  
  _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320.f, 480.f) style:UITableViewStylePlain];
  _tableView.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
}
#pragma mark -/*}}}*/
#pragma mark WebKit WebPolicyDelegate Methods/*{{{*/
static SDActionType _actionType = SDActionTypeNone;

// WebPolicyDelegate SafariDownloader Addition
- (SDActionType) webView:(WebView *)webView 
            decideAction:(NSDictionary*)action
              forRequest:(NSURLRequest *)request 
            withMimeType:(NSString *)mimeType 
                 inFrame:(WebFrame *)frame
            withListener:(id<WebPolicyDecisionListener>)listener {
  NSLog(@"WE GOT CALLED!!!!");
  
  NSString *url = [[request URL] absoluteString];
  
  if (![url hasPrefix:@"http://"] && 
      ![url hasPrefix:@"https://"] && 
      ![url hasPrefix:@"ftp://"]) {
    NSLog(@"not a valid url, continue.");
    return SDActionTypeNone;
  }
  
  if ([self supportedRequest:request 
                withMimeType:mimeType]) {
    
    NSLog(@"WE SUPPORT THE REQUEST: %@", request);
    
    NSString *filename = [self fileNameForURL:[request URL]];
    if (filename == nil) {
      filename = [[request URL] absoluteString];
    }
    
    NSString *other = nil;
    if(mimeType) 
      other = [objc_getClass("WebView") canShowMIMEType:mimeType] ? @"View" : nil;
    else 
      other = @"View";
    
    [ModalAlert showDownloadActionSheetWithTitle:@"What would you like to do?"
                                         message:filename
                                        mimetype:mimeType
                                    cancelButton:@"Cancel"
                                     destructive:@"Download"
                                           other:other
                                             tag:kDownloadSheet
                                        delegate:self];
    
    if (_actionType == SDActionTypeView) {
      return SDActionTypeView;
    }
    else if (_actionType == SDActionTypeDownload) {
      [listener ignore];
      [frame stopLoading];
      BOOL downloadAdded = NO;
      if(mimeType != nil)
        downloadAdded = [self addDownloadWithRequest:request 
                                         andMimeType:mimeType];
      else
        downloadAdded = [self addDownloadWithRequest:request];
      
      if (downloadAdded)
        NSLog(@"successfully added download");
      else
        NSLog(@"add download failed");
      return SDActionTypeDownload;
    } 
    else {
      [listener ignore];
      [frame stopLoading];
      return SDActionTypeCancel;
    }
  }
  else {
    NSLog(@"Request %@ unsupported", request);
    return SDActionTypeNone;
  }
  NSLog(@"RETURNING NO!");
  return SDActionTypeNone;
}

#pragma mark -/*}}}*/
#pragma mark Filetype Support Management/*{{{*/

- (void)updateFileTypes {
  NSMutableDictionary *globalFileTypes = 
  [NSMutableDictionary dictionaryWithContentsOfFile:[resourceBundle pathForResource:@"FileTypes" 
                                                                             ofType:@"plist"]];
  NSArray *disabledItems = [_userPrefs objectForKey:@"DisabledItems"];
  NSDictionary *customTypes = [_userPrefs objectForKey:@"CustomItems"];
  if (customTypes) 
    [globalFileTypes setValue:customTypes forKey:@"CustomItems"];
  
  if (_mimeTypes) [_mimeTypes release];
  if (_extensions) [_extensions release];
  if (_classMappings) [_classMappings release];
  _mimeTypes = [[NSMutableSet alloc] init];
  _extensions = [[NSMutableSet alloc] init];
  _classMappings = [[NSMutableDictionary alloc] init];
  
  BOOL disabled = [[_userPrefs objectForKey:@"Disabled"] boolValue];
  if (disabled) return;
  
  BOOL useExtensions = [[_userPrefs objectForKey:@"UseExtensions"] boolValue];
  
  for (NSString *fileClassName in globalFileTypes) {
    NSDictionary *fileClass = [globalFileTypes objectForKey:fileClassName];
    for (NSString *fileTypeName in fileClass) {
      if ([disabledItems containsObject:fileTypeName]) {
        NSLog(@"Skipping %@...", fileTypeName);
        continue;
      }
      
      NSDictionary *fileType = [fileClass objectForKey:fileTypeName];
      NSArray *mimes = [fileType objectForKey:@"Mimetypes"];
      [_mimeTypes addObjectsFromArray:mimes];
      for (NSString *i in mimes) [_classMappings setObject:fileClassName forKey:i];
      if (useExtensions || [[fileType objectForKey:@"ForceExtension"] boolValue] || [fileClassName isEqualToString:@"CustomItems"]) {
        NSArray *exts = [fileType objectForKey:@"Extensions"];
        [_extensions addObjectsFromArray:exts];
        for(NSString *i in exts) [_classMappings setObject:fileClassName forKey:i];
      }
    }
  }
  NSLog(@"%@", _mimeTypes);
  
  NSFileManager *fm = [NSFileManager defaultManager];
  if (_launchActions) [_launchActions release];
  _launchActions = [[NSMutableDictionary alloc] init];
  if ([fm fileExistsAtPath:@"/Applications/iFile.app"]) {
    NSDictionary *iFile = [NSDictionary dictionaryWithContentsOfFile:@"/Applications/iFile.app/Info.plist"];
    NSString *iFileVersion = [iFile objectForKey:@"CFBundleVersion"];
    if (![iFileVersion isEqualToString:@"1.0.0"])
      [_launchActions setObject:@"ifile://" forKey:@"Open in iFile"];
  }
  return;
}

- (NSString *)iconPathForClassOfType:(NSString *)name {
  NSString *iconPath = nil;
  if (!name || [name length] == 0) return nil;
  NSString *t = [_classMappings objectForKey:name];
  NSLog(@"Class is %@", t);
  if (t != nil) iconPath = 
    [resourceBundle pathForResource:[@"Class-" stringByAppendingString:t] 
                             ofType:@"png" inDirectory:@"FileIcons"];
  return iconPath;
}

- (NSString *)iconPathForName:(NSString *)name {
  NSString *iconPath = nil;
  if(name && [name length] > 0) {
    iconPath = [resourceBundle pathForResource:name 
                                        ofType:@"png" 
                                   inDirectory:@"FileIcons"];
    NSLog(@"name is %@", name);
  }
  return iconPath;
}

- (NSString *)iconPathForMIME:(NSString *)mime {
  NSString *iconPath = nil;
  if (mime && [mime length] > 0) {
    NSString *sanitaryMime = [mime stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    NSString *mimeClass = [[mime componentsSeparatedByString:@"/"] objectAtIndex:0];
    iconPath = [resourceBundle pathForResource:sanitaryMime
                                        ofType:@"png" 
                                   inDirectory:@"FileIcons"];
    if (!iconPath) {
      iconPath = [resourceBundle pathForResource:mimeClass
                                          ofType:@"png" 
                                     inDirectory:@"FileIcons"];
    }
    NSLog(@"Sanitized mime type is %@ mime class is %@", sanitaryMime, mimeClass);
  }
  return iconPath;
}

- (UIImage*)iconForExtension:(NSString *)extension 
                   orMimeType:(NSString *)mimeType {
  NSString *mimeIconPath = [self iconPathForMIME:mimeType];
  NSString *extIconPath = [self iconPathForName:extension];
  NSString *iconPath = nil;
  if(mimeIconPath != nil) iconPath = mimeIconPath;
  if(extIconPath != nil) iconPath = extIconPath;
  if(!iconPath) iconPath = [self iconPathForClassOfType:extension]; // Class-xxx lookup fallthrough
  if(!iconPath) iconPath = [self iconPathForClassOfType:mimeType]; // Class-xxx lookup fallthrough
  if(!iconPath) iconPath = [resourceBundle pathForResource:@"unknownfile" 
                                                    ofType:@"png"];
  return [UIImage imageWithContentsOfFile:iconPath];
}

- (BOOL)supportedRequest:(NSURLRequest *)request
            withMimeType:(NSString *)mimeType {
  NSLog(@"mimetype count: %d", [_mimeTypes count]);
  NSLog(@"extensions count: %d", [_extensions count]);
  
  if (mimeType != nil && [_mimeTypes containsObject:mimeType]) {
    NSLog(@"mimeType: %@ supported!", mimeType);
    return YES;
  }
  else {
    NSString* extension = [[[request URL] absoluteString] pathExtension];
    if ([_extensions containsObject:extension]) {
      NSLog(@"extensions contain %@, supported!", extension);
      return YES;
    }
  }
  return NO;
}

#pragma mark -/*}}}*/
#pragma mark Persistent Storage/*{{{*/

- (void)saveData {
  NSLog(@"(fake) archiving to path: %@", DL_ARCHIVE_PATH);
  //[NSKeyedArchiver archiveRootObject:_currentDownloads toFile:DL_ARCHIVE_PATH]; 
}

#pragma mark -

- (void)disableRotations {
  Class BrowserController = objc_getClass("BrowserController");
  _oldPanel = [[[BrowserController sharedBrowserController] browserPanel] retain];
  [[BrowserController sharedBrowserController] _setBrowserPanel:_fbPanel]; 
}

- (void)enableRotations {
  Class BrowserController = objc_getClass("BrowserController");
  [[BrowserController sharedBrowserController] _setBrowserPanel:_oldPanel];
  [_oldPanel release];
  _oldPanel = nil;
}

#pragma mark -

#pragma mark -/*}}}*/
#pragma mark Download Management/*{{{*/

- (SafariDownload *)downloadWithURL:(NSURL*)url {
  for (SafariDownload *download in _currentDownloads) {
    if ([[download.urlReq URL] isEqual:url])
      return download;
  }
  return nil; 
}

- (void)fileBrowser:(FileBrowser*)browser 
      didSelectPath:(NSString*)path 
            forFile:(id)file 
        withContext:(id)download {
  [ModalAlert showLoadingAlertWithIconName:((SafariDownload*)download).filename orMimeType:((SafariDownload*)download).mimetype];
  [self enableRotations];
  ((SafariDownload*)download).savePath = path;
  DownloadOperation *op = [[DownloadOperation alloc] initWithDelegate:(SafariDownload*)download];
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
}

- (void)fileBrowserDidCancel:(FileBrowser*)browser {
  NSLog(@"fileBrowserDidCancel");
  [self enableRotations];
}

// everything eventually goes through this method
- (BOOL)addDownload:(SafariDownload*)download {
  if (![_currentDownloads containsObject:download]) {
    [self disableRotations];
    FileBrowser* f = [[FileBrowser alloc] initWithFile:download.filename 
                                               context:download
                                              delegate:self];
    [f show];
    [f release];
    return YES;
  }
  return NO;
}

- (BOOL)addDownloadWithURL:(NSURL*)url {
  if ([self downloadWithURL:url])
    return NO;
  
  BOOL use = NO;
  NSString *filename = [self fileNameForURL:url];
  if (filename == nil) {
    filename = [url absoluteString];
    use = YES;
  }
  
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:[NSURLRequest requestWithURL:url]
                                                                name:filename
                                                            delegate:self
                                                        useSuggested:use];
  
  return [self addDownload:download];
}

- (BOOL)addDownloadWithRequest:(NSURLRequest*)request {
  BOOL use = NO;
  NSString *filename = [self fileNameForURL:[request URL]];
  if (filename == nil) {
    filename = [[request URL] absoluteString];
    use = YES;
  }
  
  if ([self downloadWithURL:[request URL]])
    return NO;
  
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:request
                                                                name:filename
                                                            delegate:self
                                                        useSuggested:use];
  return [self addDownload:download];
}

- (BOOL)addDownloadWithRequest:(NSURLRequest*)request andMimeType:(NSString *)mimeType {
  BOOL use = NO;
  NSString *filename = [self fileNameForURL:[request URL]];
  if (filename == nil) {
    filename = [[request URL] absoluteString];
    use = YES;
  }
  
  if ([self downloadWithURL:[request URL]])
    return NO;
  
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:request
                                                                name:filename
                                                            delegate:self
                                                        useSuggested:use];
  download.mimetype = mimeType;
  return [self addDownload:download];
}

- (BOOL)addDownloadWithInfo:(NSDictionary*)info {
  NSURLRequest*   request  = [info objectForKey:@"request"];
  if ([self downloadWithURL:[request URL]])
    return NO;
  
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:request
                                                                name:[info objectForKey:@"name"]
                                                            delegate:self
                                                        useSuggested:NO];
  return [self addDownload:download];
}

// everything eventually goes through this method
- (BOOL)cancelDownload:(SafariDownload *)download {
  if (download != nil) {
    @try {
      DownloadOperation *op = download.downloadOperation;
      [op cancel];
      download.downloadOperation = nil;
    }
    @catch (id nothing) { 
      NSLog(@"exception caught attempting to cancel operation"); 
    }
    
    NSUInteger row = [_currentDownloads indexOfObject:download];
    [_currentDownloads removeObject:download];
    
    if (_currentDownloads.count == 0) {
      [_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
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

- (void)deleteDownload:(SafariDownload*)download {

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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 1) {
    if (_currentDownloads.count > 0) {
      [self saveData];
      [_downloadQueue cancelAllOperations];
      [_currentDownloads removeAllObjects];
      [_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
  } 
}

- (DownloadCell*)cellForDownload:(SafariDownload*)download {
  NSUInteger row = [_currentDownloads indexOfObject:download];
  DownloadCell *cell = (DownloadCell*)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
  return cell;
}

#pragma mark -/*}}}*/
#pragma mark SafariDownloadDelegate Methods/*{{{*/

- (void)downloadDidBegin:(SafariDownload*)download {
  [ModalAlert dismissLoadingAlert];
  [self updateBadges];
  DownloadCell *cell = [self cellForDownload:download];
  cell.nameLabel = download.filename;
  cell.progressLabel = @"Downloading...";
  cell.completionLabel = @"0%";
}

- (void)downloadDidReceiveAuthenticationChallenge:(SafariDownload *)download {
  [ModalAlert dismissLoadingAlert];
  DownloadCell *cell = [self cellForDownload:download];
  cell.progressLabel = @"Awaiting Authentication...";
}

- (void)downloadDidProvideFilename:(SafariDownload*)download {
  [ModalAlert dismissLoadingAlert];
  DownloadCell *cell = [self cellForDownload:download];
  cell.nameLabel = download.filename;
}

- (void)downloadDidFinish:(SafariDownload*)download {
  NSLog(@"downloadDidFinish");
  DownloadCell* cell = [self cellForDownload:download];
  
  download.downloadOperation = nil; // no-op atm
  cell.progressLabel = @"Download Complete";
  NSUInteger row = [_currentDownloads indexOfObject:download];
  [_currentDownloads removeObject:download];
  [_finishedDownloads addObject:download];
  
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
- (void)updateProgressForDownload:(SafariDownload*)download {
  DownloadCell* cell = [self cellForDownload:download];
  float progress = cell.progressView.progress;
  progress += (download.progress - progress)/4;
  cell.progressView.progress = progress;
  if (progress < download.progress) { // :o recursive method with delay :o
    [self performSelector:@selector(updateProgressForDownload:) 
               withObject:download 
               afterDelay:0.1];
  }
}

- (void)downloadDidUpdate:(SafariDownload*)download {
  DownloadCell* cell = [self cellForDownload:download];
  cell.progressView.progress = download.progress;
  cell.completionLabel = [NSString stringWithFormat:@"%d%%", (int)(download.progress*100.0f)];
  cell.progressLabel = [NSString stringWithFormat:@"Downloading @ %.1fKB/sec", download.speed];
  cell.sizeLabel = download.sizeString;
}

- (void)downloadDidCancel:(SafariDownload*)download {   
  [ModalAlert dismissLoadingAlert];
  [self updateBadges];
  [self saveData];  
  download.downloadOperation = nil;
}

- (void)downloadDidFail:(SafariDownload*)download {
  [ModalAlert dismissLoadingAlert];
  NSLog(@"downloadDidFail");
  DownloadCell* cell = [self cellForDownload:download];
  
  download.downloadOperation = nil;
  cell.progressLabel = @"Download Failed";
  NSUInteger row = [_currentDownloads indexOfObject:download];
  [_currentDownloads removeObject:download];
  [_finishedDownloads addObject:download];
  
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

static int animationType = 0;

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

#pragma mark -/*}}}*/
#pragma mark UITableView methods/*{{{*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (_currentDownloads.count > 0)
    return 2;
  else
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if (tableView.numberOfSections == 2 && section == 0)
    return @"Active Downloads";
  else
    return @"Finished Downloads";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if(tableView.numberOfSections == 2 && section == 0)
    return [_currentDownloads count];
  else
    return [_finishedDownloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"DownloadCell";
  BOOL finished = NO;
  SafariDownload *download = nil;
  
  if(tableView.numberOfSections == 2 && indexPath.section == 0) {
    download = [_currentDownloads objectAtIndex:indexPath.row];
    finished = NO;
  } else {
    CellIdentifier = @"FinishedDownloadCell";
    download = [_finishedDownloads objectAtIndex:indexPath.row];
    finished = YES;
  }
  
  DownloadCell *cell = (DownloadCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[DownloadCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
  }
  
  // Set up the cell...
  cell.finished = finished;
  cell.failed = download.failed;
  cell.icon = [self iconForExtension:[download.filename pathExtension] orMimeType:download.mimetype];
	cell.nameLabel = download.filename;
  cell.sizeLabel = download.sizeString;
  if(!finished && !download.failed) {
    cell.progressLabel = [NSString stringWithFormat:@"Downloading @ %.1fKB/sec", download.speed];
    cell.progressView.progress = download.progress;
  } 
  else {
    if (download.failed) {
      cell.progressLabel = @"Download Failed";
    }
    else {
      cell.progressLabel = @"Download Complete";
    }
  }
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if(tableView.numberOfSections == 2 && indexPath.section == 0) return 74;
  else return 58;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  if (tableView.numberOfSections == 1 || indexPath.section == 1) {
    curDownload = [_finishedDownloads objectAtIndex:indexPath.row];
    UIActionSheet *launch = [[UIActionSheet alloc] initWithTitle:curDownload.filename
                                                        delegate:self
                                               cancelButtonTitle:nil
                                          destructiveButtonTitle:@"Delete"
                                               otherButtonTitles:nil];
    if (curDownload.failed) [launch addButtonWithTitle:@"Retry"];
    else {
      for(NSString *title in _launchActions) {
        [launch addButtonWithTitle:title];
      }
    }
    launch.cancelButtonIndex = [launch addButtonWithTitle:@"Cancel"];
    [launch showInView:self.view];
    launch.tag = kActionSheet;
    [launch release];
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.numberOfSections == 2 && indexPath.section == 0)
    return @"Cancel"; 
  else // local files
    return @"Clear";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    if (tableView.numberOfSections == 2 && indexPath.section == 0)
      [self cancelDownload:[_currentDownloads objectAtIndex:indexPath.row]];
    else {
      [_finishedDownloads removeObjectAtIndex:indexPath.row];
      [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationFade];
    }
  }
}
/*}}}*/

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  
  if (actionSheet.tag == kDownloadSheet) {
    if([[actionSheet buttonTitleAtIndex:buttonIndex] 
        isEqualToString:@"Cancel"])
      _actionType = SDActionTypeCancel;
    else if([[actionSheet buttonTitleAtIndex:buttonIndex]
             isEqualToString:@"View"]) 
      _actionType = SDActionTypeView;
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] 
              isEqualToString:@"Download"])
      _actionType = SDActionTypeDownload;
  }
  else if (actionSheet.tag == kActionSheet) {
    NSString *button = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *action = [_launchActions objectForKey:button];
    if([button isEqualToString:@"Delete"]) {
      NSString *path = [NSString stringWithFormat:@"/private/var/mobile/Library/Downloads/%@", curDownload.filename];
      int row = [_finishedDownloads indexOfObject:curDownload];
      int section = (_currentDownloads.count > 0) ? 1 : 0;
      
      [_finishedDownloads removeObjectAtIndex:row];
      [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:section]] withRowAnimation:UITableViewRowAnimationFade];
      [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    } else if([button isEqualToString:@"Retry"]) {
      int row = [_finishedDownloads indexOfObject:curDownload];
      int section = (_currentDownloads.count > 0) ? 1 : 0;
      [_finishedDownloads removeObjectAtIndex:row];
      [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:section]] withRowAnimation:UITableViewRowAnimationFade];
      curDownload.failed = NO;
      curDownload.useSuggest = NO;
      [self addDownload:curDownload];
    } else if(action) {
      Class Application = objc_getClass("Application");
      NSString *path = [NSString stringWithFormat:@"/private/var/mobile/Library/Downloads/%@", curDownload.filename];
      path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      [[Application sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", action, path]]];
    }
    curDownload = nil;
  }
}

- (void)updateBadges {
  NSString *val = nil;
  if(_currentDownloads.count > 0) val = [NSString stringWithFormat:@"%d", _currentDownloads.count];
  [_portraitDownloadButton _setBadgeValue:val];
  [_landscapeDownloadButton _setBadgeValue:val];
  //[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}
@end

// vim:filetype=objc:ts=2:sw=2:expandtab
