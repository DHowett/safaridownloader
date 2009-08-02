#import "DownloadCell.h"

#define RefreshCellSetter(ptr, sptr) if(!sptr) { return; } \
[sptr retain]; \
[ptr release]; \
ptr = sptr; \
[self setNeedsDisplay];

@implementation DownloadCell

#define SIDE_PADDING 16

static UIFont *filenameFont = nil;
static UIFont *speedFont = nil;
static UIFont *progressFont = nil;
@synthesize finished, nameLabel, progressView, sizeLabel, progressLabel, completionLabel, icon = _icon;

+ (void)initialize {
	if(self == [DownloadCell class]) {
		filenameFont = [[UIFont boldSystemFontOfSize:14] retain];
		speedFont = [[UIFont systemFontOfSize:12] retain];
    progressFont = [[UIFont boldSystemFontOfSize:13] retain];
	}
}

- (void)prepareForReuse
{
  self.nameLabel = nil;
  self.sizeLabel = nil;
  self.progressLabel = nil;
  self.completionLabel = nil;
  progressView.progress = 0.0;
}

- (void)setNameLabel:(NSString *)s {
	RefreshCellSetter(nameLabel, s)
}

- (void)setSizeLabel:(NSString *)s {
	RefreshCellSetter(sizeLabel, s)
}

- (void)setProgressLabel:(NSString *)s {
	RefreshCellSetter(progressLabel, s)
}

- (void)setCompletionLabel:(NSString *)s {
	RefreshCellSetter(completionLabel, s)
}

- (void)setIcon:(UIImage *)ic {
  RefreshCellSetter(_icon, ic);
}

- (void)setFinished:(BOOL)x 
{
	finished = x;
  
  if (finished) {
		if(progressView) {
			[progressView removeFromSuperview];
      progressView = nil;
		}
	} else {
    if(!progressView) {
      progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(SIDE_PADDING, 34, 320 - SIDE_PADDING - 16, 20)];
      [self addSubview:progressView];
      [progressView release];
    }
	}
  
	[self setNeedsDisplay];
}	

- (void)dealloc 
{
  [nameLabel release];
  [sizeLabel release];
  [progressLabel release];
	[progressView release];
  [completionLabel release];
  [super dealloc];
}

- (void)willTransitionToState:(UITableViewCellStateMask)state {
	[super willTransitionToState:state];
	[self setNeedsDisplay];
}

- (void)setEditing:(BOOL)editing {
  [super setEditing:editing];
  [self setNeedsDisplay];
}

- (void)drawContentView:(CGRect)r {
	CGContextRef context = UIGraphicsGetCurrentContext();	
	UIColor *backgroundColor = nil;
	UIColor *textColor = nil;
	UIColor *userColor = nil;
  float offset = 0.0f;
	float deleteButtonMargin = 0.0f;
  float cellWidth = r.size.width;
  
	if(self.selected) {
		textColor = [UIColor whiteColor];
		backgroundColor = [UIColor clearColor];
		userColor = [UIColor whiteColor];
	} else {
		textColor = [UIColor blackColor];
		backgroundColor = [UIColor whiteColor];
		userColor = [UIColor grayColor];
	}
  
  //if(self.editing) offset = 30.0f;
	if(self.showingDeleteConfirmation) {
    deleteButtonMargin = 50.0f;
    if(!finished) deleteButtonMargin += 16.0f;
  }
  
	[backgroundColor set];
	CGContextFillRect(context, r);
	
  [_icon drawAtPoint:CGPointMake(SIDE_PADDING, 7)];
  
	[textColor set];
	NSString *filenameString = nameLabel;
	CGSize filenameSize = [filenameString sizeWithFont:filenameFont
                                            forWidth:(cellWidth - (2 * SIDE_PADDING) - (deleteButtonMargin+offset) - (_icon.size.width + 5)) - 19.0
                                       lineBreakMode:UILineBreakModeTailTruncation];
	CGRect filenameRect = CGRectMake(SIDE_PADDING + offset + _icon.size.width + 5, 9, filenameSize.width, filenameSize.height);
	
  CGSize completionSize = [sizeLabel sizeWithFont:progressFont forWidth:100 lineBreakMode:UILineBreakModeTailTruncation];
	
	[filenameString drawInRect:filenameRect withFont:filenameFont lineBreakMode:UILineBreakModeTailTruncation];
  
	[userColor set];
  if (!finished) { // don't draw the progress % if this is a completed download
	  CGRect completionRect = CGRectMake(cellWidth - SIDE_PADDING - completionSize.width - deleteButtonMargin, 15, completionSize.width, completionSize.height);
    [completionLabel drawInRect:completionRect withFont:progressFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
  }
  
  float progressBarHeightOffset = 5.0f;
  if(!finished) progressBarHeightOffset = 18.0f;
  
	NSString *bString = progressLabel;
	CGSize bSize = [bString sizeWithFont:progressFont forWidth:(10+200-(deleteButtonMargin + offset)) lineBreakMode:UILineBreakModeTailTruncation];
	CGRect bRect = CGRectMake(SIDE_PADDING + offset, 28 + progressBarHeightOffset, bSize.width, bSize.height);
  
  CGSize sizeSize = [sizeLabel sizeWithFont:progressFont forWidth:100 lineBreakMode:UILineBreakModeTailTruncation];
	CGRect sizeRect = CGRectMake(cellWidth - SIDE_PADDING - sizeSize.width - deleteButtonMargin, 28 + progressBarHeightOffset, sizeSize.width, sizeSize.height);
	
  [bString drawInRect:bRect withFont:progressFont lineBreakMode:UILineBreakModeTailTruncation];
  [sizeLabel drawInRect:sizeRect withFont:progressFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
	
  [progressView setFrame:CGRectMake(SIDE_PADDING, 34, cellWidth - SIDE_PADDING - 16 - (deleteButtonMargin + offset), 20)];
  //	[timeLabel drawInRect:timeRect withFont:infoFont]; // :O zomg nowai
  //  [thumbView drawAtPoint:CGPointMake(8+offset, 8)];*/
  //	[thumbView drawInRect:CGRectMake(0, 0, 100, 88)];
}

@end

// vim:filetype=objc:ts=2:sw=2:expandtab
