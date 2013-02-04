include $(THEOS)/makefiles/common.mk
SUBPROJECT_NAME = common filetypes
common_FILES = SDResources.mm SDFileType.mm SDUserSettings.mm
filetypes_FILES = $(common_FILES)
filetypes_CFLAGS = -DSDFILETYPE_MAP_CATEGORIES=1 -DSDFILETYPE_NO_CUSTOM=1
include $(THEOS_MAKE_PATH)/subproject.mk
