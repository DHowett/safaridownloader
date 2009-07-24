//
//  DownloadManager.m
//  Downloader
//
//  Created by Youssef Francis on 7/23/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import "DownloadManager.h"
#define DL_ARCHIVE_PATH @"/var/mobile/Library/Downloads/safaridownloads.plist"

@implementation DownloadManager

#pragma mark -
#pragma mark Singleton Methods
static id sharedManager = nil;

+ (void)initialize  {
  if (self == [DownloadManager class])
  {
    sharedManager = [[self alloc] initWithStyle:UITableViewStylePlain];
  }
}

+ (id)sharedManager
{
  return sharedManager;
}

- (void)loadView
{
  _tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]  style:UITableViewStylePlain];
  _tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin   |
  UIViewAutoresizingFlexibleLeftMargin   | UIViewAutoresizingFlexibleRightMargin |
  UIViewAutoresizingFlexibleWidth        | UIViewAutoresizingFlexibleHeight;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  self.view = _tableView; 
  _currentDownloads = [NSMutableArray new];
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

#pragma mark -
#pragma mark Filetype Support Management

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

#pragma mark -
#pragma mark Persistent Storage

- (void)saveData
{
  NSLog(@"(fake) archiving to path: %@", DL_ARCHIVE_PATH);
  //[NSKeyedArchiver archiveRootObject:_currentDownloads toFile:DL_ARCHIVE_PATH]; 
}

#pragma mark -
#pragma mark Download Management

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
    [_currentDownloads insertObject:download atIndex:0];
    [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] 
                      withRowAnimation:UITableViewRowAnimationFade];
    return YES;
  }
  return NO;
}

- (BOOL)addDownloadWithURL:(NSURL*)url {
  if ([self downloadWithURL:url])
    return NO;
  
  NSString *name = [[url absoluteString] lastPathComponent];
  NSString *icon = [[name pathExtension] stringByAppendingString:@".png"];
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:[NSURLRequest requestWithURL:url]
                                                                name:name
                                                                icon:icon
                                                            delegate:self];
  
  return [self addDownload:download];
}

- (BOOL)addDownloadWithRequest:(NSURLRequest*)request {
  NSLog(@"addDownloadWithRequest: %@", request);
  NSString *name = [[[request URL] absoluteString] lastPathComponent];
  NSString *icon = [[name pathExtension] stringByAppendingString:@".png"];
  SafariDownload* download = [[SafariDownload alloc] initWithRequest:request
                                                                name:name
                                                                icon:icon
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
                                                                icon:[info objectForKey:@"icon"]
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
    
    [_currentDownloads removeObject:download];
    [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] 
                      withRowAnimation:UITableViewRowAnimationFade];
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

- (UITableViewCell*)cellForDownload:(SafariDownload*)download
{
  NSUInteger row = [_currentDownloads indexOfObject:download];
  UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
  return cell;
}

#pragma mark -
#pragma mark SafariDownloadDelegate Methods

- (void)downloadDidBegin:(SafariDownload*)download
{
  UITableViewCell *cell = [self cellForDownload:download];
  cell.detailTextLabel.text = @"Downloading...";
}

- (void)downloadDidFinish:(SafariDownload*)download
{
  NSLog(@"downloadDidFinish");
  UITableViewCell *cell = [self cellForDownload:download];
  
  if (cell == nil) {
    return;
  }
  
  cell.detailTextLabel.text = @"Download Complete";
  
  NSUInteger row = [_currentDownloads indexOfObject:download];
  [_currentDownloads removeObject:download];

  [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] 
                    withRowAnimation:UITableViewRowAnimationFade]; 
  
  [self saveData];
}

- (void)downloadDidUpdate:(SafariDownload*)download
{
  UITableViewCell *cell = [self cellForDownload:download];
  progressViewForCell(cell).progress = download.progress;
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1fKB/sec", download.speed];
}

- (void)downloadDidFail:(SafariDownload*)download
{
  UITableViewCell *cell = [self cellForDownload:download];
  cell.detailTextLabel.text = @"Download Failed";
}

#pragma mark -
#pragma mark UIViewController Methods

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

#pragma mark -
#pragma mark UITableView methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_currentDownloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"DownloadCell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) 
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
    cell.opaque = YES;
    cell.backgroundColor = [UIColor whiteColor];
    UIProgressView *progressView = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
    progressView.frame = CGRectMake(5, 45, _tableView.frame.size.width - 10, 8);
    progressView.tag = kProgressViewTag;
    [cell addSubview:progressView];
  }
  
  SafariDownload *download = [_currentDownloads objectAtIndex:indexPath.row];
  
  // Set up the cell...
  cell.imageView.image = [UIImage imageNamed:download.icon];
	cell.textLabel.text  = download.filename;
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1fKB/sec", download.speed];
  progressViewForCell(cell).progress = download.progress;
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 89; 
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

- (NSString *)tableView:(UITableView *)table titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 0)
    return @"Cancel"; 
  else // local files
    return @"Delete";
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [self cancelDownload:[_currentDownloads objectAtIndex:indexPath.row]];
  }
}

@end

// vim:filetype=objc:ts=2:sw=2:expandtab