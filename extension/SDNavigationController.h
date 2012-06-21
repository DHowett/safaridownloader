/*
 * SDNavigationController
 * SDM
 * Dustin Howett 2012-01-30
 */

#import "WebUI/BrowserPanel.h"

@interface SDNavigationController : UINavigationController <BrowserPanel> {
	BOOL _standalone;
}
@property (nonatomic, assign) BOOL standalone;
- (void)close;
@end
