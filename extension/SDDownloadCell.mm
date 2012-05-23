#import "SDDownloadCell.h"
#import "SDSafariDownload.h"
#import "SDResources.h"
#import "SDFileType.h"
#import "SDUtils.h"

@interface SDDownloadCell ()
- (void)_updateLabelColors;
@end

@implementation SDDownloadCell
@synthesize download = _download;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	if((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier]) != nil) {
		_nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_nameLabel.font = [UIFont boldSystemFontOfSize:14.f];

		_statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_statusLabel.font = [UIFont boldSystemFontOfSize:13.f];

		_sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_sizeLabel.font = [UIFont systemFontOfSize:12.f];

		_progressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_progressLabel.font = [UIFont systemFontOfSize:12.f];

		_progressView = [[UIProgressView alloc] initWithFrame:CGRectZero];
		_iconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];

		[self.contentView addSubview:_nameLabel];
		[self.contentView addSubview:_statusLabel];
		[self.contentView addSubview:_sizeLabel];
		[self.contentView addSubview:_progressLabel];
		[self.contentView addSubview:_progressView];
		[self.contentView addSubview:_iconImageView];
	} return self;
}

- (void)dealloc {
	[_nameLabel release];
	[_statusLabel release];
	[_sizeLabel release];
	[_progressLabel release];
	[_progressView release];
	[_iconImageView release];
	[super dealloc];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	[self _updateLabelColors];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	[super setHighlighted:highlighted animated:animated];
	[self _updateLabelColors];
}

- (void)_updateLabelColors {
	if((self.selected || self.highlighted) && self.selectionStyle != UITableViewCellSelectionStyleNone) {
		_nameLabel.textColor = [UIColor whiteColor];
		_statusLabel.textColor = [UIColor whiteColor];
		_sizeLabel.textColor = [UIColor whiteColor];
		_progressLabel.textColor = [UIColor whiteColor];
	} else {
		_nameLabel.textColor = [UIColor blackColor];
		if(_download && (_download.status == SDDownloadStatusFailed || _download.status == SDDownloadStatusRetrying)) {
			_statusLabel.textColor = [UIColor colorWithRed:0.78f green:0.0f blue:0.0f alpha:1.0f];
		} else {
			_statusLabel.textColor = [UIColor grayColor];
		}
		_sizeLabel.textColor = [UIColor grayColor];
		_progressLabel.textColor = [UIColor grayColor];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self _updateLabelColors];

	CGRect bounds = CGRectInset(self.contentView.bounds, 6.f, 6.f);

	[_nameLabel sizeToFit];
	[_statusLabel sizeToFit];
	[_sizeLabel sizeToFit];
	[_progressLabel sizeToFit];

	CGSize iconSize = _iconImageView.image.size;
	CGRect iconFrame = (CGRect){bounds.origin, iconSize};
	_iconImageView.frame = iconFrame;
	CGFloat bottomOfImage = bounds.origin.x + iconSize.height;
	CGSize filenameSize = _nameLabel.frame.size;
	CGPoint nameOffset = {CGRectGetMaxX(iconFrame) + 4, (bounds.origin.y + floorf((iconSize.height-filenameSize.height)/2.f))};
	CGRect nameFrame = (CGRect){nameOffset, {bounds.size.width-(nameOffset.x-bounds.origin.x), filenameSize.height}};
	CGFloat statusLineY = MAX(bottomOfImage, CGRectGetMaxY(nameFrame)) + 2.f;
	if(_download.status != SDDownloadStatusCompleted) {
		_progressLabel.hidden = NO;
		CGSize progressSize = _progressLabel.frame.size;
		_progressLabel.frame = (CGRect){{bounds.origin.y + bounds.size.width - progressSize.width, MAX(bottomOfImage, CGRectGetMaxY(nameFrame)) - progressSize.height}, progressSize};
		nameFrame.size.width -= (progressSize.width + 2.f);

		_progressView.hidden = NO;
		_progressView.frame = (CGRect){{bounds.origin.x, statusLineY}, {bounds.size.width, 20.f}};
		statusLineY = CGRectGetMaxY(_progressView.frame) + 2.f;
	} else {
		_progressLabel.hidden = YES;
		_progressView.hidden = YES;
	}

	// We do this here so the progressLabel can take its chunk before we min on the filename size.
	nameFrame.size.width = MIN(nameFrame.size.width, filenameSize.width);
	_nameLabel.frame = nameFrame;

	CGSize sizeSize = _sizeLabel.frame.size;
	_sizeLabel.frame = (CGRect){{CGRectGetMaxX(bounds) - sizeSize.width, statusLineY}, sizeSize};
	CGSize statusSize = _statusLabel.frame.size;
	_statusLabel.frame = (CGRect){{bounds.origin.y, statusLineY}, {MIN(statusSize.width, bounds.size.width - sizeSize.width - 4.f), statusSize.height}};
}

- (void)setDownload:(SDSafariDownload *)download {
	[download retain];
	[_download release];
	_download = download;
	[self updateDisplay];
}

- (void)updateDisplay {
	_nameLabel.text = _download.filename;
	_sizeLabel.text = [SDUtils formatSize:_download.totalBytes];
	_iconImageView.image = [SDResources iconForFileType:[SDFileType fileTypeForExtension:[_download.filename pathExtension] orMIMEType:_download.mimeType]];

	[self _updateLabelColors];
	switch(_download.status) {
		case SDDownloadStatusRetrying:
			_statusLabel.text = SDLocalizedString(@"Retrying...");
			break;
		case SDDownloadStatusFailed:
			_statusLabel.text = SDLocalizedString(@"Failed");
			break;
		case SDDownloadStatusCompleted:
			_statusLabel.text = [_download.path stringByAbbreviatingWithTildeInPath];
			break;
		case SDDownloadStatusCancelled:
			_statusLabel.text = SDLocalizedString(@"Cancelled");
			break;
		case SDDownloadStatusRunning:
			break;
		default:
			_statusLabel.text = SDLocalizedString(@"Waiting...");
			break;
	}

	[self updateProgress];
	[self setNeedsLayout];
}

- (void)updateProgress {
	float speed = ((double)_download.downloadedBytes - (double)_download.startedFromByte) / (-1*[_download.startDate timeIntervalSinceNow]);
	if(_download.totalBytes == 0) {
		_progressView.progress = 0.;
	} else {
		_progressView.progress = (double)_download.downloadedBytes / (double)_download.totalBytes;
	}
	_progressLabel.text = [NSString stringWithFormat:@"%u%%", (unsigned int)(_progressView.progress*100.f)];
	if(_download.status != SDDownloadStatusCompleted
	   && _download.status != SDDownloadStatusFailed
	   && _download.status != SDDownloadStatusRetrying) {
		_statusLabel.text = [NSString stringWithFormat:SDLocalizedString(@"Downloading @ %@/s"), [SDUtils formatSize:speed]];
		[self setNeedsLayout];
	}
}
@end

// vim:filetype=objc:ts=8:sw=8:noexpandtab
