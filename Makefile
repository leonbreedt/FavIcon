SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
INCLUDE_DIR=$(SDKROOT)/usr/include/libxml2 

all: build
build:
	swift build -Xcc -I$(INCLUDE_DIR)

test: 
	swift test -Xcc -I$(INCLUDE_DIR)

clean:
	swift package clean
