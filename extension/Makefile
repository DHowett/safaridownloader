ifeq ($(MAKELEVEL),0)
all package install clean sim::
	@cd ..; make $@
else


TWEAK_NAME = Downloader
Downloader_FILES  = SDDownloadCell.mm FileBrowser.m
Downloader_FILES += SDConcurrentOperation.mm SDSafariDownload.mm
Downloader_FILES += SDUtils.mm

Downloader_FILES += Downloader.xm _WebPolicyDelegateHooks.xm _BrowserPanelHooks.xm
Downloader_FILES += _CustomToolbar_Old.xm _Interaction_iOS3.xm
Downloader_FILES += _CustomToolbar_iOS5.xm _Interaction_iOS5.xm

Downloader_FILES += SDDownloadManager.mm ModalAlert.mm SDDownloadActionSheet.mm
Downloader_FILES += SDDownloadModel.mm
Downloader_FILES += SDNavigationController.mm
Downloader_FILES += SDDownloadListViewController.mm
Downloader_FILES += SDDownloadPromptViewController.mm
Downloader_FILES += SDDownloadRequest.mm
Downloader_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Downloader_PRIVATE_FRAMEWORKS = WebUI WebKit
Downloader_CFLAGS = -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/common -mthumb
Downloader_SUBPROJECTS = ../common
Downloader_LDFLAGS = -mthumb -weak-lSystem

include ../framework/makefiles/common.mk
include ../framework/makefiles/tweak.mk
endif
