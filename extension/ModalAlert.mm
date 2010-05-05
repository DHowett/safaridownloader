//
//  ModalAlert.m
//  Downloader
//
//  Created by Youssef Francis on 8/3/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import "DHHookCommon.h"
#import "ModalAlert.h"
#import "DownloadManager.h"
#import "Safari/BrowserController.h"
#import "Safari/TabDocument.h"
#import "Safari/TabController.h"
#import <QuartzCore/QuartzCore.h>

#ifndef DEBUG
#define NSLog(...)
#endif

DHLateClass(BrowserController);

@interface ModalAlert (priv)
UIAlertView* activeAlert;
@end

@interface UIAlertView (priv)
- (void)setNumberOfRows:(int)num;
@end

@implementation AlertPrompt
@synthesize textField;
@synthesize enteredText;
- (id)initWithTitle:(NSString *)title 
            message:(NSString *)message 
           delegate:(id)delegate 
  cancelButtonTitle:(NSString *)cancelButtonTitle 
      okButtonTitle:(NSString *)okayButtonTitle {
	if ((self = [super initWithTitle:title 
                           message:message
                          delegate:delegate 
                 cancelButtonTitle:cancelButtonTitle
                 otherButtonTitles:okayButtonTitle, nil])) {
		UITextField *theTextField = [[UITextField alloc] initWithFrame:CGRectMake(14.0, 45.0, 255.0, 32.0)]; 
    theTextField.borderStyle = UITextBorderStyleBezel;
		[theTextField setBackgroundColor:[UIColor whiteColor]]; 
		[self addSubview:theTextField];
		self.textField = theTextField;
		[theTextField release];
		CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, 75.0); 
		[self setTransform:translate];
	}
	return self;
}
- (void)show {
	[textField becomeFirstResponder];
	[super show];
}
- (NSString *)enteredText {
	return textField.text;
}
- (void)dealloc {
	[textField release];
	[super dealloc];
}
@end

@implementation QuickAlert
static UIAlertView* alertView = nil;
static UIProgressView* progressView = nil;

+ (void)showMessage:(NSString*)msg {
  [self createAlertWithTitle:msg message:nil];
}

+ (void)showMessage:(NSString*)msg description:(NSString*)desc {
  [self createAlertWithTitle:msg message:desc];
}

+ (void)showError:(NSString*)msg {
  [self createAlertWithTitle:@"Error" message:msg];
}

+ (void)showSuccess:(NSString*)msg {
  [self createAlertWithTitle:@"Success" message:msg];
}

+ (void)showLoadingAlert {
  alertView = [[UIAlertView alloc]
               initWithTitle:@"Saving..."
               message:nil
               delegate:self
               cancelButtonTitle:nil
               otherButtonTitles:nil];
  
	UIActivityIndicatorView *listingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	CGRect frame = listingIndicator.frame;
	frame.origin.x = 240;
	frame.origin.y = 15;
	frame.size.width = 22;
	frame.size.height = 22;
	listingIndicator.frame = frame;
	[alertView addSubview:listingIndicator];
  [listingIndicator release];
  
  progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
  progressView.frame = CGRectMake(15.0f, 48.0f, 248.0f, 15.0f);
  [alertView addSubview:progressView];
  [progressView release];
  
  [alertView setNumberOfRows:1];
	[alertView setTransform:CGAffineTransformMakeScale(1, 1.5)];
	[alertView show];
  [alertView release];
	[listingIndicator startAnimating];   
}

+ (void)updateProgress:(CGFloat)prog {
  progressView.progress = prog;
}

+ (void)dismissLoadingAlert {
  [progressView removeFromSuperview];
  progressView = nil;
  [alertView dismissWithClickedButtonIndex:-1 animated:YES];
  alertView = nil;
}

+ (void)createAlertWithTitle:(NSString*)title message:(NSString*)message {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:@"OK"
                                        otherButtonTitles:nil];
  [alert show];
  [alert release];
}

@end

@implementation ModalAlert

+ (void)block:(UIView *)view {
  view.hidden = FALSE;
  while (!view.hidden && view.superview != nil)
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

+ (void)showAlertViewWithTitle:(NSString*)title 
                       message:(NSString *)message 
                  cancelButton:(NSString*)cancel 
                      okButton:(NSString*)okButton 
                      delegate:(id)delegate {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:delegate 
                                        cancelButtonTitle:cancel 
                                        otherButtonTitles:okButton, nil];
  
  [alert show];
  [alert release];
  
  [ModalAlert block:alert];	
}

+ (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
  [[DownloadManager sharedManager] updateBadges];
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  UIView *v = [keyWindow viewWithTag:12345];
  [v removeFromSuperview];
  [activeAlert dismissWithClickedButtonIndex:0 animated:YES];
  activeAlert = nil;
}

static UIImage* savedIcon = nil;

+ (void)showLoadingAlertWithIconName:(NSString*)name orMimeType:(NSString *)mimeType {
  activeAlert = [[UIAlertView alloc]
                 initWithTitle:@"Loading..."
                 message:nil
                 delegate:self
                 cancelButtonTitle:nil
                 otherButtonTitles:nil];
  
	UIActivityIndicatorView *listingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	CGRect frame = listingIndicator.frame;
	frame.origin.x = 220;
	frame.origin.y = 15;
	frame.size.width = 22;
	frame.size.height = 22;
	listingIndicator.frame = frame;
	[activeAlert addSubview:listingIndicator];
  [listingIndicator release];
  
  savedIcon = [[[DownloadManager sharedManager] iconForExtension:[name pathExtension] orMimeType:mimeType] retain];
  
  UIImageView* icon = [[UIImageView alloc] initWithImage:savedIcon];
  icon.frame = CGRectMake(18, 14, 22, 22);
  [activeAlert addSubview:icon];
  [icon release];
  
	[activeAlert setNumberOfRows:0];
	[activeAlert setTransform:CGAffineTransformMakeScale(1, 1.1)];
	[activeAlert show];
  [activeAlert release];
	[listingIndicator startAnimating];   
}

+ (void)dismissLoadingAlert {
  NSLog(@"dismissLoadingAlert: %@", activeAlert);
  // Get the relevant frames.
  if (!activeAlert) return;
  UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
  UIView *enclosingView = keyWindow;
  
  Class BrowserController = objc_getClass("BrowserController");
  int orientation = [[BrowserController sharedBrowserController] orientation];
  NSLog(@"Orientation = %d.", orientation);
  UIView *button = (orientation == 0 ? ([[DownloadManager sharedManager] portraitDownloadButton]) : ([[DownloadManager sharedManager] landscapeDownloadButton]));
  CGRect tempCellFrame = [button frame];
  CGRect cellFrame;
  if(!button) cellFrame = CGRectMake(260, 440, 34, 36);
  else cellFrame = [[[BrowserController sharedBrowserController] buttonBar] convertRect:tempCellFrame toView:keyWindow];
  
  //  CGRect cellFrame = GRectMake(260, 440, 34, 36);
  CGRect buttonFrame = [activeAlert convertRect:CGRectMake(18, 14, 22, 22) toView:keyWindow];
  
  /*
   * Icon animation
   */
  
  // Determine the animation's path.
	CGPoint startPoint = CGPointMake(buttonFrame.origin.x + buttonFrame.size.width / 2, buttonFrame.origin.y + buttonFrame.size.height / 2);
	CGPoint curvePoint1 = CGPointMake(startPoint.x + 90, startPoint.y - 150);
	CGPoint endPoint = CGPointMake(CGRectGetMidX(cellFrame), CGRectGetMidY(cellFrame));
	CGPoint curvePoint2 = CGPointMake(startPoint.x + 140, endPoint.y - 40);
  
  // Create the animation's path.
  CGPathRef path = NULL;
  CGMutablePathRef mutablepath = CGPathCreateMutable();
  CGPathMoveToPoint(mutablepath,  NULL, 
                    startPoint.x, startPoint.y);
  
  CGPathAddCurveToPoint(mutablepath,   NULL, 
                        curvePoint1.x, curvePoint1.y,
                        curvePoint2.x, curvePoint2.y,
                        endPoint.x,    endPoint.y);
  
  path = CGPathCreateCopy(mutablepath);
  CGPathRelease(mutablepath);
  
  // Create animated icon view.
  
  UIImageView* animatedLabel = [[UIImageView alloc] initWithImage:savedIcon];
  animatedLabel.tag = 12345;
  [enclosingView addSubview:animatedLabel];
  [animatedLabel release];
  CALayer *iconViewLayer = animatedLabel.layer;
  
  CAKeyframeAnimation *animatedIconAnimation = [CAKeyframeAnimation animationWithKeyPath: @"position"];
  animatedIconAnimation.removedOnCompletion = YES;
  animatedIconAnimation.duration = 0.5;
  animatedIconAnimation.delegate = self;
  animatedIconAnimation.path = path;
  animatedIconAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  [iconViewLayer addAnimation:animatedIconAnimation forKey:@"animateIcon"];
  
  // Start the icon animation.
  [iconViewLayer setPosition:CGPointMake(endPoint.x, endPoint.y)];
  
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
  [UIView setAnimationDuration:0.3];
  [animatedLabel setTransform:CGAffineTransformMakeScale(0.3, 0.3)];
  [UIView commitAnimations];  
}

+ (void)showAuthViewWithChallenge:(NSURLAuthenticationChallenge*)challenge {
  BrowserController *brCont = [DHClass(BrowserController) sharedBrowserController];
  TabController* tabCont = [brCont tabController];
  TabDocument* tabDoc = [tabCont activeTabDocument];
  
  [brCont tabController:tabCont tabDocument:tabDoc didReceiveAuthenticationChallenge:challenge];
}

+ (NSDictionary*)showAuthAlertViewWithTitle:(NSString*)title 
                                    message:(NSString *)message 
                               cancelButton:(NSString*)cancel 
                                   okButton:(NSString*)okButton 
                                   delegate:(id)delegate {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:[message stringByAppendingString:@"\n\n\n\n"]
                                                 delegate:delegate 
                                        cancelButtonTitle:cancel 
                                        otherButtonTitles:okButton, nil];
  
  UITextField *userField = [[UITextField alloc] initWithFrame:CGRectMake(12, 72, 260, 29)];
  userField.placeholder = @"Username";
  userField.backgroundColor = [UIColor whiteColor];
  userField.borderStyle = UITextBorderStyleBezel;
  [alert addSubview:userField];
  [userField release];
  
  UITextField *passField = [[UITextField alloc] initWithFrame:CGRectMake(12, 106, 260, 29)];
  passField.placeholder = @"Password";
  passField.backgroundColor = [UIColor whiteColor];
  passField.borderStyle = UITextBorderStyleBezel;
  [alert addSubview:passField];
  [passField release];
  
  [alert setTransform:CGAffineTransformMakeTranslation(0, 90)];
  [alert show];
  [alert release];
  [userField becomeFirstResponder];
  
  //  UIWindow* window = [[UIApplication sharedApplication] keyWindow];
  //  [[objc_getClass("BrowserController") sharedBrowserController] showKeyboard:YES atPoint:CGPointMake(0, window.frame.size.height-216) inLayer:window belowLayer:nil forSheet:YES];
  
  [[objc_getClass("BrowserController") sharedBrowserController] _showKeyboardForSheet:YES];
  [ModalAlert block:alert];
  [[objc_getClass("BrowserController") sharedBrowserController] _hideKeyboardForSheet:YES];
  NSDictionary* ret = [NSMutableDictionary dictionary];
  if (userField.text.length > 0 && passField.text.length > 0) {
    [ret setValue:userField.text forKey:@"user"];
    [ret setValue:passField.text forKey:@"pass"];
  }
  else
    ret = nil;
  return ret;
}

+ (void)showDownloadActionSheetWithTitle:(NSString*)title 
                                 message:(NSString*)message 
                                mimetype:(NSString*)mimetype
                            cancelButton:(NSString*)cancel 
                             destructive:(NSString*)destructive
                                   other:(NSString*)other 
                                     tag:(NSInteger)tag
                                delegate:(id)delegate {
  
  UIActionSheet *ohmygod = [[UIActionSheet alloc] initWithTitle:title
                                                       delegate:delegate
                                              cancelButtonTitle:cancel
                                         destructiveButtonTitle:destructive
                                              otherButtonTitles:other, nil];
  [ohmygod setMessage:@"FILLER TEXT OH MY GOD"];
  ohmygod.tag = tag;
  
  UILabel *nameLabel = MSHookIvar<UILabel *>(ohmygod, "_bodyTextLabel");;
  UIFont *filenameFont = [nameLabel font];
  CGSize filenameSize = [message sizeWithFont:filenameFont];
  CGRect screenRect = [[UIScreen mainScreen] bounds];
  CGRect nameLabelRect = CGRectMake((screenRect.size.width / 2) - (filenameSize.width / 2), filenameSize.height,
                                    filenameSize.width, filenameSize.height);
  [nameLabel setFrame:nameLabelRect];
  [nameLabel setText:message];
  
  UIImageView *iconImageView = [[UIImageView alloc]
                                initWithImage:[[DownloadManager sharedManager] iconForExtension:[message pathExtension] orMimeType:mimetype]];
  iconImageView.center = CGPointMake(nameLabel.frame.origin.x - 15.0f, nameLabel.center.y + nameLabel.frame.size.height);
  [ohmygod addSubview:iconImageView];
  [iconImageView release];
  [ohmygod showInView:(UIView*)[[DHClass(BrowserController) sharedBrowserController] browserLayer]];
  [ohmygod release];
  
  [ModalAlert block:ohmygod];	
}

@end
