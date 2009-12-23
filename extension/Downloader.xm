#import "DHHookCommon.h"
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
#import <QuartzCore/QuartzCore.h>
#import "Safari/TabDocument.h"
#import <WebKit/DOMHTMLAnchorElement.h>

char __attribute((section("__MISC, UDID"))) udid[41] = "0000000000000000000000000000000000000000";

@interface UIActionSheet (Private)
-(id)buttons;
@end

DHLateClass(DOMHTMLAnchorElement);

static void initCustomToolbar(void) {
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
  
  [buttonBar registerButtonGroup:1 
                     withButtons:portraitGroup 
                       withCount:6];
  [buttonBar registerButtonGroup:2 
                     withButtons:landscapeGroup 
                       withCount:6];
  
  if (cg == 1 || cg == 2)
    [buttonBar showButtonGroup:cg
                  withDuration:0];
}

#pragma mark General Hooks/*{{{*/
%hook Application
- (void)applicationDidFinishLaunching:(UIApplication *)application {
  %orig;
  initCustomToolbar();
}

- (void)applicationResume:(GSEventRef)event {
  %orig;
  [[DownloadManager sharedManager] updateUserPreferences];
  [[DownloadManager sharedManager] updateFileTypes];
}

- (void)applicationOpenURL:(NSURL *)url {
  DownloadManager *shared = [DownloadManager sharedManager];
  if([shared isVisible]) {
    [shared hideDownloadManager];
    shared.loadingURL = url;
    return;
  }
  %orig;
}
%end

%hook BrowserButtonBar - (void)positionButtons:(NSArray *)buttons tags:(int *)tags count:(int)count group:(int)group {
  %orig;

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
    if(tag == 61)
      [[DownloadManager sharedManager] setPortraitDownloadButton:button];
    else if(tag == 62)
      [[DownloadManager sharedManager] setLandscapeDownloadButton:button];

    curButton++;
  }
  return;
}
%end

%hook BrowserController -(id)_panelForPanelType:(int)type {
  if(type == 44)
    return [[DownloadManager sharedManager] browserPanel];
  if (type == 88)
    return [DownloadOperation authView];
  return %orig;
}
%end

#pragma mark -/*}}}*/
#pragma mark Hooked WebViewPolicyDelegate Methods (TabDocument)/*{{{*/

%hook TabDocument
               - (void)webView:(WebView *)view
decidePolicyForNewWindowAction:(NSDictionary *)action
                       request:(NSURLRequest *)request
                  newFrameName:(NSString *)newFrameName
              decisionListener:(id<WebPolicyDecisionListener>)decisionListener {
  DownloadManager* downloader = [DownloadManager sharedManager];
  NSURLRequest* _currentRequest = downloader.currentRequest;
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    NSLog(@"WDW: SAME REQUEST");
    NSLog(@"#####################################################");
    %orig;
    return;
  }
    
  SDActionType _act = [downloader webView:view 
                             decideAction:action 
                               forRequest:request 
                             withMimeType:nil 
                                  inFrame:nil 
                             withListener:decisionListener];
  
  if (_act == SDActionTypeView) {
    NSLog(@"SDActionTypeView, saving request");
    downloader.currentRequest = request;
  }
  
  if(_act == SDActionTypeView || _act == SDActionTypeNone) {
    NSLog(@"WDW: not handled");
    NSLog(@"#####################################################");
    %orig;
    
  }
  else { // if (_act == SDActionTypeDownload || action == SDActionTypeCancel) {
    NSLog(@"WDW: handled");
    NSLog(@"#####################################################");
    [[DHClass(BrowserController) sharedBrowserController] setResourcesLoading:NO];
  }
}
#define MIMETYPE_ORIG webView:decidePolicyForMIMEType:request:frame:decisionListener:
#define MIMETYPE_HOOK webView$decidePolicyForMIMEType$request$frame$decisionListener$

                - (void)webView:(WebView *)view
decidePolicyForNavigationAction:(NSDictionary *)action
                        request:(NSURLRequest *)request
                          frame:(WebFrame *)frame
               decisionListener:(id<WebPolicyDecisionListener>)decisionListener {
  NSLog(@"NAV: decidePolicyForNavigationAction, req: %@", request);
  
  DownloadManager* downloader = [DownloadManager sharedManager];
  NSURLRequest* _currentRequest = downloader.currentRequest;
  NSLog(@"NAV: req: %@ - cur: %@", request, _currentRequest);
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    NSLog(@"NAV: SAME REQUEST");
    NSLog(@"#####################################################");
    %orig;
    return;
  }
      
  SDActionType _act = [downloader webView:view 
                             decideAction:action 
                               forRequest:request 
                             withMimeType:nil 
                                  inFrame:frame 
                             withListener:decisionListener];
  
  if (_act == SDActionTypeView) {
    NSLog(@"SDActionTypeView, saving request");
    downloader.currentRequest = request;
  }
  
  if (_act == SDActionTypeView || _act == SDActionTypeNone) {
    NSLog(@"NAV: not handled");
    NSLog(@"#####################################################");
    %orig;
  }
  else { // if (_act == SDActionTypeDownload || action == SDActionTypeCancel) {
    NSLog(@"NAV: handled");
    NSLog(@"#####################################################");
    [[DHClass(BrowserController) sharedBrowserController] setResourcesLoading:NO];
  }
}

        - (void)webView:(WebView *)view
decidePolicyForMIMEType:(NSString *)type
                request:(NSURLRequest *)request
                  frame:(WebFrame *)frame
       decisionListener:(id<WebPolicyDecisionListener>)decisionListener {
  NSLog(@"MIME: decidePolicyForMIMEType %@, request: @", type, request);
  
  DownloadManager* downloader = [DownloadManager sharedManager];
  NSURLRequest* _currentRequest = downloader.currentRequest;
  NSLog(@"MIME: req: %@ - cur: %@", request, _currentRequest);
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    NSLog(@"MIME: SAME REQUEST");
    downloader.currentRequest = nil;
    NSLog(@"#####################################################");
    %orig;
    return;
  }

  SDActionType action = [downloader webView:view 
                               decideAction:nil 
                                 forRequest:request 
                               withMimeType:type 
                                    inFrame:frame 
                               withListener:decisionListener];
  
  if (action == SDActionTypeView || action == SDActionTypeNone) {
    NSLog(@"MIME: not handled");
    NSLog(@"#####################################################");
    %orig;
  }
  else {
    NSLog(@"MIME: handled");
    NSLog(@"#####################################################");
    [[DHClass(BrowserController) sharedBrowserController] setResourcesLoading:NO];
  }
}
%end
#pragma mark -/*}}}*/
#pragma mark Hooks for Tap-Hold Download/*{{{*/
struct interaction {
  NSTimer* timer;
  CGPoint location;
  BOOL isBlocked;
  BOOL isCancelled;
  BOOL isOnWebThread;
  BOOL isDisplayingHighlight;
  BOOL attemptedClick;
  BOOL isGestureScrolling;
  CGPoint gestureScrollPoint;
  CGPoint gestureCurrentPoint;
  BOOL hasAttemptedGestureScrolling;
  UIView* candidate;
  BOOL forwardingGuard;
  SEL mouseUpForwarder;
  SEL mouseDraggedForwarder;
  DOMNode* element;
  BOOL defersCallbacksState;
  UIInformalDelegate* delegate;
  int interactionSheetType;
  UIActionSheet* interactionSheet;
  BOOL allowsImageSheet;
  BOOL allowsDataDetectorsSheet;
  struct {
    BOOL active;
    BOOL defaultPrevented;
    NSMutableArray* regions;
  } directEvents;
};

static NSURL *interactionURL = nil;

%hook UIWebDocumentView
- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(int)index {
  if(index == 1336) {
    if(interactionURL)
      [[DownloadManager sharedManager] addDownloadWithURL:interactionURL];
  }
  %orig;
  [interactionURL release];
  interactionURL = nil;
}

- (void)showBrowserSheet:(id)sheet {
  struct interaction i = MSHookIvar<struct interaction>(self, "_interaction");
  Class DOMHTMLAnchorElement = $DOMHTMLAnchorElement;
//  int sheetType = i.interactionSheetType;
//  if(sheetType == 3) {
    UIActionSheet *iSheet = i.interactionSheet;
    NSMutableArray *buttons = [sheet buttons];
    id domElement = i.element;
    id myButton;
    if(![domElement isKindOfClass:DOMHTMLAnchorElement]) {
      domElement = [domElement parentNode];
    }
    if([domElement isKindOfClass:DOMHTMLAnchorElement]) {
      interactionURL = [[domElement absoluteLinkURL] copy];
      NSString *scheme = [interactionURL scheme];
      if([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]
      || [scheme isEqualToString:@"ftp"]) {
        [iSheet addButtonWithTitle:@"Download"];
        myButton = [buttons lastObject];
        [myButton retain];
        [myButton setTag:1337];
        [buttons removeObject:myButton];
        [buttons insertObject:myButton atIndex:0];
        [myButton release];
        [iSheet setDestructiveButtonIndex:0];
        [iSheet setCancelButtonIndex:([buttons count] - 1)];
      } else {
        [interactionURL release];
        interactionURL = nil;
      }
    }
//  }
  %orig;
}
%end
#pragma mark -/*}}}*/

void ReloadPrefsNotification (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  [[DownloadManager sharedManager] updateUserPreferences];
  [[DownloadManager sharedManager] updateFileTypes];
}

static _Constructor void DownloaderInitialize() {	
  DHScopedAutoreleasePool();

  %init;

  CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
  CFNotificationCenterAddObserver(r, 
                                  NULL, 
                                  &ReloadPrefsNotification, 
                                  CFSTR("net.howett.safaridownloader/ReloadPrefs"), 
                                  NULL, 
                                  0);
}

// vim:filetype=objc:ts=2:sw=2:expandtab
