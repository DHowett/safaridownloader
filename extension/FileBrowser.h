#import "UIKitExtra/UINavigationButton.h"

@class FileBrowser;
@protocol FileBrowserDelegate
- (void)fileBrowser:(FileBrowser*)browser didSelectPath:(NSString*)path forFile:(id)file withContext:(id)context;
- (void)fileBrowserDidCancel:(FileBrowser*)browser;
@end

@interface FileBrowser : UIAlertView <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
  UITableView *myTableView;
  id<FileBrowserDelegate> _browserDelegate;
  id context;
  NSArray *data;
  NSString* currentPath;
  id file;
	int tableHeight;
  UINavigationButton* navButton;
}

@property(nonatomic, assign) id<FileBrowserDelegate> browserDelegate;
@property(nonatomic, retain) id context;
@property(nonatomic, retain) NSArray *data;
@property(nonatomic, copy) NSString *currentPath;
@property(nonatomic, retain) id file;


+ (FileBrowser*)activeInstance;
+ (BOOL)alertViewShown;

- (id)initWithFile:(id)att context:(id)ctx delegate:(id)del;
- (NSString*)resizeToFitCount:(NSUInteger)count;
@end

@interface FileBrowser(PRIVATE)
-(void)prepare;
@end
