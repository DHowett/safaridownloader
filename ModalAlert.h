@interface ModalAlert : NSObject 

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

+ (void)showActionSheetWithTitle:(NSString*)title 
                         message:(NSString *)message 
                    cancelButton:(NSString*)cancel 
                     destructive:(NSString*)destructive
                           other:(NSString*)other 
                        delegate:(id)delegate;

@end