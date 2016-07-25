#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# Exits if user has  root priveledges and exits if not
check_root () {
    if [ "${EUID}" -ne 0 ]; then
	echo "Please run as root to install."
	exit 1
    fi
}

# Prints usage information concerning this script
print_usage () {
    echo "Usage: ${0} external|install <tensorflow-source-dir> [cmake-dir]"
}

# validate and assign input
if [ "$#" -lt 2 ]; then
    print_usage
    exit 1
fi
# Determine mode
if [ "${1}" == "install" ]; then
    check_root
    MODE="install"
elif [ "${1}" == "external" ]; then
    MODE="external"
else
    print_usage
    exit 1
fi
# get arguments
TF_DIR="${2}"
CMAKE_DIR="."
if [ "$#" -gt 2 ]; then
    CMAKE_DIR="${3}"
fi

# locate protobuf information in tensorflow directory
ANY="[^\)]*"
ANY_NO_QUOTES="[^\)\\\"]*"
ANY_HEX="[a-fA-F0-9]*"
GIT_HEADER="native.git_repository\(\s*"
NAME_START="name\s*=\s*\\\""
QUOTE_START="\s*=\s*\\\""
QUOTE_END="\\\"\s*,\s*"
FOOTER="\)"
PROTOBUF_NAME="${NAME_START}protobuf${QUOTE_END}"

PROTOBUF_REGEX="${GIT_HEADER}${ANY}${PROTOBUF_NAME}${ANY}${FOOTER}"

COMMIT="s/\s*commit${QUOTE_START}\(${ANY_HEX}\)${QUOTE_END}/\1/p"
REMOTE="s/\s*remote${QUOTE_START}\(${ANY_NO_QUOTES}\)${QUOTE_END}/\1/p"

echo "Finding protobuf information in ${TF_DIR}..."
PROTOBUF_TEXT=$(grep -Pzro ${PROTOBUF_REGEX} ${TF_DIR})

PROTOBUF_COMMIT=$(echo "${PROTOBUF_TEXT}" | sed -n ${COMMIT})
PROTOBUF_URL=$(echo "${PROTOBUF_TEXT}" | sed -n ${REMOTE})

if [ -z "${PROTOBUF_URL}" ] || [ -z "${PROTOBUF_COMMIT}" ]; then
    echo "Failure: Could not find all required strings in ${TF_DIR}"
    exit 1
fi

# print information
echo
echo "Protobuf Repo:       ${PROTOBUF_URL}"
echo "Protobuf Commit:     ${PROTOBUF_COMMIT}"
echo

if [ "${MODE}" == "external" ]; then
    # output protobuf information to file
    PROTOBUF_OUT="${CMAKE_DIR}/protobuf_VERSION.cmake"
    echo "set(protobuf_URL ${PROTOBUF_URL})" > ${PROTOBUF_OUT}
    echo "set(protobuf_COMMIT ${PROTOBUF_COMMIT})" >> ${PROTOBUF_OUT}
    cp ${SCRIPT_DIR}/protobuf.cmake ${CMAKE_DIR}
    echo "Wrote protobuf_VERSION.cmake and protobuf.cmake to ${CMAKE_DIR}"
elif [ "${MODE}" == "install" ]; then
    # clone protobuf from its git repository
    git clone ${PROTOBUF_URL}
    git reset --hard ${GIT_COMMIT}
    cd protobuf
    ./autogen.sh
    ./configure
    make
    make check
    sudo make install
    sudo ldconfig
    echo "Protobuf has been installed to /usr/local"
fi

echo "Done"
