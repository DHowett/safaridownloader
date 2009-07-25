#import <UIKit/UIKit.h>
#import "BaseCell.h"

@interface Cell : BaseCell {
	BOOL finished;
	UIProgressView *progressView;
	NSString *nameLabel;
	NSString *progressLabel;
	NSString *completionLabel;
	NSString *sizeLabel;
  UIImage  *_icon;
}

@property (nonatomic, retain) NSString *nameLabel;
@property (nonatomic, retain) NSString *progressLabel;
@property (nonatomic, retain) NSString *completionLabel;
@property (nonatomic, retain) NSString *sizeLabel;
@property (nonatomic, retain) UIImage  *icon;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, assign) BOOL finished;

@end