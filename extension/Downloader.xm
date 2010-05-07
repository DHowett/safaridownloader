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
//#import <WebKit/DOMHTMLAnchorElement.h>
//typedef void* GSEventRef;

char __attribute((section("__MISC, UDID"))) udid[41] = "0000000000000000000000000000000000000000";

@interface UIActionSheet (Private)
-(id)buttons;
@end

%class BrowserController
%class DOMHTMLAnchorElement;

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
                                            action:@selector(toggleDownloadManagerFromButtonBar)
                                            target:[NSValue valueWithNonretainedObject:[$BrowserController sharedBrowserController]]];
  id y = [BrowserButtonBar imageButtonItemWithName:@"DownloadSmall.png"
                                               tag:62
                                            action:@selector(toggleDownloadManagerFromButtonBar)
                                            target:[NSValue valueWithNonretainedObject:[$BrowserController sharedBrowserController]]];
  
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

- (void)applicationWillSuspend {
  BrowserController *sbc = [$BrowserController sharedBrowserController];
  if([[sbc browserPanel] panelType] == 44)
    [sbc hideBrowserPanelType:44];
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
  if (type == 44) {
    %log;
    return [DownloadManagerNavigationController sharedInstance];
  }
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
/* {{{ struct interaction on 3.2+ */
struct interaction32 {
  NSTimer *timer;
  struct CGPoint location;
  char isBlocked;
  char isCancelled;
  char isOnWebThread;
  char isDisplayingHighlight;
  char attemptedClick;
  struct CGPoint lastPanTranslation;
  DOMNode *element;
  char defersCallbacksState;
  UIInformalDelegate *delegate;
  int interactionSheetType;
  UIActionSheet *interactionSheet;
  char allowsImageSheet;
  char allowsDataDetectorsSheet;
} _interaction32;
/* }}} */

/* {{{ struct interaction on < 3.2 */
struct interactionnot32 {
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
/* }}} */

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

static void showBrowserSheetHookInternals(UIWebDocumentView *self, UIActionSheet *sheet, DOMNode *&domElement) {
  NSMutableArray *buttons = [sheet buttons];
  id myButton;
  if(![domElement isKindOfClass:[$DOMHTMLAnchorElement class]]) {
    NSLog(@"not htmlanchorelement oh no %@", domElement);
    domElement = [domElement parentNode];
  }

  if([domElement isKindOfClass:[$DOMHTMLAnchorElement class]]) {
    NSLog(@"htmlanchorelement yay %@", domElement);
    interactionURL = [[domElement absoluteLinkURL] copy];
    NSString *scheme = [interactionURL scheme];
    NSLog(@"url is %@", interactionURL);
    if([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]
    || [scheme isEqualToString:@"ftp"]) {
      [sheet addButtonWithTitle:@"Download"];
      myButton = [buttons lastObject];
      [myButton retain];
      [myButton setTag:1337];
      [buttons removeObject:myButton];
      [buttons insertObject:myButton atIndex:0];
      [myButton release];
      [sheet setDestructiveButtonIndex:0];
      [sheet setCancelButtonIndex:([buttons count] - 1)];
    } else {
      [interactionURL release];
      interactionURL = nil;
    }
  }
}

%group Firmware_ge_32
- (void)showBrowserSheet:(id)sheet atPoint:(CGPoint)p {
  %log;
  struct interaction32 i = MSHookIvar<struct interaction32>(self, "_interaction");
  showBrowserSheetHookInternals(self, sheet, i.element);
  %orig;
}
%end

%group Firmware_lt_32
- (void)showBrowserSheet:(id)sheet {
  %log;
  struct interactionnot32 i = MSHookIvar<struct interactionnot32>(self, "_interaction");
  showBrowserSheetHookInternals(self, sheet, i.element);
  %orig;
}
%end
%end
#pragma mark -/*}}}*/

void ReloadPrefsNotification (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  [[DownloadManager sharedManager] updateUserPreferences];
  [[DownloadManager sharedManager] updateFileTypes];
}

#if 0
%hook NSBundle
- (id)localizedStringForKey:(id)key value:(id)value table:(id)table {
    //if([key isEqualToString:@"Add"]) [NSObject fuck];
  %log; return %orig;
}
%end
#endif
%hook BrowserController
- (void)_setShowingCurrentPanel:(BOOL)showing animate:(BOOL)animate {
  %log;
  id<BrowserPanel> panel = MSHookIvar<id>(self, "_browserPanel");
  /*
  if(!showing) {
    [self willHideBrowserPanel:panel];
  } else {
    [self willShowBrowserPanel:panel];
  }
  */
  %orig;
  if([panel panelType] == 44) {
    [MSHookIvar<id>(self, "_browserView") resignFirstResponder];
    [self _setShowingDownloads:showing animate:animate];
  }
  NSLog(@"DONE WITH -[BrowserController _setShowingCurrentPanel...]--");
}

%new(v@:ii)
- (void)_setShowingDownloads:(BOOL)showing animate:(BOOL)animate {
  if (showing) {
    [self _resizeNavigationController:[DownloadManagerNavigationController sharedInstance] small:NO];
    //[self _presentModalViewControllerFromDownloadsButton:[DownloadManagerNavigationController sharedInstance]]; // 3.2 ONLY
    
    // UITransitionView (non-wildcat only)
      UITransitionView* tr = MSHookIvar<UITransitionView*>(self, "_browserLayer");
      [tr transition:8 toView:[[DownloadManagerNavigationController sharedInstance] view]];
  } 
  else {
    [self willHideBrowserPanel:[DownloadManagerNavigationController sharedInstance]];
    //[self _forceDismissModalViewController:animate]; // 3.2 ONLY
    
    // UITransitionView (non-wildcat only)
    UITransitionView* tr = MSHookIvar<UITransitionView*>(self, "_browserLayer");
    [tr transition:9 toView:[self _panelSuperview]];
  }
}

%new(v@:@)
- (void)_presentModalViewControllerFromDownloadsButton:(id)x {
  // [self _presentModalViewControllerFromBookmarksButton:x]; // 3.2 ONLY
  
}

%new(v@:)
- (void)toggleDownloadManagerFromButtonBar {
  NSLog(@"-[BrowserController toggleDownloadManagerFromButtonBar]++");
  if([[self browserPanel] panelType] == 44) {
//    [[DownloadManagerNavigationController sharedInstance] close];
//    [self hideBrowserPanelType:44];
    [self hideBrowserPanelType:44];
    [self _setShowingDownloads:NO animate:YES];
  } else {
      [self showBrowserPanelType:44];
      [self _setShowingDownloads:YES animate:YES];
  }
  NSLog(@"-[BrowserController toggleDownloadManagerFromButtonBar]--");
}
//- (id)browserPanel {%log; return %orig;}
- (BOOL)showBrowserPanelType:(int)arg1 {
  %log;
  if (arg1 == 88 && [[self browserPanel] panelType] == 44) {
    [self hideBrowserPanelType:44];
    NSLog(@"showing authview, hide download list plz");
  }
  BOOL x = %orig;
  NSLog(@"------- showBrowserPanelType: %d", arg1); 
  return x;
}
- (BOOL)hideBrowserPanelType:(int)arg1 {
  %log;
  if (arg1 == 44) {
    [self _setShowingDownloads:NO animate:YES];
    return YES;
  }
  BOOL x = %orig;
  NSLog(@"------- hideBrowserPanelType: %d", arg1); 
  return x;
}
%end

static _Constructor void DownloaderInitialize() {	
  DHScopedAutoreleasePool();

  %init;
  if(class_getInstanceMethod(objc_getClass("UIWebDocumentView"), @selector(showBrowserSheet:atPoint:)) == NULL)
    %init(Firmware_lt_32);
  else
    %init(Firmware_ge_32);

  CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
  CFNotificationCenterAddObserver(r, 
                                  NULL, 
                                  &ReloadPrefsNotification, 
                                  CFSTR("net.howett.safaridownloader/ReloadPrefs"), 
                                  NULL, 
                                  0);
}

// vim:filetype=logos:ts=2:sw=2:expandtab
