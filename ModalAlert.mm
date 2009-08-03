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

@implementation ModalAlert
+ (void)block:(UIView *)view
{
  view.hidden = FALSE;
  while (!view.hidden && view.superview != nil)
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

+ (void)showAlertViewWithTitle:(NSString*)title 
                       message:(NSString *)message 
                  cancelButton:(NSString*)cancel 
                      okButton:(NSString*)okButton 
                      delegate:(id)delegate
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:delegate 
                                        cancelButtonTitle:cancel 
                                        otherButtonTitles:okButton, nil];
  
  [alert show];
  [alert release];
  
  [ModalAlert block:alert];	
}

+ (void)showAuthViewWithChallenge:(NSURLAuthenticationChallenge*)challenge {
  GET_CLASS(BrowserController);

  id brCont = [$BrowserController sharedBrowserController];
  id tabCont = [brCont tabController];
  id tabDoc = [tabCont activeTabDocument];
  //-(void)tabController:(id)controller tabDocument:(id)document didReceiveAuthenticationChallenge:(id)challenge;

  [brCont tabController:tabCont tabDocument:tabDoc didReceiveAuthenticationChallenge:challenge];
}

+ (NSDictionary*)showAuthAlertViewWithTitle:(NSString*)title 
                           message:(NSString *)message 
                      cancelButton:(NSString*)cancel 
                          okButton:(NSString*)okButton 
                          delegate:(id)delegate
{
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
  
  [ohmygod showInView:[[objc_getClass("BrowserController") sharedBrowserController] window]];
  [ohmygod release];
  
  [ModalAlert block:ohmygod];	
}

@end