UNAME = ${shell uname}
SCHEME_MAC = FavIcon-macOS
SCHEME_IOS = FavIcon-iOS
CONFIGURATION = Debug
XCPRETTY = xcpretty || tee
XCODEBUILD = xcodebuild -configuration ${CONFIGURATION}
SDK_MAC =  -scheme ${SCHEME_MAC} -sdk macosx
SDK_IPHONE = -scheme ${SCHEME_IOS} -sdk iphonesimulator -destination "name=iPhone 6s"

.PHONY: all test build clean

all: build
build:
	@${XCODEBUILD} | ${XCPRETTY}

test: build
	@${XCODEBUILD} ${SDK_MAC} test | ${XCPRETTY}
	@${XCODEBUILD} ${SDK_IPHONE} test | ${XCPRETTY}

clean:
	@${XCODEBUILD} clean | ${XCPRETTY}
