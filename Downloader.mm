#include "substrate.h"
#import <objc/runtime.h>
#import "Safari/BrowserController.h"
#import "UIKitExtra/UIWebDocumentView.h"
#import "NSURLDownload.h"
#import "Safari/PageLoad.h"
#import "UIKitExtra/UIWebViewWebViewDelegate.h"
#import "Safari/Application.h"
#import "WebPolicyDelegate.h"
#import "DownloadManager.h"


@class Downloader;
static Downloader *downloader = nil;

@protocol RenamedMethods
- (void)WV$setPolicyDelegate:(id)delegate;
- (void)AP$applicationDidFinishLaunching:(id)application;
@end

static UIWebDocumentView<RenamedMethods> *docView = nil;

@interface Downloader : NSObject <UIAlertViewDelegate>
{
  NSURLRequest* _currentRequest;
}

- (void)downloadFile:(NSString *)file;

@end

void omfg(const void *k, const void *i, void *c) {
  int key = (int)k;
  int *v = (int*)i;
  NSLog(@"%p = %x %x %x", v, v[0], v[1], v[2]);
}

@implementation Downloader

static UINavigationController *controller = nil;

- (id)init {
	self = [super init];
	if(self != nil) 
  {
    NSLog(@"Downloader class allocated!");
    
	}
	return self;
}

- (void)dealloc
{
  [_currentRequest release];
  [super dealloc]; 
}

- (void)applicationDidFinishLaunching
{
  Class BrowserController = objc_getClass("BrowserController");
  Class BrowserButtonBar = objc_getClass("BrowserButtonBar");
  //    Class BrowserButtonBar = objc_getClass("BrowserButtonBar");
  NSLog(@"BrowserController: %@", [BrowserController sharedBrowserController]);

  BrowserController *bcont = [BrowserController sharedBrowserController];

//  Ivar buttonBarIvar = object_getInstanceVariable(bcont, "_buttonBar", NULL);
//  UIToolbar* buttonBar = (UIToolbar*)object_getIvar(bcont, buttonBarIvar);
  BrowserButtonBar *buttonBar = MSHookIvar<BrowserButtonBar *>(bcont, "_buttonBar");
  NSLog(@"buttonBar: %@", buttonBar);
  CFMutableDictionaryRef _groups = MSHookIvar<CFMutableDictionaryRef>(buttonBar, "_groups");
  int cg = MSHookIvar<int>(buttonBar, "_currentButtonGroup");
  NSLog(@"Current Button Group: %d", cg);
  //CFShow(_groups);

//  NSLog(@"%@", _groups);
/*
  NSArray* items = [buttonBar items];
  NSMutableArray* mutItems = [items mutableCopy];
  [items release];
  NSLog(@"current items: %@", mutItems); */
//  UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(showDownloadManager)];
  //[buttonBar createButtonWithDescription:@"Downloads"];
//  +(id)imageButtonItemWithName:(id)name tag:(int)tag action:(SEL)action target:(id)target
  // The reallocs here ARE correct. UIKit uses malloc when it first sets these.
/*  int *oldPortraitGroup = (int*)CFDictionaryGetValue(_groups, (void*)1); // {{{
  int *oldLandscapeGroup = (int*)CFDictionaryGetValue(_groups, (void*)2);
  int *newPortraitGroup = (int*)realloc(oldPortraitGroup, oldPortraitGroup[0]+2 * sizeof(int));
  int *newLandscapeGroup = (int*)realloc(oldLandscapeGroup, oldLandscapeGroup[0]+2 * sizeof(int));
  newPortraitGroup[0] = 6; newPortraitGroup[5] = 17; newPortraitGroup[6] = 3;
  newLandscapeGroup[0] = 6; newLandscapeGroup[5] = 18; newLandscapeGroup[6] = 4;
  CFDictionarySetValue(_groups, (void*)1, (void*)newPortraitGroup);
  CFDictionarySetValue(_groups, (void*)2, (void*)newLandscapeGroup); */ // }}}
  NSArray *_buttonItems = [buttonBar buttonItems];

//  id x = [BrowserButtonBar imageButtonItemWithName:@"NavDownloads.png" tag:17 action:@selector(showDownloadManager) target:self];
//  id y = [BrowserButtonBar imageButtonItemWithName:@"NavDownloadsSmall.png" tag:18 action:@selector(showDownloadManager) target:self];
  id x = [BrowserButtonBar imageButtonItemWithName:@"NavDownloads.png" tag:17 action:nil target:nil];
  id y = [BrowserButtonBar imageButtonItemWithName:@"NavDownloadsSmall.png" tag:18 action:nil target:nil];
  NSMutableArray *mutButtonItems = [_buttonItems mutableCopy];
  [mutButtonItems addObject:x];
  [mutButtonItems addObject:y];
  [buttonBar setButtonItems:mutButtonItems];
  [mutButtonItems release];

  int portraitGroup[] = {5, 7, 15, 1, 17, 3};
  int landscapeGroup[] = {6, 8, 16, 2, 18, 4};
  int *oldPortraitGroup = (int*)CFDictionaryGetValue(_groups, (void*)1);
  int *oldLandscapeGroup = (int*)CFDictionaryGetValue(_groups, (void*)2);
  CFDictionaryRemoveValue(_groups, (void*)1);
  CFDictionaryRemoveValue(_groups, (void*)2);
  free(oldPortraitGroup); free(oldLandscapeGroup);
  [buttonBar registerButtonGroup:1 withButtons:portraitGroup withCount:6];
  [buttonBar registerButtonGroup:2 withButtons:landscapeGroup withCount:6];
/*  [mutItems addObject:item];
  [buttonBar setItems:[mutItems copy]];
  NSLog(@"new items: %@", [buttonBar items]);
  [mutItems release];*/
//  [buttonBar addSubview:[item createViewForToolbar:buttonBar]];
}

#pragma mark Download Manager UI Control /* {{{ */

- (void)showDownloadManager
{
  DownloadManager* dlManager = [DownloadManager sharedManager];
  controller = [[UINavigationController alloc] initWithRootViewController:[DownloadManager sharedManager]];
  UIBarButtonItem *doneItemButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideDownloadManager)];
  dlManager.navigationItem.leftBarButtonItem = doneItemButton;
  dlManager.navigationItem.title = @"Downloads";
  [controller setNavigationBarHidden:NO];
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  [keyWindow addSubview:[controller view]];
}

- (void)hideDownloadManager
{
  NSLog(@"removing view: %@", [controller view]);
  [[controller view] removeFromSuperview];
}

#pragma mark - /* }}} */
#pragma mark Download Management /* {{{ */

- (void)queryUserForDownloadWithRequest:(NSURLRequest *)request
{  
  NSString *filename = [[[[request URL] absoluteString] lastPathComponent] 
                        stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  
  UIAlertView *lulz = [[UIAlertView alloc] initWithTitle:@"Download?" 
                                                 message:filename
                                                delegate:self 
                                       cancelButtonTitle:@"No" 
                                       otherButtonTitles:nil];
  [lulz addButtonWithTitle:@"Yes"];
  
  NSString *impr = @"/var/mobile/Media/SafariDownloader/images";
  NSString *icn = [[filename pathExtension] stringByAppendingString:@".png"];
  NSLog(@"trying path: %@", [impr stringByAppendingPathComponent:icn]);
  if (![[NSFileManager defaultManager] 
        fileExistsAtPath:[impr stringByAppendingPathComponent:icn]])
    icn = @"unknown.png";
  NSString *path = [impr stringByAppendingPathComponent:icn];
  NSLog(@"chose path: %@", path);
  
  UIImageView *mmicon = [[UIImageView alloc] 
                         initWithImage:[UIImage imageWithContentsOfFile:path]];
  mmicon.frame = CGRectMake(40.0f, 19.0f, 22.0f, 22.0f);
  [lulz addSubview:mmicon];
  [mmicon release];    
  
  [lulz show];
  [lulz release];
  
  [_currentRequest release];
  _currentRequest = [request retain];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (   [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"] 
      || [[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"No"]) 
  {
    [docView loadRequest:_currentRequest];
  }
  else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Yes"])
  {
    [self downloadFile:alertView.message];
  }
}

- (void)downloadFile:(NSString *)file
{
  NSLog(@"downloadFile %@: currentRequest: %@", file, _currentRequest);
  
  if ([[DownloadManager sharedManager] addDownloadWithRequest:_currentRequest])
    NSLog(@"successfully added download");
  else
    NSLog(@"add download failed");
  
  [_currentRequest release];
  _currentRequest = nil;
}

#pragma mark - /* }}} */
#pragma mark WebKit WebPolicyDelegate Methods /* {{{ */

- (void) webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)action 
         request:(NSURLRequest *)request 
    newFrameName:(NSString *)name 
decisionListener:(id<WebPolicyDecisionListener>)listener {
  
  NSLog(@"NEWWINDOW: decidePolicyForNewWindowAction!!!!!!");
  NSLog(@"NEWWINDOW: action: %@", action);
  NSLog(@"NEWWINDOW: request: %@", request);
  NSLog(@"NEWWINDOW: Listener!: %@", listener);
  [listener use];
}

- (void) webView:(WebView *)sender decidePolicyForMIMEType:(NSString *)type 
         request:(NSURLRequest *)request 
           frame:(WebFrame *)frame 
decisionListener:(id<WebPolicyDecisionListener>)listener {
  
  NSLog(@"MIME: decidePolicyForMIMEType!!!!!!");
  NSLog(@"MIME: type: %@", type);
  NSLog(@"MIME: request: %@", request);
  NSLog(@"MIME: Listener!: %@", listener);
  NSLog(@"URLSTRING: %@",[[request URL] absoluteString]);
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    NSLog(@"MIME: looks like we're hitting the same request, ignore");
    [_currentRequest release];
    _currentRequest = nil;
    [listener use];
    return;
  }
  
  if ([[DownloadManager sharedManager] supportedRequest:request withMimeType:type]) 
  {
    NSLog(@"MIME: yes we support it");
    [listener ignore];
    [self queryUserForDownloadWithRequest:request];
    return;    
  }
  else
  {
    NSLog(@"MIME: we do not support this request");
  }
  
  [listener use];
}

- (void) webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)action 
         request:(NSURLRequest *)request 
           frame:(WebFrame *)frame 
decisionListener:(id<WebPolicyDecisionListener>)listener {
  
  NSLog(@"NAV: decidePolicyForNavigationAction!!!!!!");
  NSLog(@"NAV: action: %@", action);
  NSLog(@"NAV: request: %@", request);
  NSLog(@"NAV: Listener!: %@", listener);
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    NSLog(@"NAV: looks like we're hitting the same request, ignore");
    [_currentRequest release];
    _currentRequest = nil;
    [listener use];
    return;
  }
  
  if ([[DownloadManager sharedManager] supportedRequest:request withMimeType:nil]) 
  {
    NSLog(@"NAV: yes we support it");
    [listener ignore];
    [self queryUserForDownloadWithRequest:request];
    return;    
  }
  else
  {
    NSLog(@"NAV: we do not support this request");
  }
  
  [listener use];
}

@end

#pragma mark - /* }}} */
#pragma mark Renamed Methods /* {{{ */

@class WebView;
static void _setPolDel(WebView<RenamedMethods> *self, SEL sel, id delegate)
{
  NSLog(@"WANTS TO SET delegate: %@", delegate);
  [self WV$setPolicyDelegate:downloader];
}

@class Application;
static void _appLaunchedAwesome(Application<RenamedMethods> *self, SEL sel, id application) {
  [self AP$applicationDidFinishLaunching:application];
  [downloader applicationDidFinishLaunching];
}

#pragma mark - /* }}} */

#include <DHHookCommon.h>
HOOK(BrowserButtonBar, registerButtonGroup$withButtons$withCount$, void, int group, int *buttons, int count) {
  CALL_ORIG(BrowserButtonBar, registerButtonGroup$withButtons$withCount$, group, buttons, count);
  NSLog(@"registerButtonGroup:%d withButtons:%d withCount:%d", group, buttons, count);
  int i = 0;
  for(i = 0; i <count; i++) {
    NSLog(@"rbg.. button %d is %d", i, buttons[i]);
  }
}

extern "C" void DownloaderInitialize() {	
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
  
  downloader = [[Downloader alloc] init];
  MSHookMessage(NSClassFromString(@"WebView"), @selector(setPolicyDelegate:), (IMP)&_setPolDel, "WV$");
  MSHookMessage(objc_getClass("Application"), @selector(applicationDidFinishLaunching:), (IMP)&_appLaunchedAwesome, "AP$");
  GET_CLASS(BrowserButtonBar);
  HOOK_MESSAGE_F(BrowserButtonBar, registerButtonGroup:withButtons:withCount:, registerButtonGroup$withButtons$withCount$);

  [pool release];
}

/* Deprecated Hooks {{{
 
 @protocol RenamedMethods
 - (id)DL$init;
 - (void)DL$setupWithURL:(NSURL*)url;
 - (void)DL$loadURL:(NSURL*)url;
 - (void)WF$loadRequest:(NSURLRequest *)req;
 - (void)DL$loadRequest:(NSURLRequest *)req;
 - (void)DL$loadHTMLString:(id)string baseURL:(id)url;
 - (void)DL$loadData:(id)data MIMEType:(id)type textEncodingName:(id)name baseURL:(id)url;
 - (void)DL$goToAddress:(id)address fromAddressView:(id)addressView;
 - (void)DL$start:(id)start;
 - (void)RC$reachabilityChanged:(id)changed;
 @end
 
//    MSHookMessage(NSClassFromString(@"BrowserController"), @selector(loadURL:userDriven:), (IMP)&_loadURL, "DL$");
//    MSHookMessage(NSClassFromString(@"BrowserController"), @selector(setupWithURL:), (IMP)&_setup, "DL$");
//    MSHookMessage(NSClassFromString(@"TabDocument"), @selector(_reachabilityChanged:), (IMP)&$reachabilityChanged, "RC$");
//    MSHookMessage(NSClassFromString(@"UIWebDocumentView"), @selector(loadRequest:), (IMP)&_loadreq, "DL$");
//    MSHookMessage(NSClassFromString(@"UIWebDocumentView"), @selector(loadData:MIMEType:textEncodingName:baseURL:), (IMP)&_loadData, "DL$");
//    MSHookMessage(NSClassFromString(@"PageLoad"), @selector(initWithURL:), (IMP)&_initWURL, "DL$");
//    MSHookMessage(NSClassFromString(@"PageLoad"), @selector(start:), (IMP)&_start, "DL$");
 
static void _setup(BrowserController<RenamedMethods> *self, SEL sel, NSURL *url)
{
 NSLog(@"SETUPWITHURL CALLED! URL: %@", url);
 [self DL$setupWithURL:url];
}
 
static void _loadreq(UIWebDocumentView<RenamedMethods> *self, SEL sel, NSURLRequest *req)
{
 NSLog(@"loading request: %@", [[req URL] absoluteString]);
 docView = [self retain];
 [self stopLoading:nil];
}
 
static void _loadData(UIWebDocumentView<RenamedMethods> *self, SEL sel, NSData *data, NSString *MIMEType, NSString *textEncodingName, NSURL *baseURL)
{
 NSLog(@"Data:%@\nMIMEType:%@\ntextEncodingName:%@\nbaseURL:%@", data, MIMEType, textEncodingName, baseURL);
 [self DL$loadData:data MIMEType:MIMEType textEncodingName:textEncodingName baseURL:baseURL];
}
 
static void _goto(BrowserController<RenamedMethods> *self, SEL sel, id address, id view)
{
 NSLog(@"GOTOADDRESS: %@ FROMVIEW: %@", address, view);
 [self DL$goToAddress:address fromAddressView:view];
}
 
static void _load2(WebFrame<RenamedMethods> *self, SEL sel, NSURLRequest *req)
{
 NSLog(@"GOTOADDRESS: %@", req);
 [self WF$loadRequest:req];
} 
 
static id _initWURL(PageLoad<RenamedMethods> *self, SEL sel, NSURL *url)
{
 NSLog(@"PAGELOAD: %@ - INITWITHURL ZOMG CALLED! URL: %@", self, url);
 return nil;
}
 
static void _start(PageLoad<RenamedMethods> *self, SEL sel, id wut)
{
 NSLog(@"PAGELOAD: %@ - Start! CALLED! %@", self, wut);
 [self DL$start:wut];
}
 
static void $reachabilityChanged(id self, SEL sel, id wut)
{
 NSLog(@"reachabilityChanged CALLED! %@ - val: %@", self, wut);
 [self RC$reachabilityChanged:wut];
}

}}} */

// vim:filetype=objc:ts=2:sw=2:expandtab
