#!/usr/bin/make -f
PWD:=$(shell pwd)
TOP_DIR:=$(PWD)
FRAMEWORKDIR=$(TOP_DIR)/../framework

TARGET=arm-apple-darwin9
SDKPREFIX=/opt/iphone-sdk-3.0/prefix/bin
PREFIX:=$(SDKPREFIX)/$(TARGET)-

CC=$(PREFIX)gcc
CXX=$(PREFIX)g++
STRIP=$(PREFIX)strip
CODESIGN_ALLOCATE=$(PREFIX)codesign_allocate
export CC CXX STRIP CODESIGN_ALLOCATE

LDFLAGS:=-lobjc -bind_at_load -framework Foundation -framework CoreFoundation \
	-multiply_defined suppress -dynamiclib -Wall \
	-Werror -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors $(LDFLAGS)

STOREPACKAGE=1
export STOREPACKAGE

CFLAGS:=-Os -mthumb $(DEBUG_CFLAGS) -I$(FRAMEWORKDIR)/include
export FRAMEWORKDIR
export CFLAGS

OFILES=main.o

TARGET=Toggle.dylib

all: $(TARGET)

$(TARGET): $(OFILES)
	$(CXX) $(LDFLAGS) -o $@ $^
	$(STRIP) -x $@
	CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@

%.o: %.mm
	$(CXX) -c $(CFLAGS) $< -o $@

%.o: %.m
	$(CXX) -c $(CFLAGS) $< -o $@

clean:
	rm -f $(TARGET) *.o

package-local: $(TARGET)
	cp $(TARGET) _/var/mobile/Library/SBSettings/Toggles/SDM
	chown 0.80 _ -R

include $(FRAMEWORKDIR)/makefiles/DebMakefile
