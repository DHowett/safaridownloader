/*
 * SDDownloadListViewController
 * SDM
 * Dustin Howett 2012-01-30
 */
#import <QuartzCore/QuartzCore.h>
#import "SDMCommon.h"
#import "SDMVersioning.h"
#import "SDDownloadManager.h"
#import "SDDownloadListViewController.h"
#import "SDDownloadCell.h"
#import "SDResources.h"

#import "SDFileType.h"

#import "SDDownloadModel.h"

@interface UIDevice (Wildcat)
- (BOOL)isWildcat;
@end

@interface UIApplication (Safari)
- (void)applicationOpenURL:(id)url;
@end

@interface SDDownloadListViewController ()
- (void)_updateRightButton;
- (SDDownloadCell*)_cellForDownload:(SDSafariDownload*)download;
@end
@implementation SDDownloadListViewController
@synthesize currentSelectedIndexPath = _currentSelectedIndexPath;

#define kSDDownloadListViewControllerCancelAlertTag 1
#define kSDDownloadListViewControllerClearAlertTag 2

#pragma mark -

- (int)panelType {
	return SDPanelTypeDownloadManager;
}

- (UIModalPresentationStyle)modalPresentationStyle {
	return UIModalPresentationFullScreen;
}

- (void)_attachToDownloadManager {
	if(!_dataModel) {
		_dataModel = [[SDDownloadManager sharedManager] dataModel];
		[_dataModel addObserver:self forKeyPath:@"runningDownloads" options:0 context:NULL];
		[_dataModel addObserver:self forKeyPath:@"finishedDownloads" options:0 context:NULL];
	}
	[[SDDownloadManager sharedManager] setDownloadObserver:self];
}

- (void)_detachFromDownloadManager {
	if(_dataModel) {
		[_dataModel removeObserver:self forKeyPath:@"finishedDownloads"];
		[_dataModel removeObserver:self forKeyPath:@"runningDownloads"];
		_dataModel = nil;
	}
	[[SDDownloadManager sharedManager] setDownloadObserver:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
	return SDM$WildCat ? YES : (orientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)dealloc {
	[self _detachFromDownloadManager];
	[_currentSelectedIndexPath release];
	[_doneButton release];
	[_cancelButton release];
	[_clearButton release];

	[super dealloc];
}

- (void)cancelAllDownloads {
	UIAlertView* alert = nil;
	if(_dataModel.runningDownloads.count > 0) {
		alert = [[UIAlertView alloc] initWithTitle:SDLocalizedString(@"CANCEL_ALL_PROMPT")
						   message:nil
						  delegate:self
					 cancelButtonTitle:SDLocalizedString(@"NO")
					 otherButtonTitles:SDLocalizedString(@"YES"), nil];
		alert.tag = kSDDownloadListViewControllerCancelAlertTag;
	} else {
		alert = [[UIAlertView alloc] initWithTitle:SDLocalizedString(@"NOTHING_TO_CANCEL")
						   message:nil
						  delegate:self
					 cancelButtonTitle:SDLocalizedString(@"OK")
					 otherButtonTitles:nil];
	}
	
	[alert show];
	[alert release];
}

- (void)clearAllDownloads {
	UIAlertView *alert = nil;
	if(_dataModel.finishedDownloads.count > 0) {
		alert = [[UIAlertView alloc] initWithTitle:SDLocalizedString(@"CLEAR_ALL_PROMPT")
						   message:nil
						  delegate:self
					 cancelButtonTitle:SDLocalizedString(@"NO")
					 otherButtonTitles:SDLocalizedString(@"YES"), nil];
	} else {
		alert = [[UIAlertView alloc] initWithTitle:SDLocalizedString(@"NOTHING_TO_CLEAR")
						   message:nil
						  delegate:self
					 cancelButtonTitle:SDLocalizedString(@"OK")
					 otherButtonTitles:nil];
	}
	alert.tag = kSDDownloadListViewControllerClearAlertTag;
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(alert.tag == kSDDownloadListViewControllerClearAlertTag) {
		if (buttonIndex == 1) {
			[_dataModel emptyList:SDDownloadModelFinishedList];
		}
	} else {
		if (buttonIndex == 1) {
			[[SDDownloadManager sharedManager] cancelAllDownloads];
		}
	}
}

- (SDDownloadCell*)_cellForDownload:(SDSafariDownload*)download {
	return (SDDownloadCell *)[self.tableView cellForRowAtIndexPath:[_dataModel indexPathForDownload:download]];
}

#pragma mark -/*}}}*/
#pragma mark UIViewController Methods/*{{{*/

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; 
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_cancelButton = [[UIBarButtonItem alloc] initWithTitle:SDLocalizedString(@"CANCEL_ALL_SHORT") style:UIBarButtonItemStylePlain target:self action:@selector(cancelAllDownloads)];
	_clearButton = [[UIBarButtonItem alloc] initWithTitle:SDLocalizedString(@"CLEAR_ALL_SHORT") style:UIBarButtonItemStylePlain target:self action:@selector(clearAllDownloads)];
	
	if(!SDM$WildCat) {
		_doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
									target:[self navigationController]
									action:@selector(close)];
		self.navigationItem.leftBarButtonItem = _doneButton;
		self.navigationItem.leftBarButtonItem.enabled = YES;
	}

	self.tableView.rowHeight = 56;
}

- (void)viewDidUnload {
	[_doneButton release];
	_doneButton = nil;
	[_cancelButton release];
	_cancelButton = nil;
	[_clearButton release];
	_clearButton = nil;

	[super viewDidUnload]; 
}

- (void)updateRunningDownloads:(NSTimer *)timer {
	NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
	for(NSIndexPath *indexPath in indexPaths) {
		if(indexPath.section != 0) continue;
		SDSafariDownload *download = [_dataModel.runningDownloads objectAtIndex:indexPath.row];
		if(download.status != SDDownloadStatusRunning) continue;

		[(SDDownloadCell *)[self.tableView cellForRowAtIndexPath:indexPath] updateProgress];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[self _attachToDownloadManager];
	[self _updateRightButton];
	[super viewWillAppear:animated];
	[self.tableView reloadData];
	_updateTimer = [[NSTimer scheduledTimerWithTimeInterval:.5f target:self selector:@selector(updateRunningDownloads:) userInfo:nil repeats:YES] retain];
}

- (void)viewWillDisappear:(BOOL)animated {
	[_updateTimer invalidate];
	[_updateTimer release];
	_updateTimer = nil;
	[self _detachFromDownloadManager];
	[super viewWillDisappear:animated];
}

- (id)title {
	return SDLocalizedString(@"DOWNLOADS_TITLE");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	NSUInteger section;
	if([keyPath isEqualToString:@"runningDownloads"]) section = 0;
	else section = 1;
	NSIndexSet *indexSet = [change objectForKey:NSKeyValueChangeIndexesKey];
	NSUInteger indices[indexSet.count];
	[indexSet getIndexes:indices maxCount:indexSet.count inIndexRange:nil];
	NSMutableArray *newIndexPaths = [NSMutableArray array];
	for(unsigned int i = 0; i < indexSet.count; i++) {
		[newIndexPaths addObject:[NSIndexPath indexPathForRow:indices[i] inSection:section]];
	}
	switch([[change objectForKey:NSKeyValueChangeKindKey] intValue]) {
		case NSKeyValueChangeInsertion:
			[self.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationFade];
			break;
		case NSKeyValueChangeRemoval:
			[self.tableView deleteRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
	[self _updateRightButton];
}

/* {{{ Download Observer */
- (void)downloadDidChangeStatus:(SDSafariDownload *)download {
	SDDownloadCell *cell = [self _cellForDownload:download];
	if(!cell) return;
	[cell updateDisplay];
}

- (void)downloadDidUpdateMetadata:(SDSafariDownload *)download {
	SDDownloadCell *cell = [self _cellForDownload:download];
	if(!cell) return;
	[cell updateDisplay];
}
/* }}} */

- (void)_updateRightButton {
	if(_dataModel.runningDownloads.count > 0) {
		[self.navigationItem setRightBarButtonItem:_cancelButton animated:YES];
	} else {
		if(_dataModel.finishedDownloads.count > 0) {
			[self.navigationItem setRightBarButtonItem:_clearButton animated:YES];
		} else {
			[self.navigationItem setRightBarButtonItem:nil animated:YES];
		}
	}
}

#pragma mark -/*}}}*/
#pragma mark UITableView methods/*{{{*/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0.f;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (tableView.numberOfSections == 2 && section == 0)
		return _dataModel.runningDownloads.count;
	else
		return _dataModel.finishedDownloads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"SDDownloadCell";
	BOOL finished = NO;
	SDSafariDownload *download = nil;
	
	if(tableView.numberOfSections == 2 && indexPath.section == 0) {
		download = [_dataModel.runningDownloads objectAtIndex:indexPath.row];
		finished = NO;
	} else {
		CellIdentifier = @"FinishedSDDownloadCell";
		download = [_dataModel.finishedDownloads objectAtIndex:indexPath.row];
		finished = YES;
	}
	
	SDDownloadCell *cell = (SDDownloadCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[SDDownloadCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
	}
	
	cell.download = download;

	if(!finished) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	} else {
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}

	[cell updateDisplay];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0) return 68;
	else return 56;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}
	self.currentSelectedIndexPath = indexPath;
	if(indexPath.section == 1) {
		id download = [_dataModel.finishedDownloads objectAtIndex:indexPath.row];
		id launch = [[SDDownloadActionSheet alloc] initWithDownload:download delegate:self];
		[launch showInView:self.view];
		[launch release];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (NSString *)tableView:(UITableView *)tableView 
titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0)
		return SDLocalizedString(@"CANCEL");
	else // local files
		return SDLocalizedString(@"CLEAR");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		if(indexPath.section == 0) {
			id download = [_dataModel.runningDownloads objectAtIndex:indexPath.row];
			[[SDDownloadManager sharedManager] cancelDownload:download];
		} else {
			[_dataModel removeDownload:[_dataModel.finishedDownloads objectAtIndex:indexPath.row] fromList:SDDownloadModelFinishedList];
		}
	}
}
/*}}}*/

- (void)downloadActionSheet:(SDDownloadActionSheet *)actionSheet retryDownload:(SDSafariDownload *)download {
	[[SDDownloadManager sharedManager] retryDownload:download];
}

- (void)downloadActionSheet:(SDDownloadActionSheet *)actionSheet deleteDownload:(SDSafariDownload *)download {
	[[SDDownloadManager sharedManager] deleteDownload:download];
}

- (void)downloadActionSheetWillDismiss:(SDDownloadActionSheet *)actionSheet {
	[(UITableView *)self.view deselectRowAtIndexPath:self.currentSelectedIndexPath animated:YES];
	self.currentSelectedIndexPath = nil;
}
@end

// vim:filetype=objc:ts=8:sw=8:noexpandtab
