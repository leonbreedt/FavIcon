UNAME = ${shell uname}
SCHEME = FavIcon-macOS
CONFIGURATION = Debug
XCPRETTY = xcpretty || tee
XCODEBUILD = xcodebuild -scheme ${SCHEME} -configuration ${CONFIGURATION}

.PHONY: all test build clean

all: build
build:
	@${XCODEBUILD} | ${XCPRETTY}

test: build
	@${XCODEBUILD} test | ${XCPRETTY}

clean:
	@${XCODEBUILD} clean | ${XCPRETTY}
