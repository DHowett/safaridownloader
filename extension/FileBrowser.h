#import "UIKitExtra/UINavigationButton.h"

@class YFFileBrowser;
@protocol YFFileBrowserDelegate
- (void)fileBrowser:(YFFileBrowser*)browser didSelectPath:(NSString*)path forFile:(id)file withContext:(id)context;
- (void)fileBrowserDidCancel:(YFFileBrowser*)browser;
@end

@interface YFFileBrowser : UIAlertView <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
  UITableView *myTableView;
  id<YFFileBrowserDelegate> _browserDelegate;
  id context;
  NSArray *data;
  NSString* currentPath;
  id file;
	int tableHeight;
  UINavigationButton* navButton;
}

@property(nonatomic, assign) id<YFFileBrowserDelegate> browserDelegate;
@property(nonatomic, retain) id context;
@property(nonatomic, retain) NSArray *data;
@property(nonatomic, copy) NSString *currentPath;
@property(nonatomic, retain) id file;


+ (YFFileBrowser*)activeInstance;
+ (BOOL)alertViewShown;

- (id)initWithFile:(id)att context:(id)ctx delegate:(id)del;
- (NSString*)resizeToFitCount:(NSUInteger)count;
@end

@interface YFFileBrowser(PRIVATE)
-(void)prepare;
@end
