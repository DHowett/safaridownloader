SUBPROJECTS = extension preferences
STOREPACKAGE=1
export GO_EASY_ON_ME = 1
export STOREPACKAGE

include framework/makefiles/common.mk
include framework/makefiles/aggregate.mk

internal-stage::
	-find _ -iname '*.plist' -print0 | xargs -0 plutil -convert binary1
	$(FAKEROOT) chown -R 0:80 _
package-build-deb-buildno:: # miserable hack warning!
	sed -i '' -e "s@%OFFSET%@$(shell ./getoffset.sh ./extension/obj/Downloader.dylib)@g;s@%FILE%@Library/MobileSubstrate/DynamicLibraries/Downloader.dylib@g" $(FW_STAGING_DIR)/DEBIAN/extrainst_
