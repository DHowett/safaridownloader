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

#import "Safari/RotatablePopoverController.h"

char __attribute((section("__MISC, UDID"))) udid[41] = "0000000000000000000000000000000000000000";

static bool _wildCat = NO;
static bool _fourPointOh = NO;

static UIToolbarButton *_actionButton;
static UIToolbarButton *_bookmarksButton;

@interface UIActionSheet (SDMPrivate)
-(id)buttons;
-(void)presentFromRect:(CGRect)rect inView:(id)view direction:(int)direction allowInteractionWithViews:(id)views backgroundStyle:(int)style animated:(BOOL)animated;
@end

%class BrowserController
%class DOMHTMLAnchorElement;
%class DOMHTMLImageElement;

@interface BrowserController (SDMAdditions)
- (void)_setShowingDownloads:(BOOL)showing animate:(BOOL)animate;
- (void)_presentModalViewController:(id)x fromButton:(UIToolbarButton *)button;
- (void)_presentModalViewControllerFromDownloadsButton:(id)x;
- (void)toggleDownloadManagerFromButtonBar;
- (void)_setBrowserPanel:(id)panel;
- (void)setBrowserPanel:(id)panel;
- (id)browserLayer;
- (void)_forceDismissModalViewController:(BOOL)animate;
@end

@interface BrowserController (SafariFour)
- (void)setCurrentPopoverController:(UIPopoverController *)p;
@end

@interface UIDevice (Wildcat)
- (BOOL)isWildcat;
@end

@interface UIScreen (iOS4)
- (CGFloat)scale;
@end

static NSString *portraitIconFilename(void) {
  NSString *name = @"Download";
  if(_wildCat) return @"DownloadT.png";
  return _fourPointOh ? name : [name stringByAppendingString:@".png"];
}

static NSString *landscapeIconFilename(void) {
  NSString *name = @"DownloadSmall";
  return _fourPointOh ? name : [name stringByAppendingString:@".png"];
}

static void initCustomToolbar(void) {
  Class BrowserController = objc_getClass("BrowserController");
  Class BrowserButtonBar = objc_getClass("BrowserButtonBar");
  BrowserController *bcont = [BrowserController sharedBrowserController];
  BrowserButtonBar *buttonBar = MSHookIvar<BrowserButtonBar *>(bcont, "_buttonBar");
  CFMutableDictionaryRef _groups = MSHookIvar<CFMutableDictionaryRef>(buttonBar, "_groups");
  int cg = MSHookIvar<int>(buttonBar, "_currentButtonGroup");
  NSArray *_buttonItems = [buttonBar buttonItems];
  
  NSMutableArray *mutButtonItems = [_buttonItems mutableCopy];

  id x = [BrowserButtonBar imageButtonItemWithName:portraitIconFilename()
                                               tag:61
                                            action:@selector(toggleDownloadManagerFromButtonBar)
                                            target:[NSValue valueWithNonretainedObject:[$BrowserController sharedBrowserController]]];

  [mutButtonItems addObject:x];
  CFDictionaryRemoveValue(_groups, (void*)1);

  if(!_wildCat) {
    // Landscape (non-iPad)
    id y = [BrowserButtonBar imageButtonItemWithName:landscapeIconFilename()
                                                 tag:62
                                              action:@selector(toggleDownloadManagerFromButtonBar)
                                              target:[NSValue valueWithNonretainedObject:[$BrowserController sharedBrowserController]]];
    [mutButtonItems addObject:y];
    CFDictionaryRemoveValue(_groups, (void*)2);
  }

  
  [buttonBar setButtonItems:mutButtonItems];
  [mutButtonItems release];
  
  int portraitGroup[]  = {5, 7, 15, 1, 61, 3};
  int landscapeGroup[] = {6, 8, 16, 2, 62, 4};

  if(_wildCat) { // The iPad has a different button order than the iPhone.
    portraitGroup[0] = 5;
    portraitGroup[1] = 7;
    portraitGroup[2] = 3;
    portraitGroup[3] = 1;
    portraitGroup[4] = 15;
    portraitGroup[5] = 61;
  }
  
  [buttonBar registerButtonGroup:1 
                     withButtons:portraitGroup 
                       withCount:6];
  if(!_wildCat) {
    [buttonBar registerButtonGroup:2 
                       withButtons:landscapeGroup 
                         withCount:6];
  }
  
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
  [[SDDownloadManager sharedManager] updateUserPreferences];
  [[SDDownloadManager sharedManager] updateFileTypes];
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
  float YOrigin = _wildCat ? 10 : 2;
  for(UIToolbarButton *button in buttons) {
    curX = curButton * buttonBoxWidth;
    maxX = curX + buttonBoxWidth;
    float curWidth = button.frame.size.width;
    float curHeight = button.frame.size.height;
    float newXOrigin = maxX - (buttonBoxWidth / 2.0) - (curWidth / 2.0);
    [button setFrame:CGRectMake(newXOrigin, YOrigin, curWidth, curHeight)];

    int tag = button.tag;
    if(tag == 61)
      [[SDDownloadManager sharedManager] setPortraitDownloadButton:button];
    else if(tag == 62)
      [[SDDownloadManager sharedManager] setLandscapeDownloadButton:button];
    else if(tag == 1)
      _bookmarksButton = button;
    else if(tag == 15)
      _actionButton = button;

    curButton++;
  }
  return;
}
%end

%hook BrowserController -(id)_panelForPanelType:(int)type {
  %log;
  if (type == 44) {
    return [SDDownloadManagerNavigationController sharedInstance];
  } else if (type == 88) {
    return [SDDownloadOperation authView];
  }
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
  SDDownloadManager* downloader = [SDDownloadManager sharedManager];
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
  
  SDDownloadManager* downloader = [SDDownloadManager sharedManager];
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
  
  SDDownloadManager* downloader = [SDDownloadManager sharedManager];
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
  DOMNode *element;
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

@interface DOMNode : NSObject
-(DOMNode*)parentNode;
-(NSURL*)absoluteLinkURL;
-(NSURL*)absoluteImageURL;
@end

%hook UIWebDocumentView
- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(int)index {
  if(index == 1336) {
    if(interactionURL)
      [[SDDownloadManager sharedManager] addDownloadWithURL:interactionURL browser:YES];
  }
  %orig;
  [interactionURL release];
  interactionURL = nil;
}

static void showBrowserSheetHookInternals(UIWebDocumentView *self, UIActionSheet *sheet, DOMNode *&domElement) {
  NSLog(@"DOM Element is %@", domElement);
  NSMutableArray *buttons = [sheet buttons];
  NSString *downloadThing = @"";
  id myButton;

  DOMNode *anchorNode = domElement;
  while(anchorNode && ![anchorNode isKindOfClass:[$DOMHTMLAnchorElement class]]) {
    NSLog(@"not htmlanchorelement oh no %@", anchorNode);
    anchorNode = [anchorNode parentNode];
  }

  if(anchorNode) {
    NSLog(@"100%% certainty that this is an anchor node. %@", anchorNode);
    domElement = anchorNode;
  } else {
    NSLog(@"There's definitely not an anchor node here.");
  }

  if([domElement isKindOfClass:[$DOMHTMLAnchorElement class]]) {
    NSLog(@"htmlanchorelement yay %@", domElement);
    interactionURL = [[domElement absoluteLinkURL] copy];
    downloadThing = @"Target";
  } else if([domElement isKindOfClass:[$DOMHTMLImageElement class]]) {
    NSLog(@"htmlimageelement yay %@", domElement);
    interactionURL = [[domElement absoluteImageURL] copy];
    downloadThing = @"Image";
  } else {
    interactionURL = nil;
  }

  if(interactionURL) {
    NSString *scheme = [interactionURL scheme];
    NSLog(@"url is %@", interactionURL);
    if([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]
    || [scheme isEqualToString:@"ftp"]) {
     [sheet addButtonWithTitle:[NSString stringWithFormat:@"Download %@...", downloadThing]];
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
  [[SDDownloadManager sharedManager] updateUserPreferences];
  [[SDDownloadManager sharedManager] updateFileTypes];
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
  id controller = [self browserPanel];
  if (showing) {
    [self _resizeNavigationController:controller small:NO];
    [self _presentModalViewControllerFromDownloadsButton:controller];
  } 
  else {
    [self willHideBrowserPanel:controller];
    [self _forceDismissModalViewController:animate]; // 3.2+
  }
}

%new(v@:@@)
- (void)_presentModalViewController:(id)x fromButton:(UIToolbarButton *)button {
  if(_wildCat) {
    id rpc = [[%c(RotatablePopoverController) alloc] initWithContentViewController:x];
    [rpc setPresentationRect:[button frame]];
    [rpc setPresentationView:[self buttonBar]];
    [rpc setPermittedArrowDirections:1];
    [rpc setPassthroughViews:[NSArray arrayWithObject:[self buttonBar]]];
    [rpc presentPopoverAnimated:NO];
    [self setCurrentPopoverController:rpc];
    [rpc release];
  } else {
    [[self _modalViewController] presentModalViewController:x animated:YES];
  }
}

%new(v@:@)
- (void)_presentModalViewControllerFromDownloadsButton:(id)x {
  [self _presentModalViewController:x fromButton:[[SDDownloadManager sharedManager] portraitDownloadButton]];
}

%group iPadHooks
- (void)_presentModalViewControllerFromActionButton:(id)x {
  [self _presentModalViewController:x fromButton:_actionButton];
}

- (void)_presentModalViewControllerFromBookmarksButton:(id)x {
  [self _presentModalViewController:x fromButton:_bookmarksButton];
}

- (void)popupAlert:(UIActionSheet *)alert {
  [alert presentFromRect:[_actionButton frame] inView:[self buttonBar] direction:1 allowInteractionWithViews:[NSArray arrayWithObjects:[self buttonBar], nil] backgroundStyle:0 animated:YES];
}
%end
%group Firmware_ge_32
%new(v@:)
- (void)toggleDownloadManagerFromButtonBar {
  if([[self browserPanel] panelType] == 44) {
    [[self browserPanel] performSelector:@selector(close)];
  } else {
      [self showBrowserPanelType:44];
  }
}
%end

%group Firmware_lt_32
%new(v@:)
- (void)toggleDownloadManagerFromButtonBar {
  if([[self browserPanel] panelType] == 44) {
    [self hideBrowserPanelType:44];
    [self _setShowingDownloads:NO animate:YES];
  } else {
    [self showBrowserPanelType:44];
    [self _setShowingDownloads:YES animate:YES];
  }
}
%end


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

@interface BrowserController (iOS4)
- (id)transitionView;
@end
%hook BrowserController
%group Firmware_ge_32
- (void)setBrowserPanel:(id)panel {
  %log;%orig;
}
%new(v@:@)
- (void)_setBrowserPanel:(id)panel {
  [self setBrowserPanel:panel];
}
%new(@@:)
- (id)browserLayer {
  return [self transitionView];
}
%end
%end

%group Firmware_lt_32
%hook BrowserController
%new(v@:i) // Missing on < 4.0
- (void)_forceDismissModalViewController:(BOOL)animated {
  [self _forceDismissModalViewController];
}
%end

%hook Application
- (void)applicationWillSuspend {
  BrowserController *sbc = [$BrowserController sharedBrowserController];
  if([[sbc browserPanel] panelType] == 44) {
    [sbc hideBrowserPanelType:44];
    [sbc _setShowingDownloads:NO animate:YES];
  }
  %orig;
}
%end
%end

%group iPadHooks
%hook BrowserButtonBar
- (void)setFrame:(CGRect)frame {
  %orig(CGRectMake(frame.origin.x, frame.origin.y, frame.size.width+26, frame.size.height));
}
%end
%hook AddressView
- (CGRect)_fieldRect {
  CGRect frame = %orig;
  return CGRectMake(frame.origin.x+26, frame.origin.y, frame.size.width-26, frame.size.height);
}
%end
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
  if([UIDevice instancesRespondToSelector:@selector(isWildcat)] && [[UIDevice currentDevice] isWildcat]) {
    _wildCat = YES;
    %init(iPadHooks);
  } else {
    _wildCat = NO;
  }

  _fourPointOh = NO;
  if([UIScreen instancesRespondToSelector:@selector(scale)]) {
    _fourPointOh = YES;
  }
}

// vim:filetype=logos:ts=2:sw=2:expandtab
