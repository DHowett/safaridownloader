SUBPROJECTS = extension preferences
STOREPACKAGE=1
export GO_EASY_ON_ME = 1
export STOREPACKAGE

include framework/makefiles/common.mk
include framework/makefiles/aggregate.mk

internal-package::
	-find _ -iname '*.plist' -print0 | xargs -0 plutil -convert binary1
	$(FAKEROOT) chown -R 0.80 _
