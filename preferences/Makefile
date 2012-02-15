include ../framework/makefiles/common.mk

BUNDLE_NAME := SDSettings
SDSettings_FILES = SDSettings.mm common/SDFileType.mm common/SDResources.mm common/SDUserSettings.mm

SDSettings_INSTALL_PATH = /System/Library/PreferenceBundles

SDSettings_FRAMEWORKS = UIKit CoreGraphics
SDSettings_PRIVATE_FRAMEWORKS = Preferences

SDSettings_CFLAGS = -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/preferences -mthumb -DSDFILETYPE_MAP_CATEGORIES=1
SDSettings_LDFLAGS = -mthumb

SDSettings_BUNDLE_NAME = SafariDownloaderSettings

include ../framework/makefiles/bundle.mk
