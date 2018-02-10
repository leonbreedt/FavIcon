UNAME = ${shell uname}
SCHEME_MAC = FavIcon-macOS
SCHEME_IOS = FavIcon-iOS
CONFIGURATION = Debug
XCPRETTY = xcpretty || tee
XCODEBUILD = xcodebuild -configuration ${CONFIGURATION}
SDK_MAC = -scheme ${SCHEME_MAC} -sdk macosx
SDK_IPHONE = -scheme ${SCHEME_IOS} -sdk iphonesimulator -destination "name=iPhone 6s"

.PHONY: all test build release clean

all: build
build:
	@${XCODEBUILD} ${SDK_MAC} | ${XCPRETTY}
	@${XCODEBUILD} ${SDK_IPHONE} | ${XCPRETTY}

test: build
	@${XCODEBUILD} ${SDK_MAC} test | ${XCPRETTY}
	@${XCODEBUILD} ${SDK_IPHONE} test | ${XCPRETTY}

release:
	@test -z "${VERSION}" && echo "error: VERSION variable not set" && exit 1
	git tag ${VERSION}
	git push --tags
	pod trunk push FavIcon.podspec

clean:
	@${XCODEBUILD} ${SDK_MAC} clean | ${XCPRETTY}
	@${XCODEBUILD} ${SDK_IPHONE} clean | ${XCPRETTY}
