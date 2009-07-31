#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTextFieldSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSetupListController.h>
#import <Preferences/PSSetupController.h>
#import <UIKit/UIPreferencesDeleteTableCell.h>
#import <DHLocalizedListController.h>

@interface SDSettingsController : DHLocalizedListController {
}
- (id)initForContentSize:(CGSize)size;
- (id)specifiers;
@end
