ifeq ($(MAKELEVEL),0)
all package install clean sim::
	@cd ..; make $@
else


TWEAK_NAME=Downloader
Downloader_FILES  = BaseCell.m DownloadCell.m DownloadOperation.m FileBrowser.m SafariDownload.m

Downloader_FILES += Downloader.xm _WebPolicyDelegateHooks.xm _BrowserPanelHooks.xm
Downloader_FILES += _CustomToolbar_Old.xm _Interaction_iOS3.xm
Downloader_FILES += _CustomToolbar_iOS5.xm _Interaction_iOS5.xm

Downloader_FILES += SDDownloadManager.mm ModalAlert.mm SDDownloadActionSheet.mm
Downloader_FILES += SDDownloadManagerNavigationController.mm
Downloader_FILES += SDDownloadPromptView.mm SDRoundedButton.mm SDDownloadRequest.mm
Downloader_FILES += AuthenticationView.mm
Downloader_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Downloader_PRIVATE_FRAMEWORKS = WebUI WebKit
Downloader_CFLAGS = -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/common -mthumb
Downloader_SUBPROJECTS = ../common
Downloader_LDFLAGS = -mthumb

include ../framework/makefiles/common.mk
include ../framework/makefiles/tweak.mk
endif
