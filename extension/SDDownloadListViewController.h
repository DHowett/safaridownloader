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

	UIBarButtonItem *_doneButton;
	UIBarButtonItem *_cancelButton;
	UIBarButtonItem *_clearButton;
}
@property (nonatomic, retain) NSIndexPath *currentSelectedIndexPath;
@end
