#import "DHHookCommon.h"
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
#import "ModalAlert.h"
#import "UIKitExtra/UIToolbarButton.h"
#import "Safari/BrowserController.h"
#import "Safari/BrowserButtonBar.h"
#import <QuartzCore/QuartzCore.h>
#import <WebKit/WebView.h>

#import "Safari/TabDocument.h"

// Numerical and Structural String Formatting Macros
#define iF(i) [NSString stringWithFormat:@"%d", i]
#define fF(f) [NSString stringWithFormat:@"%.2f", f]
#define bF(b) [NSString stringWithFormat:@"%@", b ? @"true" : @"false"]
#define sF(inset) NSStringFromUIEdgeInsets(inset)

#ifndef DEBUG
#define NSLog(...)
#endif

@class Downloader;
static Downloader *downloader = nil;
static id _currentRequest;

@class BrowserButtonBar;
@interface BrowserButtonBar (mine)
- (NSArray*)buttonItems;
- (void)setButtonItems:(NSArray *)its;
- (void)showButtonGroup:(int)group withDuration:(double)duration;
- (void)registerButtonGroup:(int)group withButtons:(int*)buttons withCount:(int)count;
- (id)$$createButtonWithDescription:(id)description;
@end

@interface Downloader : NSObject <UIActionSheetDelegate> {
}

@end

@implementation Downloader

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
  [super dealloc]; 
}

- (void)loadCustomToolbar
{
  Class BrowserController = objc_getClass("BrowserController");
  Class BrowserButtonBar = objc_getClass("BrowserButtonBar");
  BrowserController *bcont = [BrowserController sharedBrowserController];
  BrowserButtonBar *buttonBar = MSHookIvar<BrowserButtonBar *>(bcont, "_buttonBar");
  CFMutableDictionaryRef _groups = MSHookIvar<CFMutableDictionaryRef>(buttonBar, "_groups");
  int cg = MSHookIvar<int>(buttonBar, "_currentButtonGroup");
  NSArray *_buttonItems = [buttonBar buttonItems];
  
  id x = [BrowserButtonBar imageButtonItemWithName:@"Download.png"
                                               tag:61
                                            action:@selector(showDownloadManager)
                                            target:[NSValue valueWithNonretainedObject:[DownloadManager sharedManager]]];
  id y = [BrowserButtonBar imageButtonItemWithName:@"DownloadSmall.png"
                                               tag:62
                                            action:@selector(showDownloadManager)
                                            target:[NSValue valueWithNonretainedObject:[DownloadManager sharedManager]]];
  
  NSMutableArray *mutButtonItems = [_buttonItems mutableCopy];

  [mutButtonItems addObject:x];
  [mutButtonItems addObject:y];
  [buttonBar setButtonItems:mutButtonItems];
  [mutButtonItems release];
  
  int portraitGroup[]  = {5, 7, 15, 1, 61, 3};
  int landscapeGroup[] = {6, 8, 16, 2, 62, 4};
  
  CFDictionaryRemoveValue(_groups, (void*)1);
  CFDictionaryRemoveValue(_groups, (void*)2);
  
  [buttonBar registerButtonGroup:1 withButtons:portraitGroup withCount:6];
  [buttonBar registerButtonGroup:2 withButtons:landscapeGroup withCount:6];
  
  if (cg == 1 || cg == 2)
    [buttonBar showButtonGroup:cg withDuration:0]; // duration appears to either be ignored or is somehow related to animations
}

#pragma mark -/*}}}*/
#pragma mark Download Management/*{{{*/

typedef enum
{
  SDActionTypeView = 1,
  SDActionTypeDownload = 2,
  SDActionTypeCancel = 3,
} SDActionType;

static SDActionType _actionType = SDActionTypeView;

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"])
  {
    _actionType = SDActionTypeCancel;
  }
  else if([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"View"]) 
  {
    _actionType = SDActionTypeView;
  }
  else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Download"])
  {
    _actionType = SDActionTypeDownload;
  }
}

#pragma mark -/*}}}*/
#pragma mark WebKit WebPolicyDelegate Methods/*{{{*/

// WebPolicyDelegate SafariDownloader Addition
//BOOL decidePolicy(WebView *webView, NSDictionary *action, NSURLRequest *request, NSString *mimeType, WebFrame *frame, id<WebPolicyDecisionListener> listener) {
- (BOOL) webView:(WebView *)webView 
    decideAction:(NSDictionary*)action
      forRequest:(NSURLRequest *)request 
    withMimeType:(NSString *)mimeType 
         inFrame:(WebFrame *)frame
    withListener:(id<WebPolicyDecisionListener>)listener
{
  NSString *url = [[request URL] absoluteString];
  
  if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"] && ![url hasPrefix:@"ftp://"]) {
    NSLog(@"not a valid http url, continue.");
    return NO;
  }
  
  if ([[DownloadManager sharedManager] supportedRequest:request withMimeType:mimeType]) {
    NSString *filename = [[DownloadManager sharedManager] fileNameForURL:[request URL]];
    if (filename == nil) {
      filename = [[request URL] absoluteString];
    }
    
    NSString *other;
    if(mimeType) other = [objc_getClass("WebView") canShowMIMEType:mimeType] ? @"View" : nil;
    else other = @"View";
    
    [ModalAlert showDownloadActionSheetWithTitle:@"What would you like to do?"
                                         message:filename
                                        mimetype:mimeType
                                    cancelButton:@"Cancel"
                                     destructive:@"Download"
                                           other:other
                                        delegate:self];
    
    if (_actionType == SDActionTypeView) 
      return NO;
    else if (_actionType == SDActionTypeDownload) {
      [listener ignore];
      [frame stopLoading];
      BOOL downloadAdded;
      if(mimeType != nil)
        downloadAdded = [[DownloadManager sharedManager] addDownloadWithRequest:request andMimeType:mimeType];
      else
        downloadAdded = [[DownloadManager sharedManager] addDownloadWithRequest:request];

      if (downloadAdded)
        NSLog(@"successfully added download");
      else
        NSLog(@"add download failed");
      return YES;
    } 
    else {
      [listener ignore];
      [frame stopLoading];
    }
    return YES;
  }
  else 
    return NO;
  return NO;
}
#pragma mark -/*}}}*/
@end

#pragma mark Renamed Methods/*{{{*/
@class WebView;
HOOK(Application, applicationDidFinishLaunching$, void, UIApplication *application) {
  CALL_ORIG(Application, applicationDidFinishLaunching$, application);
  [downloader loadCustomToolbar];
  [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

HOOK(Application, applicationResume$, void, GSEventRef event) {
  CALL_ORIG(Application, applicationResume$, event);
  [[DownloadManager sharedManager] updateFileTypes];
}

HOOK(BrowserButtonBar, positionButtons$tags$count$group$, void, id buttons, int *tags, int count, int group) {
  CALL_ORIG(BrowserButtonBar, positionButtons$tags$count$group$, buttons, tags, count, group);
  if(group != 1 && group != 2) {
    return;
  }

  NSLog(@"Button array: %@", [buttons description]);
  float maxWidth = self.frame.size.width;
  float buttonBoxWidth = floorf(maxWidth / count);
  if((int)buttonBoxWidth % 2 == 1) buttonBoxWidth -= 1.0f;
  float curX = 0;
  float maxX = buttonBoxWidth;
  int curButton = 0;
  float YOrigin = 2; //(group == 1) ? 2 : 0;
  for(UIToolbarButton *button in buttons) {
    curX = curButton * buttonBoxWidth;
    maxX = curX + buttonBoxWidth;
    float curWidth = button.frame.size.width;
    float curHeight = button.frame.size.height;
    float newXOrigin = maxX - (buttonBoxWidth / 2.0) - (curWidth / 2.0);
    [button setFrame:CGRectMake(newXOrigin, YOrigin, curWidth, curHeight)];
    
    int tag = button.tag;
    if(tag == 61) [[DownloadManager sharedManager] setPortraitDownloadButton:button];
    else if(tag == 62) [[DownloadManager sharedManager] setLandscapeDownloadButton:button];

    curButton++;
  }
  return;
}

HOOK(BrowserController, _panelForPanelType$, id, int type) {
  if(type == 44)
    return [[DownloadManager sharedManager] browserPanel];
  if (type == 88)
    return [DownloadOperation authView];
  return CALL_ORIG(BrowserController, _panelForPanelType$, type);
}

#pragma mark -/*}}}*/
#pragma mark Hooked WebViewPolicyDelegate Methods (TabDocument)/*{{{*/
HOOK(TabDocument,
     webView$decidePolicyForNavigationAction$request$frame$decisionListener$,
     void,
     WebView *view,
     NSDictionary *action,
     NSURLRequest *request,
     WebFrame *frame,
     id<WebPolicyDecisionListener> decisionListener) {
  NSLog(@"NAV: decidePolicyForNavigationAction!!!!!!");
  NSLog(@"NAV: action: %@", action);
  NSLog(@"NAV: request: %@", request);
  NSLog(@"NAV: Listener!: %@", decisionListener);
  
  BOOL handled = [downloader webView:view decideAction:action forRequest:request withMimeType:nil inFrame:frame withListener:decisionListener];
  if(!handled) CALL_ORIG(TabDocument, webView$decidePolicyForNavigationAction$request$frame$decisionListener$, view, action, request, frame, decisionListener);
}

HOOK(TabDocument,
     webView$decidePolicyForNewWindowAction$request$newFrameName$decisionListener$,
     void,
     WebView *view,
     NSDictionary *action,
     NSURLRequest *request,
     NSString *newFrameName,
     id<WebPolicyDecisionListener> decisionListener) {
  BOOL handled = [downloader webView:view decideAction:action forRequest:request withMimeType:nil inFrame:nil withListener:decisionListener];
  if(!handled) CALL_ORIG(TabDocument, webView$decidePolicyForNewWindowAction$request$newFrameName$decisionListener$, view, action, request, newFrameName, decisionListener);
}

HOOK(TabDocument,
     webView$decidePolicyForMIMEType$request$frame$decisionListener$,
     void,
     WebView *view,
     NSString *type,
     NSURLRequest *request,
     WebFrame *frame,
     id<WebPolicyDecisionListener> decisionListener) {
  NSLog(@"MIME: decidePolicyForMIMEType!!!!!!");
  NSLog(@"MIME: type: %@", type);
  NSLog(@"MIME: request: %@", request);
  NSLog(@"MIME: Listener!: %@", decisionListener);
  NSLog(@"URLSTRING: %@", [[request URL] absoluteString]);
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    [_currentRequest release];
    _currentRequest = nil;
    CALL_ORIG(TabDocument, webView$decidePolicyForMIMEType$request$frame$decisionListener$, view, type, request, frame, decisionListener);
    return;
  }

  BOOL handled = [downloader webView:view decideAction:nil forRequest:request withMimeType:type inFrame:frame withListener:decisionListener];
  if(!handled) CALL_ORIG(TabDocument, webView$decidePolicyForMIMEType$request$frame$decisionListener$, view, type, request, frame, decisionListener);
}
#pragma mark -/*}}}*/

extern "C" void DownloaderInitialize() {	
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
  downloader = [[Downloader alloc] init];
  GET_CLASS(Application);
  HOOK_MESSAGE_F(Application, applicationDidFinishLaunching:, applicationDidFinishLaunching$);
  HOOK_MESSAGE_F(Application, applicationResume:, applicationResume$);

  GET_CLASS(BrowserButtonBar);
  HOOK_MESSAGE_F(BrowserButtonBar, positionButtons:tags:count:group:, positionButtons$tags$count$group$);

  GET_CLASS(BrowserController);
  HOOK_MESSAGE_F(BrowserController, _panelForPanelType:, _panelForPanelType$);

  GET_CLASS(TabDocument);
  HOOK_MESSAGE_F(TabDocument, webView:decidePolicyForNavigationAction:request:frame:decisionListener:, webView$decidePolicyForNavigationAction$request$frame$decisionListener$);
  HOOK_MESSAGE_F(TabDocument, webView:decidePolicyForNewWindowAction:request:newFrameName:decisionListener:, webView$decidePolicyForNewWindowAction$request$newFrameName$decisionListener$);
  HOOK_MESSAGE_F(TabDocument, webView:decidePolicyForMIMEType:request:frame:decisionListener:, webView$decidePolicyForMIMEType$request$frame$decisionListener$);
  [pool release];
}

// vim:filetype=objc:ts=2:sw=2:expandtab
