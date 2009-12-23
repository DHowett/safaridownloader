TWEAK_NAME=Downloader
Downloader_OBJC_FILES = BaseCell.m DownloadCell.m DownloadOperation.m Resources.m SafariDownload.m
Downloader_OBJCC_FILES = Downloader.mm DownloadManager.mm ModalAlert.mm
Downloader_SUBPROJECTS = preferences
Downloader_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Downloader_PRIVATE_FRAMEWORKS = WebUI
Downloader_CFLAGS = -I$(TOP_DIR) -mthumb
Downloader_LDFLAGS = -Wl,-single_module -Wl,-x -mthumb
STOREPACKAGE=1
export STOREPACKAGE

OFILES=Downloader.o DownloadManager.o DownloadOperation.o SafariDownload.o BaseCell.o DownloadCell.o ModalAlert.o

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk

after-Downloader-package::
	-find _ -iname '*.plist' -print0 | xargs -0 plutil -convert binary1
	$(FAKEROOT) chown -R 0.80 _
