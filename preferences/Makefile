include ../framework/makefiles/common.mk

BUNDLE_NAME := SDSettings
SDSettings_FILES = SDSettings.mm
SDSettings_SUBPROJECTS = ../common:filetypes

SDSettings_INSTALL_PATH = /Library/PreferenceBundles

SDSettings_FRAMEWORKS = UIKit CoreGraphics
SDSettings_PRIVATE_FRAMEWORKS = Preferences

SDSettings_CFLAGS = -I$(THEOS_PROJECT_DIR) -I$(THEOS_PROJECT_DIR)/preferences -mthumb -DSDFILETYPE_MAP_CATEGORIES=1 -DSDFILETYPE_NO_CUSTOM=1 -DBUNDLE_PATH="@\"$(SDSettings_INSTALL_PATH)/$(SDSettings_BUNDLE_NAME).bundle\""
SDSettings_LDFLAGS = -mthumb

SDSettings_BUNDLE_NAME = SafariDownloaderSettings

include ../framework/makefiles/bundle.mk
