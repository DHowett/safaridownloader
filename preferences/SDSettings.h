#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTextFieldSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSetupListController.h>
#import <Preferences/PSSetupController.h>

@interface SDListController : PSListController
- (id)specifiers;
@end

@interface SDSettingsController : SDListController
- (id)initForContentSize:(CGSize)size;
@end
