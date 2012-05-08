#import <objc/runtime.h>
#import "SDDownloadActionSheet.h"
#import <SandCastle/SandCastle.h>

#import <UIKit/UIDocumentInteractionController.h>

const int kSDDownloadActionSheetTag = 903403;

static NSMutableDictionary *_launchActions;

@class LSApplicationProxy;
@interface LSApplicationProxy : NSObject
- (id)app;
- (id)localizedName;
@end

@implementation SDDownloadActionSheet
@synthesize download = _download;

+ (void)initialize {
	Class $SandCastle = objc_getClass("SandCastle");
	_launchActions = [[NSMutableDictionary alloc] init];
	if ([[$SandCastle sharedInstance] fileExistsAtPath:@"/Applications/iFile.app"]) {
		[_launchActions setObject:@"ifile://" forKey:@"Open in iFile"];
	}
}

- (id)initWithDownload:(SDSafariDownload *)download delegate:(id<SDDownloadActionSheetDelegate>)delegate {
	self = [super initWithTitle:download.filename delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
	if(self) {
		_sdDelegate = delegate;
		self.tag = kSDDownloadActionSheetTag;
		_download = download;
		if(_download.status == SDDownloadStatusFailed) [self addButtonWithTitle:@"Retry"];
		else {
			_documentInteractionController = [[objc_getClass("UIDocumentInteractionController") interactionControllerWithURL:
						[NSURL fileURLWithPath:[_download.path stringByAppendingPathComponent:_download.filename]]] retain];
			if(_documentInteractionController) {
				int buttonIndex = 0;
				_applications = [[_documentInteractionController _applications:YES] retain];
				for(LSApplicationProxy *app in _applications) {
					UIButton *button = [self buttonAtIndex:[self addButtonWithTitle:[NSString stringWithFormat:@"Open in %@", [app localizedName]]]];
					button.tag = -1 * (50+buttonIndex);
					NSLog(@"Added button with tag %d", button.tag);
					buttonIndex++;
				}
			} else {
				for(NSString *title in _launchActions) {
					[self buttonAtIndex:[self addButtonWithTitle:title]];
				}
			}
		}
		self.cancelButtonIndex = [self addButtonWithTitle:@"Cancel"];
	}
	return self;
}

- (void)dealloc {
	[_applications release];
	[_documentInteractionController release];
	[super dealloc];
}

- (void)_IPCOpenWithAppID:(int)appId {
	[_documentInteractionController _openDocumentWithApplication:[_applications objectAtIndex:appId-1]];
}

- (void)actionSheet:(SDDownloadActionSheet *)actionSheet clickedButtonAtIndex:(int)index {
	[_sdDelegate downloadActionSheetWillDismiss:self];
	NSString *button = index >= 0 ? [self buttonTitleAtIndex:index] : nil;
	if([button isEqualToString:@"Delete"]) {
		[_sdDelegate downloadActionSheet:actionSheet deleteDownload:_download];
	} else if([button isEqualToString:@"Retry"]) {
		[_sdDelegate downloadActionSheet:actionSheet retryDownload:_download];
	} else {
		NSLog(@"button clicked with tag %d", index);
		if(index < 0) {
			[self _IPCOpenWithAppID:(-1*index)-50];
		} else {
			NSString *action = [_launchActions objectForKey:button];
			if(action) {
				Class Application = objc_getClass("Application");
				NSString *path = [_download.path stringByAppendingPathComponent:_download.filename];
				path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				[[Application sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", action, path]]];
			}
		}
	}
}
@end

// vim:ft=objc
