include ../framework/makefiles/common.mk

SUBPROJECTS = preferences

include ../framework/makefiles/aggregate.mk

ifeq ($(findstring RELEASE,$(THEOS_SCHEMA)),)
PACKAGE_BUILDNAME = private
endif

internal-stage::
	$(FAKEROOT) chown -R 0:80 _
