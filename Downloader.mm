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
#import "UIKitExtra/UIToolbarButton.h"
#import "Safari/BrowserController.h"
#import "Safari/BrowserButtonBar.h"
#import <QuartzCore/QuartzCore.h>
#import "DHHookCommon.h"

// Numerical and Structural String Formatting Macros
#define iF(i) [NSString stringWithFormat:@"%d", i]
#define fF(f) [NSString stringWithFormat:@"%.2f", f]
#define bF(b) [NSString stringWithFormat:@"%@", b ? @"true" : @"false"]
#define sF(inset) NSStringFromUIEdgeInsets(inset)

#ifndef DEBUG
#define NSLog(...)
#endif

@interface ModalAlert : NSObject @end
@implementation ModalAlert
+ (void)block:(UIView *)view
{
  view.hidden=FALSE;
  while (!view.hidden && view.superview != nil)
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

+ (void)showAlertViewWithTitle:(NSString*)title 
                       message:(NSString *)message 
                  cancelButton:(NSString*)cancel 
                      okButton:(NSString*)okButton 
                      delegate:(id)delegate
{
  UIAlertView *alert= [[UIAlertView alloc] initWithTitle:title
                                                 message:message
                                                delegate:delegate 
                                       cancelButtonTitle:cancel 
                                       otherButtonTitles:okButton, nil];
  [alert show];
  [alert release];
  [ModalAlert block:alert];	
}

+ (void)showActionSheetWithTitle:(NSString*)title 
                         message:(NSString *)message 
                    cancelButton:(NSString*)cancel 
                     destructive:(NSString*)destructive
                           other:(NSString*)other 
                        delegate:(id)delegate
{

  UIActionSheet *ohmygod = [[UIActionSheet alloc] initWithTitle:title
                                                       delegate:delegate
                                              cancelButtonTitle:cancel
                                         destructiveButtonTitle:destructive
                                              otherButtonTitles:other, nil];
  [ohmygod setMessage:@"FILLER TEXT OH MY GOD"];
  
  UILabel *nameLabel = MSHookIvar<UILabel *>(ohmygod, "_bodyTextLabel");;
  UIFont *filenameFont = [nameLabel font];
  CGSize filenameSize = [message sizeWithFont:filenameFont];
  CGRect screenRect = [[UIScreen mainScreen] bounds];
  CGRect nameLabelRect = CGRectMake((screenRect.size.width / 2) - (filenameSize.width / 2), filenameSize.height,
                                   filenameSize.width, filenameSize.height);
  [nameLabel setFrame:nameLabelRect];
  [nameLabel setText:message];
  
  UIImageView *iconImageView = [[UIImageView alloc]
                              initWithImage:[[DownloadManager sharedManager] iconForExtension:[message pathExtension]]];
  iconImageView.center = CGPointMake(nameLabel.frame.origin.x - 15.0f, nameLabel.center.y + nameLabel.frame.size.height);
  [ohmygod addSubview:iconImageView];
  [iconImageView release];
  
  //[ohmygod showFromToolbar:[[objc_getClass("BrowserController") sharedBrowserController] buttonBar]];
  [ohmygod showInView:[[objc_getClass("BrowserController") sharedBrowserController] window]];
  [ohmygod release];
  
  [ModalAlert block:ohmygod];	
}
@end

@class Downloader;
static Downloader *downloader = nil;

@class BrowserButtonBar;
@interface BrowserButtonBar (mine)
- (NSArray*)buttonItems;
- (void)setButtonItems:(NSArray *)its;
- (void)showButtonGroup:(int)group withDuration:(double)duration;
- (void)registerButtonGroup:(int)group withButtons:(int*)buttons withCount:(int)count;
- (id)$$createButtonWithDescription:(id)description;
@end

static id originalDelegate = nil;

@interface Downloader : NSObject <UIActionSheetDelegate>
{
  NSURLRequest* _currentRequest;
}

- (void)downloadFile;

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
  [_currentRequest release];
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
  
  id x = [BrowserButtonBar imageButtonItemWithName:@"NavBookmarks.png" tag:17 action:nil target:nil];
  id y = [BrowserButtonBar imageButtonItemWithName:@"NavBookmarksSmall.png" tag:18 action:nil target:nil];
  
  id spacer1 = [BrowserButtonBar imageButtonItemWithName:@"spacer" tag:66 action:nil target:nil];
  id spacer2 = [BrowserButtonBar imageButtonItemWithName:@"spacer" tag:67 action:nil target:nil];
  
  NSMutableArray *mutButtonItems = [_buttonItems mutableCopy];
  [mutButtonItems addObject:x];
  [mutButtonItems addObject:y];
  [mutButtonItems addObject:spacer1];
  [mutButtonItems addObject:spacer2];
  [buttonBar setButtonItems:mutButtonItems];
  [mutButtonItems release];
  
  int portraitGroup[]  = {5, 66, 7, 66, 15, 66, 1, 66, 17, 66, 3};
  int landscapeGroup[] = {6, 67, 8, 67, 16, 67, 2, 67, 18, 67, 4};
  
  CFDictionaryRemoveValue(_groups, (void*)1);
  CFDictionaryRemoveValue(_groups, (void*)2);
  
  [buttonBar registerButtonGroup:1 withButtons:portraitGroup withCount:11];
  [buttonBar registerButtonGroup:2 withButtons:landscapeGroup withCount:11];
  
  if (cg == 1 || cg == 2)
    [buttonBar showButtonGroup:cg withDuration:0]; // duration appears to either be ignored or is somehow related to animations
}

#pragma mark -/*}}}*/
#pragma mark Download Management/*{{{*/
static id curWebFrame = nil;

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
- (void) webView:(WebView *)webView 
    decideAction:(NSDictionary*)action
      forRequest:(NSURLRequest *)request 
    withMimeType:(NSString *)mimeType 
         inFrame:(WebFrame *)frame
    withListener:(id<WebPolicyDecisionListener>)listener
{
  NSString *url = [[request URL] absoluteString];
  
  if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
    NSLog(@"not a valid http url, continue.");
    [originalDelegate webView:webView decidePolicyForNavigationAction:action
                      request:request
                        frame:frame
             decisionListener:listener];
    return;
  }
  
  if ([[DownloadManager sharedManager] supportedRequest:request withMimeType:mimeType])
  {
    NSString *filename = [[[[request URL] absoluteString] lastPathComponent] 
                          stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //NSString *other = [objc_getClass("WebView") canShowMIMEType:mimeType] ? @"View" : nil;
    NSString *other = @"View";
    
    [ModalAlert showActionSheetWithTitle:@"What would you like to do?"
                                 message:filename
                            cancelButton:@"Cancel"
                             destructive:@"Download"
                                   other:other
                                delegate:self];
    
    if (_actionType == SDActionTypeView) 
    {      
      if (action) 
      {
        [originalDelegate webView:webView decidePolicyForNavigationAction:action
                          request:request
                            frame:frame
                 decisionListener:listener];
      }
      else
      {
        [originalDelegate webView:webView decidePolicyForMIMEType:mimeType
                          request:request
                            frame:frame
                 decisionListener:listener];
      }
    }
    else if (_actionType == SDActionTypeDownload)
    {
      [listener ignore];
      if ([[DownloadManager sharedManager] addDownloadWithRequest:request])
        NSLog(@"successfully added download");
      else
        NSLog(@"add download failed");
    }
    else
    {
      [frame stopLoading];
      [listener ignore]; 
    }
  }
  else
  {
    [listener use]; 
  }  
}
///////////////////////////////////////////////////

- (void) webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)action 
         request:(NSURLRequest *)request 
    newFrameName:(NSString *)name 
decisionListener:(id<WebPolicyDecisionListener>)listener {
  NSString *url = [[request URL] absoluteString];
  
  if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
    NSLog(@"not a valid http url, continue.");
    [originalDelegate webView:sender decidePolicyForNewWindowAction:action
                      request:request
                 newFrameName:name
             decisionListener:listener];
    return;
  }
  
  if ([[DownloadManager sharedManager] supportedRequest:request withMimeType:nil]) {
    NSString *filename = [[[[request URL] absoluteString] lastPathComponent] 
                          stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *other = @"View";
    
    [ModalAlert showActionSheetWithTitle:@"What would you like to do?"
                                 message:filename
                            cancelButton:@"Cancel"
                             destructive:@"Download"
                                   other:other
                                delegate:self];
    
    if (_actionType == SDActionTypeView) {      
      [originalDelegate webView:sender decidePolicyForNewWindowAction:action
                        request:request
                   newFrameName:name
               decisionListener:listener];
    } else if (_actionType == SDActionTypeDownload) {
      [listener ignore];
      if ([[DownloadManager sharedManager] addDownloadWithRequest:request])
        NSLog(@"successfully added download");
      else
        NSLog(@"add download failed");
    } else {
      [listener ignore]; 
    }
  } else {
    [listener use]; 
  }  
}

- (void) webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type 
         request:(NSURLRequest *)request 
           frame:(WebFrame *)frame 
decisionListener:(id<WebPolicyDecisionListener>)listener {
//  
  NSLog(@"MIME: decidePolicyForMIMEType!!!!!!");
  NSLog(@"MIME: type: %@", type);
  NSLog(@"MIME: request: %@", request);
  NSLog(@"MIME: Listener!: %@", listener);
  NSLog(@"URLSTRING: %@", [[request URL] absoluteString]);
  
  if (_currentRequest != nil && [_currentRequest isEqual:request]) 
  {
    [_currentRequest release];
    _currentRequest = nil;
    [listener use];
    return;
  }

  [self webView:webView 
   decideAction:nil 
     forRequest:request 
   withMimeType:type 
        inFrame:frame 
   withListener:listener];
  
}

- (void) webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)action 
         request:(NSURLRequest *)request 
           frame:(WebFrame *)frame 
decisionListener:(id<WebPolicyDecisionListener>)listener {
  
  NSLog(@"NAV: decidePolicyForNavigationAction!!!!!!");
  NSLog(@"NAV: action: %@", action);
  NSLog(@"NAV: request: %@", request);
  NSLog(@"NAV: Listener!: %@", listener);
  
  [self webView:webView 
   decideAction:action 
     forRequest:request 
   withMimeType:nil 
        inFrame:frame 
   withListener:listener];
}
#pragma mark -/*}}}*/
@end

#pragma mark Renamed Methods/*{{{*/
@class WebView;
HOOK(WebView, setPolicyDelegate$, void, id delegate) {
  NSLog(@"wants to set delegate: %@", delegate);
  originalDelegate = [delegate retain];
  CALL_ORIG(WebView, setPolicyDelegate$, downloader);
}

HOOK(Application, applicationDidFinishLaunching$, void, UIApplication *application) {
  CALL_ORIG(Application, applicationDidFinishLaunching$, application);
  [downloader loadCustomToolbar];
}

HOOK(Application, applicationResume$, void, GSEventRef event) {
  CALL_ORIG(Application, applicationResume$, event);
  [[DownloadManager sharedManager] updateFileTypes];
}

HOOK(BrowserButtonBar, createButtonWithDescription$, id, id description) {
  UIToolbarButton* ret = CALL_ORIG(BrowserButtonBar, createButtonWithDescription$, description);
  NSInteger tag = [[description objectForKey:@"UIButtonBarButtonTag"] intValue];
  
  if (tag == 17) // portrait buton
  {
    [ret setImage:[UIImage imageNamed:@"Download.png"]];
    [ret addTarget:[DownloadManager sharedManager] action:@selector(showDownloadManager) forControlEvents:UIControlEventTouchUpInside]; // set this here to avoid uibarbutton weirdness
    [[DownloadManager sharedManager] setPortraitDownloadButton:ret];
  }
  else if (tag == 18) // landscape button
  {
    [ret setImage:[UIImage imageNamed:@"DownloadSmall.png"]];
    [ret addTarget:[DownloadManager sharedManager] action:@selector(showDownloadManager) forControlEvents:UIControlEventTouchUpInside]; // set this here to avoid uibarbutton weirdness
    [[DownloadManager sharedManager] setLandscapeDownloadButton:ret];
  }
  else if (tag == 66) // portrait spacer
    ret.frame = CGRectMake(ret.frame.origin.x, ret.frame.origin.y, 15, ret.frame.size.height);
  else if (tag == 67) // landscape spacer
    ret.frame = CGRectMake(ret.frame.origin.x, ret.frame.origin.y, 45, ret.frame.size.height);
  return ret;
}

HOOK(UIToolbarButton, hitTest$withEvent$, id, CGPoint point, id event) {
  if ([self tag] == 66 || [self tag] == 67)
    return nil;
  return CALL_ORIG(UIToolbarButton, hitTest$withEvent$, point, event); 
}

HOOK(UIToolbarButton, setFrame$, void, CGRect frame) {
  if (self.tag == 17)
    CALL_ORIG(UIToolbarButton, setFrame$, CGRectOffset(frame, 3, 0));
  else if (self.tag == 18)
    CALL_ORIG(UIToolbarButton, setFrame$, CGRectOffset(frame, 8, 0));
  else
    CALL_ORIG(UIToolbarButton, setFrame$, frame);
}

HOOK(BrowserController, _panelForPanelType$, id, int type) {
  if(type == 44)
    return [[DownloadManager sharedManager] browserPanel];
  return CALL_ORIG(BrowserController, _panelForPanelType$, type);
}

#pragma mark -/*}}}*/

extern "C" void DownloaderInitialize() {	
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
  downloader = [[Downloader alloc] init];
  GET_CLASS(WebView);
  HOOK_MESSAGE_F(WebView, setPolicyDelegate:, setPolicyDelegate$);

  GET_CLASS(Application);
  HOOK_MESSAGE_F(Application, applicationDidFinishLaunching:, applicationDidFinishLaunching$);
  HOOK_MESSAGE_F(Application, applicationResume:, applicationResume$);

  GET_CLASS(BrowserButtonBar);
  HOOK_MESSAGE_F(BrowserButtonBar, createButtonWithDescription:, createButtonWithDescription$);

  GET_CLASS(UIToolbarButton);
  HOOK_MESSAGE_F(UIToolbarButton, hitTest:withEvent:, hitTest$withEvent$);
  HOOK_MESSAGE_F(UIToolbarButton, setFrame:, setFrame$);

  GET_CLASS(BrowserController);
  HOOK_MESSAGE_F(BrowserController, _panelForPanelType:, _panelForPanelType$);
  [pool release];
}

// vim:filetype=objc:ts=2:sw=2:expandtab
