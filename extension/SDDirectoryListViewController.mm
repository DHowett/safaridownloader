#import <QuartzCore/QuartzCore.h>

#import "SDMCommon.h"
#import "SDDirectoryListViewController.h"
#import "SDDownloadManager.h"

#import "SDResources.h"
#import "SDFileType.h"

#import "SDNavigationController.h"
#import "SDFileBrowserNavigationController.h"

#import "SandCastle/SandCastle.h"

@interface UIAlertView (TextField)
- (int)addTextFieldWithValue:(NSString *)value label:(NSString *)label;
@end

@interface _SDFileEntry: NSObject {
	BOOL _isDir;
	NSString *_path;
	NSString *_name;
}
@property (nonatomic, assign) BOOL isDir;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *name;
+ (_SDFileEntry *)fileEntryWithName:(NSString *)name atPath:(NSString *)path;
- (id)initWithName:(NSString *)name atPath:(NSString *)path;
@end

@implementation _SDFileEntry
@synthesize isDir = _isDir, name = _name, path = _path;
+ (_SDFileEntry *)fileEntryWithName:(NSString *)name atPath:(NSString *)path {
	_SDFileEntry *temp = [[self alloc] initWithName:name atPath:path];
	return [temp autorelease];
}

- (id)initWithName:(NSString *)name atPath:(NSString *)path {
	if((self = [super init]) != nil) {
		self.path = path;
		self.name = name;
		self.isDir = [[SDM$SandCastle sharedInstance] pathIsDir:[path stringByAppendingPathComponent:name]];
	} return self;
}

- (void)dealloc {
	[_name release];
	[super dealloc];
}

static NSComparisonResult _fileEntryComparator(id one, id two, void *context) {
	_SDFileEntry *o = (_SDFileEntry *)one;
	_SDFileEntry *t = (_SDFileEntry *)two;
	if(o.isDir && !t.isDir) {
		return NSOrderedAscending;
	} else if(t.isDir && !o.isDir) {
		return NSOrderedDescending;
	} else {
		return [o.name compare:t.name];
	}
}
@end

@implementation SDDirectoryListViewController
@synthesize currentPath = _currentPath;
- (NSString *)title {
	return [self.currentPath lastPathComponent];
}

- (NSArray *)toolbarItems {
	return [(SDFileBrowserNavigationController *)[self navigationController] browserToolbarItems];
}

- (id)initWithPath:(NSString *)path {
	if((self = [super initWithStyle:UITableViewStylePlain]) != nil) {
		self.currentPath = path;
	} return self;
}

- (void)dealloc {
	[_currentPath release];
	[_fileList release];
	[super dealloc];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self reloadData];

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(_newDirectoryButtonTapped:)] autorelease];
}

- (void)reloadData {
	NSArray *fileList = [[SDM$SandCastle sharedInstance] directoryContentsAtPath:self.currentPath];
	NSMutableArray *entries = [NSMutableArray arrayWithCapacity:fileList.count];
	for(NSString *file in fileList) {
		if([file hasPrefix:@"."]) continue;
		[entries addObject:[_SDFileEntry fileEntryWithName:file atPath:_currentPath]];
	}
	_fileList = [[entries sortedArrayUsingFunction:&_fileEntryComparator context:NULL] retain];
	[self.tableView reloadData];
}

- (void)viewWillUnload {
	[super viewWillUnload];
	[_fileList release];
	_fileList = nil;
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _fileList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *reuseIdentifier = @"FileCell";
	UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier] ?: [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:reuseIdentifier] autorelease];

	_SDFileEntry *fileEntry = [_fileList objectAtIndex:indexPath.row];
	NSString *filename = fileEntry.name;

	cell.textLabel.text = filename;
	if(fileEntry.isDir) {
		cell.imageView.image = [SDResources iconForFolder];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else {
		SDFileType *fileType = [SDFileType fileTypeForExtension:[filename pathExtension] orMIMEType:nil];
		cell.imageView.image = [SDResources iconForFileType:fileType];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	_SDFileEntry *fileEntry = [_fileList objectAtIndex:indexPath.row];
	if(fileEntry.isDir) {
		cell.textLabel.textColor = [UIColor blackColor];
	} else {
		cell.textLabel.textColor = [UIColor lightGrayColor];
	}

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	_SDFileEntry *fileEntry = [_fileList objectAtIndex:indexPath.row];
	if(!fileEntry.isDir) return;
	SDDirectoryListViewController *newDirectoryViewController = [[[SDDirectoryListViewController alloc] initWithPath:[fileEntry.path stringByAppendingPathComponent:fileEntry.name]] autorelease];
	[self.navigationController pushViewController:newDirectoryViewController animated:YES];
}

- (void)_newDirectoryButtonTapped:(id)sender {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:SDLocalizedString(@"NEW_DIRECTORY_TITLE") message:nil delegate:self cancelButtonTitle:SDLocalizedString(@"CANCEL") otherButtonTitles:SDLocalizedString(@"ACTION_CREATE_DIRECTORY"), nil];
	[alertView addTextFieldWithValue:nil label:SDLocalizedString(@"NEW_DIRECTORY_NAME_PLACEHOLDER")];
	[alertView show];
	[alertView release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
	if(index == alertView.cancelButtonIndex) return;
	NSString *directoryName = [[alertView textFieldAtIndex:0] text];

	if(directoryName.length <= 0) return;
	NSString *newPath = [self.currentPath stringByAppendingPathComponent:directoryName];
	[[SDM$SandCastle sharedInstance] createDirectoryAtResolvedPath:newPath];
	[self reloadData];

	SDDirectoryListViewController *newDirectoryViewController = [[[SDDirectoryListViewController alloc] initWithPath:newPath] autorelease];
	[self.navigationController pushViewController:newDirectoryViewController animated:YES];
}

@end
