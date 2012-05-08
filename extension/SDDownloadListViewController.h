/*
 * SDDownloadListViewController
 * SDM
 * Dustin Howett 2012-01-30
 */

#import <UIKit/UIKit.h>

@class SDDownloadModel;
@interface SDDownloadListViewController : UITableViewController {
	NSIndexPath *_currentSelectedIndexPath;
	SDDownloadModel *_dataModel;
	NSTimer *_updateTimer;
}
@property (nonatomic, retain) NSIndexPath *currentSelectedIndexPath;
@end
