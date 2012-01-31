#include <objc/runtime.h>

#ifdef __cplusplus
#define _EXTERN extern "C"
#else
#define _EXTERN extern
#endif

// Exported from Downloader*.xm
_EXTERN Class SDM$BrowserController;
_EXTERN Class SDM$SandCastle;

// Exported from AuthenticationView.xm
_EXTERN Class SDM$MyAuthenticationView;

// Exported from Downloader*.xm
_EXTERN bool SDM$WildCat;
