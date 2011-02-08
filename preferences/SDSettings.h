#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTextFieldSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSetupListController.h>
#import <Preferences/PSSetupController.h>

@interface SDSettingsController : PSListController {
}
- (id)initForContentSize:(CGSize)size;
- (id)specifiers;
@end
