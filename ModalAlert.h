@interface ModalAlert : NSObject 

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
                                delegate:(id)delegate;

@end
