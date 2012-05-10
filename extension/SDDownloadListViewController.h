/*
 * SDDownloadListViewController
 * SDM
 * Dustin Howett 2012-01-30
 */

#import <UIKit/UIKit.h>

#import "SDDownloadActionSheet.h"
#import "SDSafariDownload.h"

@class SDDownloadModel;
@protocol SDDownloadActionSheetDelegate;

@interface SDDownloadListViewController : UITableViewController <UIActionSheetDelegate, SDDownloadActionSheetDelegate, SDSafariDownloadDelegate> {
	NSIndexPath *_currentSelectedIndexPath;
	SDDownloadModel *_dataModel;
	NSTimer *_updateTimer;
}
@property (nonatomic, retain) NSIndexPath *currentSelectedIndexPath;
@end
