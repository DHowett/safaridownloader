export DEBUG=1
include framework/makefiles/common.mk

export ADDITIONAL_CFLAGS = -include $(THEOS_PROJECT_DIR)/release.h
SUBPROJECTS = extension
ifneq ($(THEOS_TARGET_NAME),iphone_simulator)
	SUBPROJECTS += preferences
endif

export RELEASE.CFLAGS = -DRELEASE

export GO_EASY_ON_ME = 1

include framework/makefiles/aggregate.mk

ifeq ($(findstring RELEASE,$(THEOS_SCHEMA)),)
PACKAGE_BUILDNAME = nonrelease
endif

internal-stage::
	-find _ -iname '*.plist' -print0 | xargs -0 plutil -convert binary1
	-find _ -iname '*.png' -print0 | xargs -0 pincrush -i
	$(FAKEROOT) chown -R 0:80 _
