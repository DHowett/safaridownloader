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

#define NAVACTION_ORIG webView:decidePolicyForNavigationAction:request:frame:decisionListener:
#define NAVACTION_HOOK webView$decidePolicyForNavigationAction$request$frame$decisionListener$

#define MIMETYPE_ORIG webView:decidePolicyForMIMEType:request:frame:decisionListener:
#define MIMETYPE_HOOK webView$decidePolicyForMIMEType$request$frame$decisionListener$

#define NEWWINDOW_ORIG webView:decidePolicyForNewWindowAction:request:newFrameName:decisionListener:
#define NEWWINDOW_HOOK webView$decidePolicyForNewWindowAction$request$newFrameName$decisionListener$

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

#pragma mark Renamed Methods/*{{{*/
HOOK(Application, applicationDidFinishLaunching$, void, 
     UIApplication *application) {
  CALL_ORIG(Application, applicationDidFinishLaunching$, application);
  initCustomToolbar();
}

HOOK(Application, applicationResume$, void, GSEventRef event) {
  CALL_ORIG(Application, applicationResume$, event);
  [[DownloadManager sharedManager] updateUserPreferences];
  [[DownloadManager sharedManager] updateFileTypes];
}

HOOK(BrowserButtonBar, positionButtons$tags$count$group$, void, 
     id buttons, int *tags, int count, int group) {
  
  CALL_ORIG(BrowserButtonBar, 
            positionButtons$tags$count$group$,
            buttons, tags, count, group);
  
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
     NEWWINDOW_HOOK,
     void,
     WebView *view,
     NSDictionary *action,
     NSURLRequest *request,
     NSString *newFrameName,
     id<WebPolicyDecisionListener> decisionListener) {
  
  DownloadManager* downloader = [DownloadManager sharedManager];
  NSURLRequest* _currentRequest = downloader.currentRequest;
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    NSLog(@"WDW: SAME REQUEST");
    NSLog(@"#####################################################");
    CALL_ORIG(TabDocument, NEWWINDOW_HOOK, view, action, request, newFrameName, decisionListener);
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
    CALL_ORIG(TabDocument, NEWWINDOW_HOOK, view, action, request, newFrameName, decisionListener);
    
  }
  else { // if (_act == SDActionTypeDownload || action == SDActionTypeCancel) {
    NSLog(@"WDW: handled");
    NSLog(@"#####################################################");
    [[CLASS(BrowserController) sharedBrowserController] setResourcesLoading:NO];
  }
}

HOOK(TabDocument,
     NAVACTION_HOOK,
     void,
     WebView *view,
     NSDictionary *action,
     NSURLRequest *request,
     WebFrame *frame,
     id<WebPolicyDecisionListener> decisionListener) {
  
  NSLog(@"NAV: decidePolicyForNavigationAction, req: %@", request);
  
  DownloadManager* downloader = [DownloadManager sharedManager];
  NSURLRequest* _currentRequest = downloader.currentRequest;
  NSLog(@"NAV: req: %@ - cur: %@", request, _currentRequest);
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    NSLog(@"NAV: SAME REQUEST");
    NSLog(@"#####################################################");
    CALL_ORIG(TabDocument, NAVACTION_HOOK, view, action, request, frame, decisionListener);
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
    CALL_ORIG(TabDocument, NAVACTION_HOOK, view, action, request, frame, decisionListener);
  }
  else { // if (_act == SDActionTypeDownload || action == SDActionTypeCancel) {
    NSLog(@"NAV: handled");
    NSLog(@"#####################################################");
    [[CLASS(BrowserController) sharedBrowserController] setResourcesLoading:NO];
  }
}

HOOK(TabDocument,
     MIMETYPE_HOOK,
     void,
     WebView *view,
     NSString *type,
     NSURLRequest *request,
     WebFrame *frame,
     id<WebPolicyDecisionListener> decisionListener) {
  
  NSLog(@"MIME: decidePolicyForMIMEType %@, request: @", type, request);
  
  DownloadManager* downloader = [DownloadManager sharedManager];
  NSURLRequest* _currentRequest = downloader.currentRequest;
  NSLog(@"MIME: req: %@ - cur: %@", request, _currentRequest);
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    NSLog(@"MIME: SAME REQUEST");
    downloader.currentRequest = nil;
    NSLog(@"#####################################################");
    CALL_ORIG(TabDocument, MIMETYPE_HOOK, view, type, request, frame, decisionListener);
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
    CALL_ORIG(TabDocument, MIMETYPE_HOOK, view, type, request, frame, decisionListener);
  }
  else {
    NSLog(@"MIME: handled");
    NSLog(@"#####################################################");
    [[CLASS(BrowserController) sharedBrowserController] setResourcesLoading:NO];
  }
}
#pragma mark -/*}}}*/

void ReloadPrefsNotification (CFNotificationCenterRef center, 
                              void *observer, 
                              CFStringRef name, 
                              const void *object, 
                              CFDictionaryRef userInfo) {
  [[DownloadManager sharedManager] updateUserPreferences];
  [[DownloadManager sharedManager] updateFileTypes];
}

extern "C" void DownloaderInitialize() {	
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
  
  GET_CLASS(Application); 
  GET_CLASS(BrowserButtonBar);
  GET_CLASS(BrowserController);
  GET_CLASS(TabDocument);

  HOOK_MESSAGE_F(Application, applicationDidFinishLaunching:, applicationDidFinishLaunching$);
  HOOK_MESSAGE_F(Application, applicationResume:, applicationResume$);
  HOOK_MESSAGE_F(BrowserButtonBar, positionButtons:tags:count:group:, positionButtons$tags$count$group$);
  HOOK_MESSAGE_F(BrowserController, _panelForPanelType:, _panelForPanelType$);
  HOOK_MESSAGE_F(TabDocument, NAVACTION_ORIG, NAVACTION_HOOK);
  HOOK_MESSAGE_F(TabDocument, NEWWINDOW_ORIG, NEWWINDOW_HOOK); 
  HOOK_MESSAGE_F(TabDocument, MIMETYPE_ORIG,  MIMETYPE_HOOK);

  CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
  CFNotificationCenterAddObserver(r, 
                                  NULL, 
                                  &ReloadPrefsNotification, 
                                  CFSTR("net.howett.safaridownloader/ReloadPrefs"), 
                                  NULL, 
                                  0);

  [pool release];
}

// vim:filetype=objc:ts=2:sw=2:expandtab
