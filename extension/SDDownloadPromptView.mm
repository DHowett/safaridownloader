#import <QuartzCore/QuartzCore.h>

#import "SDDownloadPromptView.h"
#import "SDMCommonClasses.h"
#import "DownloadManager.h"
#import "SDRoundedButton.h"

#import "SDResources.h"
#import "SDFileType.h"

#import "Safari/BrowserController.h"

const NSString *const kSDMAnimationContextShowing = @"kSDMAnimationContextShowing";
const NSString *const kSDMAnimationContextHiding = @"kSDMAnimationContextHiding";

@implementation SDDownloadPromptView
@synthesize delegate = _delegate;
@synthesize downloadRequest = _downloadRequest;

- (int)panelType { return SDPanelTypeDownloadPrompt; }
- (BOOL)pausesPages { return YES; }
- (BOOL)allowsRotation { return YES; }
- (int)panelState { return 0; }

- (id)initWithDownloadRequest:(SDDownloadRequest *)downloadRequest delegate:(id)delegate {
	if((self = [super initWithFrame:CGRectZero]) != nil) {
		self.downloadRequest = downloadRequest;

		self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.8f];
		self.layer.cornerRadius = 4.f;
		self.layer.borderWidth = 1.f;
		self.layer.borderColor = [[UIColor blackColor] CGColor];
		self.delegate = delegate;
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_titleLabel.text = downloadRequest.filename;
		_titleLabel.font = [UIFont boldSystemFontOfSize:22.f];
		_titleLabel.textAlignment = UITextAlignmentCenter;
		_titleLabel.textColor = [UIColor whiteColor];
		_titleLabel.shadowColor = [UIColor blackColor];
		_titleLabel.shadowOffset = (CGSize){0.f, 1.f};
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
		_titleLabel.adjustsFontSizeToFitWidth = YES;
		_titleLabel.minimumFontSize = 14.f;
		[self addSubview:_titleLabel];

		NSLog(@"mime type is %@", downloadRequest.mimeType);
		UIImage *iconImage = [SDResources iconForFileType:[SDFileType fileTypeForExtension:[downloadRequest.filename pathExtension] orMIMEType:downloadRequest.mimeType]];
		_iconImageView = [[UIImageView alloc] initWithImage:iconImage];
		[self addSubview:_iconImageView];
	} return self;
}

- (void)dealloc {
	[_titleLabel release];
	[_iconImageView release];

	[_downloadRequest release];
	[super dealloc];
}

- (void)_createButtons {
	_downloadButton = [[SDRoundedButton alloc] initWithFrame:CGRectZero];
	[_downloadButton setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:.5f]];
	[_downloadButton setBorderColor:[[UIColor redColor] colorWithAlphaComponent:.6f] forState:UIControlStateNormal];
	[_downloadButton setBorderColor:[[UIColor redColor] colorWithAlphaComponent:.3f] forState:UIControlStateHighlighted];
	[_downloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[_downloadButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
	[_downloadButton setTitle:@"Download" forState:UIControlStateNormal];
	_downloadButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.f];
	[_downloadButton addTarget:self action:@selector(_actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	_downloadButton.tag = SDActionTypeDownload;
	[self addSubview:_downloadButton];

	_downloadToButton = [[SDRoundedButton alloc] initWithFrame:CGRectZero];
	[_downloadToButton setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:.5f]];
	[_downloadToButton setBorderColor:[[UIColor redColor] colorWithAlphaComponent:.6f] forState:UIControlStateNormal];
	[_downloadToButton setBorderColor:[[UIColor redColor] colorWithAlphaComponent:.3f] forState:UIControlStateHighlighted];
	[_downloadToButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[_downloadToButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
	[_downloadToButton setTitle:@"…" forState:UIControlStateNormal];
	_downloadToButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.f];
	[_downloadToButton addTarget:self action:@selector(_actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	_downloadToButton.tag = SDActionTypeDownloadAs;
	[self addSubview:_downloadToButton];

	if(_downloadRequest.supportsViewing) {
		_viewButton = [[SDRoundedButton alloc] initWithFrame:CGRectZero];
		[_viewButton setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:.5f]];
		[_viewButton setBorderColor:[[UIColor whiteColor] colorWithAlphaComponent:.6f] forState:UIControlStateNormal];
		[_viewButton setBorderColor:[[UIColor whiteColor] colorWithAlphaComponent:.3f] forState:UIControlStateHighlighted];
		[_viewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
		[_viewButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
		[_viewButton setTitle:@"View" forState:UIControlStateNormal];
		_viewButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.f];
		[_viewButton addTarget:self action:@selector(_actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		_viewButton.tag = SDActionTypeView;
		[self addSubview:_viewButton];
	}

	_cancelButton = [[SDRoundedButton alloc] initWithFrame:CGRectZero];
	[_cancelButton setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:.5f]];
	[_cancelButton setBorderColor:[[UIColor grayColor] colorWithAlphaComponent:.6f] forState:UIControlStateNormal];
	[_cancelButton setBorderColor:[[UIColor grayColor] colorWithAlphaComponent:.3f] forState:UIControlStateHighlighted];
	[_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[_cancelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
	[_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
	_cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:20.f];
	[_cancelButton addTarget:self action:@selector(dismissWithCancel) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:_cancelButton];
}

- (void)_actionButtonTapped:(UIButton *)s {
	[_delegate downloadPromptView:self didCompleteWithAction:s.tag];
	[self setVisible:NO animated:YES];
}

- (void)sizeToFit {
	CGFloat height;
	if(_downloadRequest.supportsViewing) {
		height = 172.f;
	} else {
		height = 128.f;
	}
	self.frame = (CGRect){self.frame.origin, {280.f, height}};
}

- (void)layoutSubviews {
	if(!_downloadButton) {
		[self _createButtons];
	}

	CGRect bounds = self.bounds;
	[_titleLabel sizeToFit];
	CGSize titleLabelSize = _titleLabel.frame.size;
	CGSize iconSize = _iconImageView.image.size;
	CGFloat totalWidth = iconSize.width + 4.f + titleLabelSize.width;
	totalWidth = MIN(totalWidth, bounds.size.width-8.f);
	_titleLabel.frame = (CGRect){{(bounds.size.width-totalWidth)/2.f+iconSize.width+4.f, 2.f}, {MIN(titleLabelSize.width, totalWidth-iconSize.width-4.f), titleLabelSize.height}};
	_iconImageView.frame = (CGRect){{(bounds.size.width-totalWidth)/2.f, CGRectGetMaxY(_titleLabel.frame)-iconSize.height}, iconSize};

	_downloadButton.frame = (CGRect){{4.f, 38.f}, {272.f-4.f-40.f, 40.f}};
	_downloadToButton.frame = (CGRect){{4.f+272.f-40.f, 38.f}, {40.f, 40.f}};
	_cancelButton.frame = (CGRect){{4.f, (_downloadRequest.supportsViewing ? 126.f : 82.f)}, {272.f, 40.f}};
	_viewButton.frame = (CGRect){{4.f, 82.f}, {272.f, 40.f}};
}

- (void)dismissWithCancel {
	[self dismissWithCancelAnimated:YES];
}

- (void)dismissWithCancelAnimated:(BOOL)animated {
	[_delegate downloadPromptView:self didCompleteWithAction:SDActionTypeNone];
	[self setVisible:NO animated:animated];
}

- (void)_animationDidStop:(NSString *)animationID finished:(BOOL)finished context:(NSString *)context {
	if(context == kSDMAnimationContextShowing) {
		[[SDM$BrowserController sharedBrowserController] didShowBrowserPanel:self];
	} else if(context == kSDMAnimationContextHiding) {
		[self removeFromSuperview];
		[[SDM$BrowserController sharedBrowserController] didHideBrowserPanel:self];
	}
}

- (void)setVisible:(BOOL)visible animated:(BOOL)animated {
	if(visible) {
		[[SDM$BrowserController sharedBrowserController] willShowBrowserPanel:self];

		UIView *superview = [[SDM$BrowserController sharedBrowserController] _panelSuperview];
		[self sizeToFit];
		self.center = (CGPoint){superview.bounds.size.width/2.f, superview.bounds.size.height/2.f};
		self.alpha = 0.f;
		[superview addSubview:self];
		if(animated) {
			[UIView beginAnimations:nil context:(void*)kSDMAnimationContextShowing];
			[UIView setAnimationDidStopSelector:@selector(_animationDidStop:finished:context:)];
			[UIView setAnimationDelegate:self];
		}
		self.alpha = 1.f;
		if(animated) [UIView commitAnimations];
		else
			[self _animationDidStop:nil finished:YES context:kSDMAnimationContextShowing];
	} else {
		if(animated) {
			[UIView beginAnimations:nil context:(void*)kSDMAnimationContextHiding];
			[UIView setAnimationDidStopSelector:@selector(_animationDidStop:finished:context:)];
			[UIView setAnimationDelegate:self];
		}
		self.alpha = 0.f;
		if(animated) [UIView commitAnimations];
		else
			[self _animationDidStop:nil finished:YES context:kSDMAnimationContextShowing];
	}
}

- (void)willRotateToInterfaceOrientation:(int)interfaceOrientation duration:(double)duration { }
- (void)didRotateFromInterfaceOrientation:(int)interfaceOrientation { }

- (void)willAnimateRotationToInterfaceOrientation:(int)interfaceOrientation duration:(double)duration {
	self.center = (CGPoint){self.superview.bounds.size.width/2.f, self.superview.bounds.size.height/2.f};
}

@end
