#import "BaseCell.h"

@interface SDBaseCellView : UIView
@end

@implementation SDBaseCellView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  ((SDBaseCell *)[self superview]).selected = YES;
  [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  ((SDBaseCell *)[self superview]).selected = NO;
  [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  ((SDBaseCell *)[self superview]).selected = NO;
  [super touchesCancelled:touches withEvent:event];
}

- (void)drawRect:(CGRect)r {
	[(SDBaseCell *)[self superview] drawContentView:r];
}

@end

@implementation SDBaseCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) 
  {
	contentView = [[SDBaseCellView alloc] initWithFrame:CGRectZero];
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
