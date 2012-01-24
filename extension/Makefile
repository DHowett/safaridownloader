ifeq ($(MAKELEVEL),0)
all package install clean::
	@cd ..; make $@
else

TWEAK_NAME=Downloader
Downloader_FILES = BaseCell.m DownloadCell.m DownloadOperation.m FileBrowser.m SafariDownload.m
Downloader_FILES += Downloader.xm DownloadManager.mm ModalAlert.mm SDDownloadActionSheet.mm
Downloader_FILES += AuthenticationView.mm
Downloader_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Downloader_PRIVATE_FRAMEWORKS = WebUI
Downloader_CFLAGS = -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/common -mthumb
Downloader_SUBPROJECTS = ../common
Downloader_LDFLAGS = -mthumb

include ../framework/makefiles/common.mk
include ../framework/makefiles/tweak.mk
endif
