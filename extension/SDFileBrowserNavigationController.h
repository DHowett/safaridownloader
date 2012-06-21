#import "SDNavigationController.h"
#import "SDDownloadRequest.h"

typedef enum {
	SDFileBrowserModeSelectPath = 0,
	SDFileBrowserModeImmediateDownload
} SDFileBrowserMode;

@class SDFileBrowserNavigationController;
@protocol SDFileBrowserDelegate <NSObject>
- (void)fileBrowserDidCancel:(SDFileBrowserNavigationController *)fileBrowser;
- (void)fileBrowser:(SDFileBrowserNavigationController *)fileBrowser didSelectPath:(NSString *)path;
@end

@interface SDFileBrowserNavigationController : SDNavigationController {
	SDFileBrowserMode _mode;
	SDDownloadRequest *_downloadRequest;
	NSString *_path;
	NSArray *_browserToolbarItems;
	NSObject<SDFileBrowserDelegate> *_fileBrowserDelegate;
}
@property (nonatomic, assign) NSObject<SDFileBrowserDelegate> *fileBrowserDelegate;
@property (nonatomic, retain) SDDownloadRequest *downloadRequest;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, retain, readonly) NSArray *browserToolbarItems;
- (id)initWithMode:(SDFileBrowserMode)mode;
- (id)initWithMode:(SDFileBrowserMode)mode downloadRequest:(SDDownloadRequest *)downloadRequest;
@end
