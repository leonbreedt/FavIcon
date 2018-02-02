UNAME = ${shell uname}

ifeq ($(UNAME), Darwin)
TEST_RESOURCES_DIRECTORY = ./.build/debug/FavIconPackageTests.xctest/Contents/Resources
else ifeq ($(UNAME), Linux)
TEST_RESOURCES_DIRECTORY = ./.build/debug
endif

SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
INCLUDE_DIR=$(SDKROOT)/usr/include/libxml2 

all: build
build:
	swift build -Xcc -I$(INCLUDE_DIR)

test: build
	mkdir -p $(TEST_RESOURCES_DIRECTORY)
	cp -f Tests/FavIconTests/*.{xml,json,html} $(TEST_RESOURCES_DIRECTORY)
	swift test -Xcc -I$(INCLUDE_DIR)

clean:
	swift package clean
