#import <UIKit/UIKit.h>

@interface SDBaseCell : UITableViewCell {
	UIView *contentView;
}

- (void)drawContentView:(CGRect)r;

@end
