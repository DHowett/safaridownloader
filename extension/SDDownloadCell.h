@class SDSafariDownload;
@interface SDDownloadCell: UITableViewCell {
	SDSafariDownload *_download;
	UIProgressView *_progressView;
	UILabel *_nameLabel;
	UILabel *_statusLabel;
	UILabel *_sizeLabel;
	UILabel *_progressLabel;
	UIImageView *_iconImageView;
}
@property (nonatomic, retain) SDSafariDownload *download;
- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
- (void)updateDisplay;
- (void)updateProgress;
@end

