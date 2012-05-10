#define SUPPORT_BUNDLE_PATH @"/Library/Application Support/Safari Downloader"
#define PREFERENCES_FILE @"/var/mobile/Library/Preferences/net.howett.safaridownloader.plist"

typedef enum {
	SDPanelTypeDownloadManager = 150,
	SDPanelTypeAuthentication = 151,
	SDPanelTypeDownloadPrompt = 152
} SDPanelTypes;

typedef enum
{
	SDActionTypeNone = 0,
	SDActionTypeView = 1,
	SDActionTypeDownload = 2,
	SDActionTypeCancel = 3,
	SDActionTypeDownloadAs = 4,
} SDActionType;
