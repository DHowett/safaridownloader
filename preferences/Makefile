firstrule:
	@(cd ..; make)

LDFLAGS=-lobjc -framework Foundation -framework UIKit -framework CoreFoundation -multiply_defined suppress \
	-Wall -Werror -lobjc -ObjC++ -fobjc-exceptions -bundle -fobjc-call-cxx-cdtors \
	-F/opt/iphone-sdk/sys/System/Library/PrivateFrameworks -framework Preferences

all: SDSettings

SDSettings: SDSettings.o
	$(CC) $(LDFLAGS) -o $@ $^ $(FRAMEWORKDIR)/lib/DHLocalizedListController.o
	$(STRIP) -x $@
	CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@

%.o: %.mm
	$(CC) -c $(CFLAGS) $< -o $@

clean:
	rm -f *.o SDSettings
