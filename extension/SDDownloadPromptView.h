#import "DownloaderCommon.h"

#import "SDDownloadRequest.h"

#import "RotatableBrowserPanel.h"

@class SDDownloadPromptView;

@protocol SDDownloadPromptViewDelegate <NSObject>
- (void)downloadPromptView:(SDDownloadPromptView *)downloadPromptView didCompleteWithAction:(int)action;
@end

@class SDRoundedButton;
@interface SDDownloadPromptView : UIView <RotatableBrowserPanel> {
	NSObject<SDDownloadPromptViewDelegate> *_delegate;
	SDDownloadRequest *_downloadRequest;
	UILabel *_titleLabel;
	UIImageView *_iconImageView;
	NSMutableArray *_supportedActions;
	SDRoundedButton *_downloadButton;
	SDRoundedButton *_downloadToButton;
	SDRoundedButton *_viewButton;
	SDRoundedButton *_cancelButton;
}
@property (nonatomic, assign) NSObject<SDDownloadPromptViewDelegate> *delegate;
@property (nonatomic, retain) SDDownloadRequest *downloadRequest;
- (id)initWithDownloadRequest:(SDDownloadRequest *)downloadRequest delegate:(id)delegate;
- (void)setVisible:(BOOL)visible animated:(BOOL)animated;
- (void)dismissWithCancel;
- (void)dismissWithCancelAnimated:(BOOL)animated;
@end
