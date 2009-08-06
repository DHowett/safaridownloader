#import "BaseCell.h"

@interface BaseCellView : UIView
@end

@implementation BaseCellView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  ((BaseCell *)[self superview]).selected = YES;
  [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  ((BaseCell *)[self superview]).selected = NO;
  [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  ((BaseCell *)[self superview]).selected = NO;
  [super touchesCancelled:touches withEvent:event];
}

- (void)drawRect:(CGRect)r {
	[(BaseCell *)[self superview] drawContentView:r];
}

@end

@implementation BaseCell

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
  if(self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
  {
		contentView = [[BaseCellView alloc] initWithFrame:CGRectZero];
		contentView.opaque = YES;
    self.opaque = YES;
		[self addSubview:contentView];
		[contentView release];
  }
  return self;
}

- (void)dealloc {
	[super dealloc];
}

- (void)setFrame:(CGRect)f {
	[super setFrame:f];
	CGRect b = [self bounds];
	b.size.height -= 1;
	[contentView setFrame:b];
}

- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	[contentView setNeedsDisplay];
}

- (void)drawContentView:(CGRect)r {
	// subclasses should implement this
}

@end

// vim:filetype=objc:ts=2:sw=2:expandtab
