#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# Prints an error message and exits with an error code of 1
fail () {
    echo "Command failed; script terminated"
    exit 1
}

# Prints usage information concerning this script
print_usage () {
    echo "|
| Usage: ${0} generate|install [args]
|
| --> ${0} generate installed|external <tensorflow-source-dir> [<cmake-dir>]:
|
|     Generates the cmake files for the given installation of tensorflow
|     and writes them to <cmake-dir>
|
| --> ${0} install <tensorflow-source-dir> [<install-dir> <download-dir>]
|
|     Downloads Protobuf to <donload-dir> (defaults to the current directory),
|     and installs it to <instal-dir> (defaults to /usr/local).
|"
}


# validate and assign input
if [ "$#" -lt 2 ]; then
    print_usage
    exit 1
fi
# Determine mode
if [ "${1}" == "install" ]; then
    MODE="install"
elif [ "${1}" == "generate" ]; then
    MODE="generate"
else
    print_usage
    exit 1
fi

# get arguments
if [ "${MODE}" == "install" ]; then
    TF_DIR="${2}"
    INSTALL_DIR="/usr/local"
    DOWNLOAD_DIR="."
    if [ "$#" -gt 2 ]; then
       INSTALL_DIR="${3}"
    fi
    if [ "$#" -gt 3 ]; then
	DOWNLOAD_DIR="${4}"
    fi
elif [ "${MODE}" == "generate" ]; then
    GENERATE_MODE="${2}"
    if [ "${GENERATE_MODE}" != "installed" ] && [ "${GENERATE_MODE}" != "external" ]; then
	print_usage
	exit 1
    fi
    TF_DIR="${3}"
    CMAKE_DIR="."
    if [ "$#" -gt 3 ]; then
	CMAKE_DIR="${4}"
    fi
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
PROTOBUF_TEXT=$(grep -Pzro ${PROTOBUF_REGEX} ${TF_DIR}) || fail

PROTOBUF_COMMIT=$(echo "${PROTOBUF_TEXT}" | sed -n ${COMMIT}) || fail
PROTOBUF_URL=$(echo "${PROTOBUF_TEXT}" | sed -n ${REMOTE}) || fail

if [ -z "${PROTOBUF_URL}" ] || [ -z "${PROTOBUF_COMMIT}" ]; then
    echo "Failure: Could not find all required strings in ${TF_DIR}"
    exit 1
fi

# print information
echo
echo "Protobuf Repository:  ${PROTOBUF_URL}"
echo "Protobuf Commit:      ${PROTOBUF_COMMIT}"
echo

# perform requested action
if [ "${MODE}" == "install" ]; then
    # clone protobuf from its git repository
    cd ${DOWNLOAD_DIR} || fail
    git clone ${PROTOBUF_URL} || fail
    git reset --hard ${PROTOBUF_COMMIT} || fail
    # configure
    cd protobuf || fail
    ./autogen.sh || fail
    ./configure --prefix=${INSTALL_DIR} || fail
    # build and install
    make || fail
    make check || fail
    sudo make install || fail
    sudo ldconfig || fail
    echo "Protobuf has been installed to ${INSTALL_DIR}"
elif [ "${MODE}" == "generate" ]; then
    if [ "${GENERATE_MODE}" == "external" ]; then
	# output protobuf information to file
	PROTOBUF_OUT="${CMAKE_DIR}/Protobuf_VERSION.cmake"
	echo "set(Protobuf_URL ${PROTOBUF_URL})" > ${PROTOBUF_OUT} || fail
	echo "set(Protobuf_COMMIT ${PROTOBUF_COMMIT})" >> ${PROTOBUF_OUT} || fail
	cp ${SCRIPT_DIR}/Protobuf.cmake ${CMAKE_DIR} || fail
	echo "Wrote Protobuf_VERSION.cmake and Protobuf.cmake to ${CMAKE_DIR}"
    elif [ "${GENERATE_MODE}" == "installled" ]; then
	echo "No files to generate (use CMake's built-in FindProtobuf module)"
    fi
fi
echo "Done"
