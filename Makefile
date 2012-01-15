export ADDITIONAL_CFLAGS = -include $(THEOS_PROJECT_DIR)/release.h
ifeq ($(RELEASE),1)
	export ADDITIONAL_CFLAGS += -DRELEASE
endif
SUBPROJECTS = extension preferences
STOREPACKAGE=1
export RELEASE.CFLAGS = -DRELEASE

export GO_EASY_ON_ME = 1

include framework/makefiles/common.mk
include framework/makefiles/aggregate.mk

ifeq ($(findstring RELEASE,$(THEOS_SCHEMA)),)
PACKAGE_BUILDNAME = nonrelease
endif

internal-stage::
	-find _ -iname '*.plist' -print0 | xargs -0 plutil -convert binary1
	-find _ -iname '*.png' -print0 | xargs -0 pincrush -i
	$(FAKEROOT) chown -R 0:80 _
