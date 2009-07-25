#import "Cell.h"

// Tastiez Macro
#define RefreshCellSetter(ptr, sptr) if(!sptr) { return; } \
[sptr retain]; \
[ptr release]; \
ptr = sptr; \
[self setNeedsDisplay];

@implementation Cell

static UIFont *filenameFont = nil;
static UIFont *speedFont = nil;
static UIFont *progressFont = nil;
@synthesize finished, nameLabel, progressView, speedLabel, progressLabel;

+ (void)initialize {
	if(self == [Cell class]) {
		filenameFont = [[UIFont boldSystemFontOfSize:14] retain];
		speedFont = [[UIFont systemFontOfSize:12] retain];
    progressFont = [[UIFont boldSystemFontOfSize:13] retain];
	}
}

- (void)prepareForReuse
{
  self.nameLabel = nil;
  self.speedLabel = nil;
  self.progressLabel = nil;
  progressView.progress = 0.0;
}

- (void)setNameLabel:(NSString *)s {
	RefreshCellSetter(nameLabel, s)
}

- (void)setSpeedLabel:(NSString *)s {
	RefreshCellSetter(speedLabel, s)
}

- (void)setProgressLabel:(NSString *)s {
	RefreshCellSetter(progressLabel, s)
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
      progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(110, 34, 190, 20)];
      [self addSubview:progressView];
      [progressView release];
    }
	}
  
	[self setNeedsDisplay];
}	

- (void)dealloc 
{
  [nameLabel release];
  [speedLabel release];
  [progressLabel release];
	[progressView release];
  [super dealloc];
}

- (void)willTransitionToState:(UITableViewCellStateMask)state {
	[super willTransitionToState:state];
	if(!finished) {
		if(state & UITableViewCellStateShowingDeleteConfirmationMask) {
			[progressView setFrame:CGRectMake(110, 34, 140, 20)];
		} else {
			[progressView setFrame:CGRectMake(110, 34, 190, 20)];
		}
	}

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
	if(self.showingDeleteConfirmation) deleteButtonMargin = 50.0f;

	[backgroundColor set];
	CGContextFillRect(context, r);
	
	[textColor set];
	NSString *filenameString = nameLabel;
	CGSize filenameSize = [filenameString sizeWithFont:filenameFont forWidth:(190-(deleteButtonMargin+offset)) lineBreakMode:UILineBreakModeTailTruncation];
	CGRect filenameRect = CGRectMake(110 + offset, 12, filenameSize.width, filenameSize.height);
	
	[filenameString drawInRect:filenameRect withFont:filenameFont lineBreakMode:UILineBreakModeTailTruncation];
	
	[userColor set];
	NSString *bString = progressLabel;
	CGSize bSize = [bString sizeWithFont:progressFont forWidth:(200-(deleteButtonMargin + offset)) lineBreakMode:UILineBreakModeTailTruncation];
	CGRect bRect = CGRectMake(110 + offset, 46, bSize.width, bSize.height);
	CGRect timeRect = CGRectMake(110 + offset, 61, 190 - deleteButtonMargin - offset, 15);
	
  [bString drawInRect:bRect withFont:progressFont lineBreakMode:UILineBreakModeTailTruncation];
	
//	[timeLabel drawInRect:timeRect withFont:infoFont];
	
//  [thumbView drawAtPoint:CGPointMake(8+offset, 8)];*/
//	[thumbView drawInRect:CGRectMake(0, 0, 100, 88)];
}

@end

// vim:filetype=objc:ts=2:sw=2:expandtab
