/*
 * SDNavigationController
 * SDM
 * Dustin Howett 2012-01-30
 */

#import "WebUI/BrowserPanel.h"

@interface SDNavigationController : UINavigationController <BrowserPanel> {
}
- (void)close;
@end
