#import "SDRoundedButton.h"

#import <QuartzCore/QuartzCore.h>

@implementation SDRoundedButton
- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame]) != nil) {
		_borderColors = [[NSMutableDictionary alloc] init];
		self.layer.borderWidth = 2.f;
		self.layer.cornerRadius = 8.f;
	} return self;
}

- (void)dealloc {
	[_borderColors release];
	[super dealloc];
}

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state {
	[_borderColors setObject:color forKey:[NSNumber numberWithInt:state]];
	[self setNeedsLayout];
}

- (UIColor *)borderColorForState:(UIControlState)state {
	return [_borderColors objectForKey:[NSNumber numberWithInt:state]] ?: [_borderColors objectForKey:[NSNumber numberWithInt:UIControlStateNormal]];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	UIColor *borderColor = [self borderColorForState:self.state] ?: [self titleColorForState:self.state];
	self.layer.borderColor = borderColor.CGColor;
}
@end
