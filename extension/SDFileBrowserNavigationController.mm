#import "SDFileBrowserNavigationController.h"
#import "SDDirectoryListViewController.h"
#import "SDMCommon.h"

#import "SDResources.h"
#import "SDUserSettings.h"

@interface SDFileBrowserNavigationController ()
@property (nonatomic, copy) NSString *path;
- (NSArray *)_viewControllersForPath:(NSString *)path rootedAt:(NSString *)root;
@end

@implementation SDFileBrowserNavigationController
@synthesize downloadRequest = _downloadRequest;
@synthesize path = _path;
@synthesize fileBrowserDelegate = _fileBrowserDelegate;
@synthesize browserToolbarItems = _browserToolbarItems;

- (int)panelType { return SDPanelTypeFileBrowser; }

- (UIModalPresentationStyle)modalPresentationStyle {
	return SDM$WildCat ? UIModalPresentationFormSheet : UIModalPresentationFullScreen;
}

- (id)initWithMode:(SDFileBrowserMode)mode {
	return [self initWithMode:mode downloadRequest:nil];
}

- (id)initWithMode:(SDFileBrowserMode)mode downloadRequest:(SDDownloadRequest *)downloadRequest {
	if((self = [super init]) != nil) {
		self.downloadRequest = downloadRequest;
		_mode = mode;

		[self setToolbarHidden:NO animated:NO];
	} return self;
}

- (void)setDownloadRequest:(SDDownloadRequest *)downloadRequest {
	id old = _downloadRequest;
	_downloadRequest = [downloadRequest retain];
	[old release];
	self.path = _downloadRequest.savePath;
}

- (void)dealloc {
	[_downloadRequest release];
	[_path release];
	[_browserToolbarItems release];
	[super dealloc];
}

- (void)setPath:(NSString *)path {
	[_path release];
	_path = [[path stringByStandardizingPath] copy];
	self.viewControllers = [self _viewControllersForPath:path rootedAt:NSHomeDirectory()];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	NSString *doneButtonTitle = _mode == SDFileBrowserModeImmediateDownload ? SDLocalizedString(@"ACTION_SAVE_AS") : SDLocalizedString(@"ACTION_CHOOSE_DIRECTORY");

	_browserToolbarItems = [[NSArray arrayWithObjects:
		[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(_cancelButtonTapped:)] autorelease],
		[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease],
		[[[UIBarButtonItem alloc] initWithTitle:doneButtonTitle style:UIBarButtonItemStyleDone target:self action:@selector(_doneButtonTapped:)] autorelease],
		nil] retain];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[_browserToolbarItems release];
	_browserToolbarItems = nil;
}

- (NSArray *)_viewControllersForPath:(NSString *)path rootedAt:(NSString *)root {
	NSMutableArray *a = [NSMutableArray array];
	root = [root stringByStandardizingPath];

	int pass = 0;
	do {
		if(pass > 0)
			path = [path stringByDeletingLastPathComponent];

		SDDirectoryListViewController *directoryViewController = [[SDDirectoryListViewController alloc] initWithPath:path];
		[a insertObject:directoryViewController atIndex:0];
		[directoryViewController release];
		pass++;
	} while(![path isEqualToString:root]);

	return a;
}

- (void)_cancelButtonTapped:(id)sender {
	[_fileBrowserDelegate fileBrowserDidCancel:self];
}

- (void)_doneButtonTapped:(id)sender {
	[_fileBrowserDelegate fileBrowser:self didSelectPath:[(SDDirectoryListViewController *)self.topViewController currentPath]];
}

@end
