#import <QuartzCore/QuartzCore.h>

#import "SDMCommon.h"
#import "SDDownloadPromptViewController.h"
#import "SDDownloadManager.h"

#import "SDResources.h"
#import "SDFileType.h"

#import "SDNavigationController.h"

@implementation SDDownloadPromptViewController
@synthesize delegate = _delegate;
@synthesize downloadRequest = _downloadRequest;

- (int)panelType { return SDPanelTypeDownloadPrompt; }

- (UIModalPresentationStyle)modalPresentationStyle {
	return SDM$WildCat ? UIModalPresentationFormSheet : UIModalPresentationFullScreen;
}

- (NSString *)title {
	return SDLocalizedString(@"DOWNLOAD_PROMPT_TITLE");
}


- (id)initWithDownloadRequest:(SDDownloadRequest *)downloadRequest delegate:(id)delegate {
	if((self = [super initWithStyle:UITableViewStyleGrouped]) != nil) {
		self.downloadRequest = downloadRequest;
		self.delegate = delegate;

		_supportedActions = [[NSMutableArray alloc] initWithCapacity:3];
		[_supportedActions addObject:[NSNumber numberWithInteger:SDActionTypeDownload]];
		if(_downloadRequest.supportsViewing)
			[_supportedActions addObject:[NSNumber numberWithInteger:SDActionTypeView]];
		[_supportedActions addObject:[NSNumber numberWithInteger:SDActionTypeCancel]];
	} return self;
}

- (void)dealloc {
	[_downloadRequest release];
	[_supportedActions release];
	[super dealloc];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.section == 0 ? 72.f : 44.f;
}

- (int)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch(section) {
		//case 0:
			//return SDLocalizedString(@"FILE");
		case 1:
			return SDLocalizedString(@"SAVE_INTO");
		//case 2:
			//return SDLocalizedString(@"ACTIONS");
	}
	return nil;
}

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return 1;
		case 1:
			return 1;
		case 2:
			return [_supportedActions count];
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *reuseIdentifier = nil;
	UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
	switch(indexPath.section) {
		case 0:
			reuseIdentifier = @"FilenameCell";
			cellStyle = UITableViewCellStyleSubtitle;
			break;
		case 1:
			reuseIdentifier = @"DestinationCell";
			break;
		case 2:
			reuseIdentifier = @"ActionCell";
			break;
	}

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier] ?: [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:reuseIdentifier] autorelease];

	switch(indexPath.section) {
		case 0: {
			SDFileType *fileType = [SDFileType fileTypeForExtension:[_downloadRequest.filename pathExtension] orMIMEType:_downloadRequest.mimeType];
			cell.imageView.image = [SDResources iconForFileType:fileType];
			cell.textLabel.text = _downloadRequest.filename;
			cell.detailTextLabel.text = fileType.name;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			break;
		} case 1:
			cell.imageView.image = [SDResources iconForFolder];
			cell.textLabel.text = @"Downloads";
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case 2:
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			switch(indexPath.row) {
				case 0:
					cell.textLabel.text = SDLocalizedString(@"ACTION_DOWNLOAD");
					break;
				case 1: // If we don't support viewing, we actually fall through to display 'Cancel'.
					if(_downloadRequest.supportsViewing) {
						cell.textLabel.text = SDLocalizedString(@"ACTION_VIEW");
						break;
					}
				case 2:
					cell.textLabel.text = SDLocalizedString(@"ACTION_CANCEL");
					break;
			}
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch(indexPath.section) {
		case 0:
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
		case 1:
			break;
		case 2:
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			[_delegate downloadPrompt:self didCompleteWithAction:(SDActionType)[[_supportedActions objectAtIndex:indexPath.row] integerValue]];
			[(SDNavigationController *)[self navigationController] close];
			break;
	}
}

- (void)dismissWithCancel {
	[_delegate downloadPrompt:self didCompleteWithAction:SDActionTypeNone];
	[(SDNavigationController *)[self navigationController] close];
}

@end
