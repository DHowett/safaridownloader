#include <objc/runtime.h>

#ifdef __cplusplus
#define _EXTERN extern "C"
#else
#define _EXTERN extern
#endif

// Exported from Downloader*.xm
_EXTERN Class SDM$BrowserController;
_EXTERN Class SDM$SandCastle;

// Exported from Downloader*.xm
_EXTERN bool SDM$WildCat;

// Exported from SDDownloadManager.mm
_EXTERN NSString * const kSDMAssociatedOverrideAuthenticationChallenge;

// Exported from _CustomToolbar_Old.xm
_EXTERN NSString * const kSDMAssociatedPortraitDownloadButton;
_EXTERN NSString * const kSDMAssociatedActionButton;
_EXTERN NSString * const kSDMAssociatedBookmarksButton;

typedef enum {
	SDPanelTypeDownloadManager = 150,
	SDPanelTypeDownloadPrompt = 151,
	SDPanelTypeFileBrowser = 152
} SDPanelTypes;

typedef enum
{
	SDActionTypeNone = 0,
	SDActionTypeView = 1,
	SDActionTypeDownload = 2,
	SDActionTypeCancel = 3,
	SDActionTypeDownloadAs = 4,
} SDActionType;
