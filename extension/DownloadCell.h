#import <UIKit/UIKit.h>
#import "BaseCell.h"

@interface SDDownloadCell : SDBaseCell {
  BOOL finished;
  BOOL failed;
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
@property (nonatomic, assign) BOOL failed;

@end
