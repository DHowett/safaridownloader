@interface SDRoundedButton : UIButton {
	NSMutableDictionary *_borderColors;
}
- (id)initWithFrame:(CGRect)frame;
- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state;
- (UIColor *)borderColorForState:(UIControlState)state;
@end
