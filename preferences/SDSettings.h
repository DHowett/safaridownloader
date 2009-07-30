#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTextFieldSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <DHLocalizedListController.h>

@interface SDSettingsController : DHLocalizedListController {
}
- (id)initForContentSize:(CGSize)size;
- (id)specifiers;
@end
