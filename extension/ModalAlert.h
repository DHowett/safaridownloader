@interface SDAlertPrompt : UIAlertView 
{
	UITextField	*textField;
}
@property (nonatomic, retain) UITextField *textField;
@property (readonly) NSString *enteredText;
- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle okButtonTitle:(NSString *)okButtonTitle;
@end

@interface SDQuickAlert : NSObject
+ (void)showMessage:(NSString*)msg;
+ (void)showMessage:(NSString*)msg description:(NSString*)desc;
+ (void)showError:(NSString*)msg;
+ (void)showSuccess:(NSString*)msg;
//+ (void)showLoadingAlert;
//+ (void)updateProgress:(CGFloat)prog;
//+ (void)dismissLoadingAlert;
@end

@interface SDQuickAlert (internal)
+ (void)createAlertWithTitle:(NSString*)t message:(NSString*)message;
@end

@interface SDModalAlert : NSObject 

+ (void)showLoadingAlertWithIconName:(NSString*)name orMimeType:(NSString *)mimeType;
+ (void)dismissLoadingAlert;

+ (void)showAlertViewWithTitle:(NSString*)title 
                       message:(NSString *)message 
                  cancelButton:(NSString*)cancel 
                      okButton:(NSString*)okButton 
                      delegate:(id)delegate;

+ (void)showAuthViewWithChallenge:(NSURLAuthenticationChallenge*)challenge;

+ (NSDictionary*)showAuthAlertViewWithTitle:(NSString*)title 
                                    message:(NSString *)message 
                               cancelButton:(NSString*)cancel 
                                   okButton:(NSString*)okButton 
                                   delegate:(id)delegate;

+ (void)showDownloadActionSheetWithTitle:(NSString*)title 
                                 message:(NSString*)message 
                                mimetype:(NSString*)mimetype
                            cancelButton:(NSString*)cancel 
                             destructive:(NSString*)destructive
                                   other:(NSString*)other 
                                     tag:(NSInteger)tag
                                delegate:(id)delegate;

@end
