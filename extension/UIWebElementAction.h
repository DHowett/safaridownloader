@interface UIWebElementAction : NSString {
	NSString *_title;	// 4 = 0x4
	id _actionHandler;	// 8 = 0x8
	int _type;	// 12 = 0xc
}
@property(readonly, assign, nonatomic) int type;	// G=0x244ec1; @synthesize=_type
+ (id)customElementActionWithTitle:(id)title actionHandler:(id)handler;	// 0x244945
+ (id)standardElementActionWithType:(int)type;	// 0x244e15
+ (id)standardElementActionWithType:(int)type customTitle:(id)title;	// 0x2449d9
- (id)initWithTitle:(id)title actionHandler:(id)handler type:(int)type;	// 0x24485d
- (void)_runActionWithElement:(id)element targetURL:(id)url documentView:(id)view interactionLocation:(CGPoint)location;	// 0x244e39
- (id)_title;	// 0x244e29
- (void)dealloc;	// 0x2448e5
// declared property getter: - (int)type;	// 0x244ec1
@end

