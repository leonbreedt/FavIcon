UNAME = ${shell uname}
SCHEME_MAC = FavIcon-macOS
SCHEME_IOS = FavIcon-iOS
CONFIGURATION = Debug
XCODEBUILD = xcodebuild -configuration ${CONFIGURATION}
SDK_MAC = -scheme ${SCHEME_MAC} -sdk macosx
SDK_IPHONE = -scheme ${SCHEME_IOS} -sdk iphonesimulator -destination "name=iPhone 8"
SDK_PATH_MACOSX = ${shell xcrun --sdk macosx --show-sdk-path}

.PHONY: all test build release clean

all: build
build:
	@${XCODEBUILD} ${SDK_MAC}
	@${XCODEBUILD} ${SDK_IPHONE}

build-spm:
	swift build

test: build
	@${XCODEBUILD} ${SDK_MAC} test
	@${XCODEBUILD} ${SDK_IPHONE} test

release:
	@test -z "${VERSION}" && echo "error: VERSION variable not set" && exit 1
	git tag ${VERSION}
	git push --tags
	pod trunk push FavIcon.podspec

clean:
	@${XCODEBUILD} ${SDK_MAC} clean
	@${XCODEBUILD} ${SDK_IPHONE} clean
