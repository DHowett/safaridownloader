#import "SDMCommon.h"
#import "SDDownloadRequest.h"
#import "SDFileBrowserNavigationController.h"

@protocol SDDownloadPrompt <NSObject>
@property (nonatomic, retain) SDDownloadRequest *downloadRequest;
@end

@protocol SDDownloadPromptDelegate <NSObject>
- (void)downloadPrompt:(NSObject<SDDownloadPrompt> *)downloadPrompt didCompleteWithAction:(SDActionType)action;
@end

@interface SDDownloadPromptViewController : UITableViewController <SDDownloadPrompt, SDFileBrowserDelegate> {
	NSObject<SDDownloadPromptDelegate> *_delegate;
	SDDownloadRequest *_downloadRequest;
	NSMutableArray *_supportedActions;
}
@property (nonatomic, assign) NSObject<SDDownloadPromptDelegate> *delegate;
@property (nonatomic, retain) SDDownloadRequest *downloadRequest;
- (id)initWithDownloadRequest:(SDDownloadRequest *)downloadRequest delegate:(id)delegate;
- (void)dismissWithCancel;
@end
