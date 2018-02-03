#!/bin/bash

MODULEMAP_FILE="$1"

[ -z "${MODULEMAP_FILE}" ] && {
    echo "usage: $0 OUTPUT-FILE" >&2
    exit 1
}

XCODE_PLATFORM_DIR="/Applications/Xcode.app/Contents/Developer/Platforms"
CANDIDATE_DIRS="${SDKROOT} / ${XCODE_PLATFORM_DIR}/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk ${XCODE_PLATFORM_DIR}/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

INCLUDE_DIR=""
for dir in ${CANDIDATE_DIRS}; do
    if [ ${dir} != "/" ]; then
        test_dir="${dir}/usr/include/libxml2"
    else
        test_dir="${dir}usr/include/libxml2"
    fi
    if [ -f "${test_dir}/libxml/tree.h" ]; then
        INCLUDE_DIR="${test_dir}"
        break
    fi
done

[ -z "${INCLUDE_DIR}" ] && {
    echo "error: unable to locate a usable libxml2. either install a recent Xcode, or the command-line tools, and try again." >&2
    exit 1
}

cat >"${MODULEMAP_FILE}" <<EOF
module Clibxml2 [system] {
  header "${INCLUDE_DIR}/libxml/tree.h"
  header "${INCLUDE_DIR}/libxml/HTMLparser.h"
  header "${INCLUDE_DIR}/libxml/xpath.h"
  header "${INCLUDE_DIR}/libxml/xpathInternals.h"
  link "xml2"
  export *
}
EOF