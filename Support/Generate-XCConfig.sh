#!/bin/bash

XCCONFIG_FILE="$1"

[ -z "${XCCONFIG_FILE}" ] && {
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

XCCONFIG="$(cat <<END
LIBXML2_INCLUDE_DIR = ${INCLUDE_DIR}
END
)"

if [ -f "${XCCONFIG_FILE}" ]; then
    EXISTING="$(cat ${XCCONFIG_FILE})"
    if [ "${EXISTING}" = "${XCCONFIG}" ]; then
        echo "${XCCONFIG_FILE} up to date, not changing."
        exit 0
    else
        echo "${XCCONFIG_FILE} out of date, updating."
    fi
else
    echo "${XCCONFIG_FILE} does not exist, creating."
fi

rm -f "${XCCONFIG_FILE}"
echo "${XCCONFIG}" >"${XCCONFIG_FILE}"