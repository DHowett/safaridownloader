//
//  DownloadManager.m
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import "DownloadManager.h"
#import "Cell.h"
#define DL_ARCHIVE_PATH @"/var/mobile/Library/Downloads/safaridownloads.plist"

static BOOL doRot = YES;

@implementation DownloadManagerPanel

- (void)allowRotations:(BOOL)allow {
  _allowsRotations = allow;
  doRot = allow;
}

-(BOOL) allowsRotation {
  return _allowsRotations;
}

-(BOOL) pausesPages {
  return NO;
}

-(int) panelType {
  return 44;
}

-(int) panelState {
  return 0;
}

-(NSString*)description {
 return @"[DownloadManagerPanel]: Fake object that conforms to the browserpanel protocol, this allows us to block rotations successfully"; 
}

@end

@implementation DownloadManager

#pragma mark -
#pragma mark Singleton Methods/*{{{*/
static id sharedManager = nil;
static id resourceBundle = nil;

+ (void)initialize  {
  if (self == [DownloadManager class])
  {
    sharedManager = [[self alloc] init];
    resourceBundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/Downloader"];
  }
}

+ (id)sharedManager
{
  return sharedManager;
}

- (id)init {
  if([self initWithStyle:UITableViewStylePlain] != nil) 
  {
    _currentDownloads = [NSMutableArray new];
    _finishedDownloads = [NSMutableArray new];
    _downloadQueue = [NSOperationQueue new];
    [_downloadQueue setMaxConcurrentOperationCount:5];
    _mimeTypes = [[NSArray alloc] initWithObjects: // eventually have these loaded from prefs on disk
                  @"image/jpeg",
                  @"image/jpg",
                  @"image/png",
                  @"image/tga",
                  @"image/targa",
                  @"image/tiff",
                  @"text/plain",
                  @"application/text",
                  @"application/pdf",
                  @"text/pdf",
                  @"application/msword",
                  @"application/doc",
                  @"appl/text",
                  @"application/winword",
                  @"application/word",
                  @"text/xml",
                  @"application/xml",
                  @"application/msexcel",
                  @"application/x-msexcel",
                  @"application/x-ms-excel",
                  @"application/vnd.ms-excel",
                  @"application/x-excel",
                  @"application/x-dos_ms_excel",
                  @"application/xls",
                  @"application/x-xls",
                  @"zz-application/zz-winassoc-xls",
                  @"application/mspowerpoint",
                  @"application/ms-powerpoint",
                  @"application/mspowerpnt",
                  @"application/vnd-mspowerpoint",
                  @"application/vnd.ms-powerpoint",
                  @"application/powerpoint",
                  @"application/x-powerpoint",
                  @"application/x-mspowerpoint",
                  @"application/octet-stream",
                  @"application/bin",
                  @"applicaiton/binary",
                  @"application/x-msdownload",
                  @"application/x-deb",
                  @"application/zip",
                  @"video/quicktime",
                  nil];  
  }
  return self;
}

- (void)loadView
{
  _tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]  style:UITableViewStylePlain];
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin   |
  UIViewAutoresizingFlexibleLeftMargin   | UIViewAutoresizingFlexibleRightMargin |
  UIViewAutoresizingFlexibleWidth        | UIViewAutoresizingFlexibleHeight;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.rowHeight = 56;
  self.view = _tableView; 
}

- (id)copyWithZone:(NSZone *)zone {
  return self;
}

- (id)retain {
  return self;
}

- (unsigned)retainCount {
  return UINT_MAX;
}

- (void)release {}

- (id)autorelease {
  return self;
}

- (UIImage *)iconForExtension:(NSString *)extension {
  NSString *iconPath = [resourceBundle pathForResource:extension ofType:@"png" inDirectory:@"FileIcons"];
  if(!iconPath) iconPath = [resourceBundle pathForResource:@"unknownfile" ofType:@"png"];
  return [UIImage imageWithContentsOfFile:iconPath];
}

#pragma mark -/*}}}*/
#pragma mark Filetype Support Management/*{{{*/

- (BOOL)supportedRequest:(NSURLRequest *)request
            withMimeType:(NSString *)mimeType
{
  NSString *urlString = [[request URL] absoluteString];
  if (mimeType != nil && [_mimeTypes containsObject:mimeType]) 
  {
    return YES;
  }
  else  // eventually have this read from a prefs array on disk
    if (// documents
        [urlString hasSuffix:@".doc"]
        || [urlString hasSuffix:@".docx"]
        || [urlString hasSuffix:@".ppt"]
        || [urlString hasSuffix:@".pptx"]
        || [urlString hasSuffix:@".xls"]
        || [urlString hasSuffix:@".xlsx"]
        // images
        || [urlString hasSuffix:@".jpg"]
        || [urlString hasSuffix:@".jpeg"]
        || [urlString hasSuffix:@".png"]
        || [urlString hasSuffix:@".tif"]
        || [urlString hasSuffix:@".tiff"]
        || [urlString hasSuffix:@".gif"]
        // audio/video
        || [urlString hasSuffix:@".mp3"]
        || [urlString hasSuffix:@".wav"]
        || [urlString hasSuffix:@".ogg"]
        || [urlString hasSuffix:@".mp4"]
        || [urlString hasSuffix:@".mpg"]
        || [urlString hasSuffix:@".mpeg"]
        || [urlString hasSuffix:@".avi"]
        || [urlString hasSuffix:@".aac"]
        || [urlString hasSuffix:@".mp3"]
        // archives
        || [urlString hasSuffix:@".deb"]
        || [urlString hasSuffix:@".zip"]
        || [urlString hasSuffix:@".rar"]
        || [urlString hasSuffix:@".tar"]
        || [urlString hasSuffix:@".tgz"]
        || [urlString hasSuffix:@".tbz"]
        || [urlString hasSuffix:@".gz"]
        || [urlString hasSuffix:@".bzip2"])
    {
      return YES;
    }
  return NO;
}

#pragma mark -/*}}}*/
#pragma mark Persistent Storage/*{{{*/

- (void)saveData
{
  NSLog(@"(fake) archiving to path: %@", DL_ARCHIVE_PATH);
  //[NSKeyedArchiver archiveRootObject:_currentDownloads toFile:DL_ARCHIVE_PATH]; 
}

#pragma mark -/*}}}*/
#pragma mark Download Management/*{{{*/

- (SafariDownload *)downloadWithURL:(NSURL*)url
{
  for (SafariDownload *download in _currentDownloads) 
  {
    if ([[download.urlReq URL] isEqual:url])
      return download;
  }
  return nil; 
}

// everything eventually goes through this method
- (BOOL)addDownload:(SafariDownload *)download {
  if (![_currentDownloads containsObject:download]) 
  {
    DownloadOperation *op = [[DownloadOperation alloc] initWithDelegate:download];
    [_downloadQueue addOperation:op];
    [op release];
    [_currentDownloads addObject:download];
    if(_currentDownloads.count == 1) {
      [_tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } else {
      [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_currentDownloads.count-1 inSection:0]] 
                        withRowAnimation:UITableViewRowAnimationFade];
    }
    [self updateButtonBadges];
    return YES;
  }
  return NO;
}

- (BOOL)addDownloadWithURL:(NSURL*)url {
  if ([self downloadWithURL:url])
    return NO;
  
  NSString *name = [[url absoluteString] lastPathComponent];
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:[NSURLRequest requestWithURL:url]
                                                                name:name
                                                            delegate:self];
  
  return [self addDownload:download];
}

- (BOOL)addDownloadWithRequest:(NSURLRequest*)request {
  NSLog(@"addDownloadWithRequest: %@", request);
  NSString *name = [[[request URL] absoluteString] lastPathComponent];
  
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:request
                                                                name:name
                                                            delegate:self];
  if ([self downloadWithURL:[request URL]])
    [download release];
  else
    return [self addDownload:download];
  
  return NO;
}

- (BOOL)addDownloadWithInfo:(NSDictionary*)info {
  NSURLRequest*   request  = [info objectForKey:@"request"];
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:request
                                                                name:[info objectForKey:@"name"]
                                                            delegate:self];
  if ([self downloadWithURL:[request URL]])
    [download release];
  else
    return [self addDownload:download];
  
  return NO;
}

// everything eventually goes through this method
- (BOOL)cancelDownload:(SafariDownload *)download {
  if (download != nil)
  {
    NSUInteger index = [_currentDownloads indexOfObject:download];
    
    @try 
    {
      DownloadOperation *op = [[_downloadQueue operations] objectAtIndex:index];
      [op cancel];
    }
    @catch (id nothing) 
    { 
      NSLog(@"exception caught attempting to cancel operation"); 
    }
    
    int idx = [_currentDownloads indexOfObject:download];
    [_currentDownloads removeObject:download];
    
    if (_currentDownloads.count == 0) {
      [_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    } else {
      [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]]
                        withRowAnimation:UITableViewRowAnimationFade];
    }
    [self updateButtonBadges];
  }
  return NO;
}

- (BOOL)cancelDownloadWithURL:(NSURL *)url
{
  if ([self cancelDownload:[self downloadWithURL:url]])
    return YES;
  return NO; 
}

- (void)deleteDownload:(SafariDownload*)download
{
  //  NSString *prefix = @"/var/mobile/Library/Downloads/YourTube";
  //  NSString *path = [prefix stringByAppendingPathComponent:download.filename];
  //  NSLog(@"removing file at path: %@", path);
  //  [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
  //  NSUInteger index = [_downloadedVideos indexOfObject:download];
  //  [_downloadedVideos removeObjectAtIndex:index];
  //  NSInteger section = [_tableView numberOfSections] - 1;
  //  [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:section]] 
  //                    withRowAnimation:UITableViewRowAnimationFade]; 
}

- (void)cancelAllDownloads
{
  [self saveData];
  [_downloadQueue cancelAllOperations];
}

- (Cell*)cellForDownload:(SafariDownload*)download
{
  NSUInteger row = [_currentDownloads indexOfObject:download];
  Cell *cell = (Cell*)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
  return cell;
}

#pragma mark -/*}}}*/
#pragma mark SafariDownloadDelegate Methods/*{{{*/

- (void)downloadDidBegin:(SafariDownload*)download
{
  Cell *cell = [self cellForDownload:download];
  cell.progressLabel = @"Downloading...";
  cell.completionLabel = @"0%";
}

- (void)downloadDidFinish:(SafariDownload*)download
{
  NSLog(@"downloadDidFinish");
  Cell *cell = [self cellForDownload:download];
  
  if (cell == nil) {
    return;
  }
  
  cell.progressLabel = @"Download Complete";
  
  NSUInteger row = [_currentDownloads indexOfObject:download];
  [_currentDownloads removeObject:download];
  
  if (_currentDownloads.count == 0) {
    [_tableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
  } else {
    [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]]
                      withRowAnimation:UITableViewRowAnimationFade];
  }
  
  [_finishedDownloads addObject:download];
  
  if (_currentDownloads.count > 0) {
    [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_finishedDownloads.count-1 inSection:1]]
                      withRowAnimation:UITableViewRowAnimationFade];
  } else {
    [_tableView reloadData];
  }
  [self updateButtonBadges];
  
  [self saveData];
}

- (void)downloadDidUpdate:(SafariDownload*)download
{
  Cell *cell = [self cellForDownload:download];
  if (!cell.nameLabel) cell.nameLabel = download.filename; // I know, why do this every update? I couldn't catch the suggested filename properly with didBegin. >:{
  cell.progressView.progress = download.progress;
  cell.completionLabel = [NSString stringWithFormat:@"%d%%", (int)(download.progress*100.0f)];
  cell.progressLabel = [NSString stringWithFormat:@"Downloading @ %.1fKB/sec", download.speed];
  cell.sizeLabel = download.sizeString;
}

- (void)downloadDidFail:(SafariDownload*)download
{
  Cell *cell = [self cellForDownload:download];
  cell.progressLabel = @"Download Failed";
}

#pragma mark -/*}}}*/
#pragma mark UIViewController Methods/*{{{*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES; 
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning]; 
}

- (void)viewDidLoad
{
  [super viewDidLoad]; 
}

- (void)viewDidUnload
{
  [super viewDidUnload]; 
}

#pragma mark -/*}}}*/
#pragma mark UITableView methods/*{{{*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if(_currentDownloads.count > 0) {
    return 2;
  } else {
    return 1;
  }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if(tableView.numberOfSections == 2 && section == 0) {
    return @"Active Downloads";
  } else {
    return @"Finished Downloads";
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if(tableView.numberOfSections == 2 && section == 0) {
    return [_currentDownloads count];
  } else {
    return [_finishedDownloads count];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"DownloadCell";
  BOOL finished = NO;
  SafariDownload *download;
  
  if(tableView.numberOfSections == 2 && indexPath.section == 0) {
    download = [_currentDownloads objectAtIndex:indexPath.row];
    finished = NO;
  } else {
    CellIdentifier = @"FinishedDownloadCell";
    download = [_finishedDownloads objectAtIndex:indexPath.row];
    finished = YES;
  }
  
  Cell *cell = (Cell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) 
  {
    cell = [[[Cell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
  }
  
  // Set up the cell...
  cell.finished = finished;
  cell.icon = [self iconForExtension:[download.filename pathExtension]];
	cell.nameLabel = download.filename;
  cell.sizeLabel = download.sizeString;
  if(!finished) {
    cell.progressLabel = [NSString stringWithFormat:@"Downloading (%.1fKB/sec)", download.speed];
    cell.progressView.progress = download.progress;
  } else {
    cell.progressLabel = @"Download Complete";
  }
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(tableView.numberOfSections == 2 && indexPath.section == 0) return 79;
  else return 56;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (tableView.numberOfSections == 2 && indexPath.section == 0)
    return @"Cancel"; 
  else // local files
    return @"Clear";
}

// Override to support editing the table view.
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

- (void)setPortraitDownloadButton:(id)portraitButton {
  _portraitDownloadButton = portraitButton;
}

- (void)setLandscapeDownloadButton:(id)landscapeButton {
  _landscapeDownloadButton = landscapeButton;
}

- (void)updateButtonBadges {
  NSString *val = nil;
  if(_currentDownloads.count > 0) val = [NSString stringWithFormat:@"%d", _currentDownloads.count];
  [_portraitDownloadButton _setBadgeValue:val];
  [_landscapeDownloadButton _setBadgeValue:val];
}
@end

// vim:filetype=objc:ts=2:sw=2:expandtab
