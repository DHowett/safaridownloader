#import <UIKit/UIKit.h>

@interface BaseCell : UITableViewCell {
	UIView *contentView;
}

- (void)drawContentView:(CGRect)r;

@end
