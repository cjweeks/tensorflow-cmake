#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# Exits if user doe not have root priveledges
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

# locate eigen archive in tensorflow directory
ANY="[^\)]*"
ANY_NO_QUOTES="[^\)\\\"]*"
ANY_HEX="[a-fA-F0-9]*"
ARCHIVE_HEADER="native.new_http_archive\(\s*"
NAME_START="name\s*=\s*\\\""
QUOTE_START="\s*=\s*\\\""
QUOTE_END="\\\"\s*,\s*"
FOOTER="\)"
EIGEN_NAME="${NAME_START}eigen_archive${QUOTE_END}"

EIGEN_REGEX="${ARCHIVE_HEADER}${ANY}${EIGEN_NAME}${ANY}${FOOTER}"

URL="s/\s*url${QUOTE_START}\(${ANY_NO_QUOTES}\)${QUOTE_END}/\1/p"
HASH="s/\s*sha256${QUOTE_START}\(${ANY_HEX}\)${QUOTE_END}/\1/p"
ARCHIVE_HASH="s=.*/\(${ANY_HEX}\)\\.tar\\.gz=\1=p"

echo "Finding eigen version in ${TF_DIR}..."
EIGEN_TEXT=$(grep -Pzro ${EIGEN_REGEX} ${TF_DIR})

EIGEN_URL=$(echo "${EIGEN_TEXT}" | sed -n ${URL})
EIGEN_HASH=$(echo "${EIGEN_TEXT}" | sed -n ${HASH})
EIGEN_ARCHIVE_HASH=$(echo "${EIGEN_URL}" | sed -n ${ARCHIVE_HASH})

if [ -z "${EIGEN_URL}" ] || [ -z "${EIGEN_HASH}" ] || [ -z "${EIGEN_ARCHIVE_HASH}" ]; then
    echo "Failure: Could not find all required strings in ${TF_DIR}"
    exit 1
fi

# print information
echo
echo "Eigen URL:           ${EIGEN_URL}"
echo "Eigen URL Hash:      ${EIGEN_HASH}"
echo "Eigen Archive Hash:  ${EIGEN_ARCHIVE_HASH}"
echo

if [ "${MODE}" == "external" ]; then
    # output Eigen information to file
    EIGEN_OUT="${CMAKE_DIR}/eigen_VERSION.cmake"
    echo "set(eigen_URL ${EIGEN_URL})" > ${EIGEN_OUT}
    echo "set(eigen_archive_hash ${EIGEN_ARCHIVE_HASH})" >> ${EIGEN_OUT}
    echo "set(eigen_HASH SHA256=${EIGEN_HASH})" >> ${EIGEN_OUT}
    echo "set(eigen_dir eigen-eigen-${EIGEN_ARCHIVE_HASH})" >> ${EIGEN_OUT}
    cp ${SCRIPT_DIR}/../cmake/eigen.cmake ${CMAKE_DIR}
    echo "Copied eigen_VERSION.cmake and eigen.cmake to ${CMAKE_DIR}"
elif [ "${MODE}" == "install" ]; then
    # copy eigen files to cmake directory
    cp ${SCRIPT_DIR}/FindEigen.cmake ${CMAKE_DIR}
    # donwload eigen and extract to /usr/local/include
    mkdir -p /usr/local/include/eigen
    rm -r /usr/local/include/eigen/*
    cd /usr/local/include/eigen
    wget ${EIGEN_URL}
    tar -zxvf *
    echo
    echo "All Eigen files copied to /usr/local/eigen"
    echo "FindEigen.cmake copied to ${CMAKE_DIR}"
fi

echo "Done"

