#include "SafariDownload.h"

extern const int kSDDownloadActionSheetTag;

@class SDDownloadActionSheet;

@protocol SDDownloadActionSheetDelegate
- (void)downloadActionSheet:(SDDownloadActionSheet *)actionSheet retryDownload:(SDSafariDownload *)download;
- (void)downloadActionSheet:(SDDownloadActionSheet *)actionSheet deleteDownload:(SDSafariDownload *)download;
@end

@interface UIActionSheet (Private)
- (id)buttonAtIndex:(int)index;
@end

@interface SDDownloadActionSheet: UIActionSheet <UIActionSheetDelegate> {
	id _documentInteractionController;
	NSArray *_applications;
	SDSafariDownload *_download;
	id<SDDownloadActionSheetDelegate> _sdDelegate;
}
@property(readonly) SDSafariDownload *download;
- (id)initWithDownload:(SDSafariDownload *)download delegate:(id<SDDownloadActionSheetDelegate>)delegate;
@end
