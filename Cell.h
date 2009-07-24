#import <UIKit/UIKit.h>
#import "BaseCell.h"

@interface Cell : BaseCell {
	BOOL finished;
	UIProgressView *progressView;
	NSString *nameLabel;
	NSString *progressLabel;
	NSString *speedLabel;
}

@property (nonatomic, retain) NSString *nameLabel;
@property (nonatomic, retain) NSString *progressLabel;
@property (nonatomic, retain) NSString *speedLabel;
@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, assign) BOOL finished;

@end
