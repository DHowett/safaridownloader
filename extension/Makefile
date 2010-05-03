TWEAK_NAME=Downloader
Downloader_OBJC_FILES = BaseCell.m DownloadCell.m DownloadOperation.m FileBrowser.m Resources.m SafariDownload.m
Downloader_OBJCC_FILES = Downloader.mm DownloadManager.mm ModalAlert.mm
Downloader_FRAMEWORKS = UIKit CoreGraphics QuartzCore
Downloader_PRIVATE_FRAMEWORKS = WebUI
Downloader_CFLAGS = -I$(FW_PROJECT_DIR) -mthumb
Downloader_LDFLAGS = -Wl,-single_module -Wl,-x -mthumb

include ../framework/makefiles/common.mk
include ../framework/makefiles/tweak.mk
