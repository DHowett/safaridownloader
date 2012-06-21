#import "SDMCommon.h"

/*@protocol SDDownloadPrompt <NSObject>
@property (nonatomic, retain) SDDownloadRequest *downloadRequest;
@end

@protocol SDDownloadPromptDelegate <NSObject>
- (void)downloadPrompt:(NSObject<SDDownloadPrompt> *)downloadPrompt didCompleteWithAction:(SDActionType)action;
@end
*/

@interface SDDirectoryListViewController : UITableViewController /*<SDDownloadPrompt>*/ {
	NSString *_currentPath;
	NSArray *_fileList;
}
@property (nonatomic, copy) NSString *currentPath;
- (id)initWithPath:(NSString *)path;
- (void)reloadData;
@end
