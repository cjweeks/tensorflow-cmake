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
|     Downloads Eigen to <donload-dir> (defaults to the current directory),
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

echo "Finding Eigen version in ${TF_DIR}..."
EIGEN_TEXT=$(grep -Pzro ${EIGEN_REGEX} ${TF_DIR}) || fail

EIGEN_URL=$(echo "${EIGEN_TEXT}" | sed -n ${URL}) || fail
EIGEN_HASH=$(echo "${EIGEN_TEXT}" | sed -n ${HASH}) || fail
EIGEN_ARCHIVE_HASH=$(echo "${EIGEN_URL}" | sed -n ${ARCHIVE_HASH}) || fail

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

# perform requested action
if [ "${MODE}" == "install" ]; then
    # donwload eigen and extract to download directory
    echo "Downlaoding Eigen to ${DOWNLOAD_DIR}"
    cd ${DOWNLOAD_DIR} || fail
    rm -rf eigen-eigen-${EIGEN_ARCHIVE_HASH} || fail
    rm -f ${EIGEN_ARCHIVE_HASH}.tar.gz* || fail
    wget ${EIGEN_URL} || fail
    tar -zxvf ${EIGEN_ARCHIVE_HASH}.tar.gz || fail
    cd eigen-eigen-${EIGEN_ARCHIVE_HASH} || fail
    # create build directory and build
    mkdir build || fail
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DINCLUDE_INSTALL_DIR=include/eigen-eigen-${EIGEN_ARCHIVE_HASH} .. || fail
    make || fail
    make install || fail
    echo "Installation complete"
    echo "Cleaning up..."
    # clean up
    cd ../..
    rm -rf eigen-eigen-${EIGEN_ARCHIVE_HASH} || fail
    rm -f ${EIGEN_ARCHIVE_HASH}.tar.gz* || fail
elif [ "${MODE}" == "generate" ]; then
    # output Eigen information to file
    EIGEN_OUT="${CMAKE_DIR}/Eigen_VERSION.cmake"
    echo "set(Eigen_URL ${EIGEN_URL})" > ${EIGEN_OUT} || fail
    echo "set(Eigen_ARCHIVE_HASH ${EIGEN_ARCHIVE_HASH})" >> ${EIGEN_OUT} || fail
    echo "set(Eigen_HASH SHA256=${EIGEN_HASH})" >> ${EIGEN_OUT} || fail
    echo "set(Eigen_DIR eigen-eigen-${EIGEN_ARCHIVE_HASH})" >> ${EIGEN_OUT} || fail
    echo "Eigen_VERSION.cmake written to ${CMAKE_DIR}"
    # perform specific operations regarding installation
    if [ "${GENERATE_MODE}" == "external" ]; then
	cp ${SCRIPT_DIR}/Eigen.cmake ${CMAKE_DIR} || fail
	echo "Wrote Eigen_VERSION.cmake and Eigen.cmake to ${CMAKE_DIR}"
    elif [ "${GENERATE_MODE}" == "installed" ]; then
	cp ${SCRIPT_DIR}/FindEigen.cmake ${CMAKE_DIR} || fail
	echo "FindEigen.cmake copied to ${CMAKE_DIR}"
    fi
fi

echo "Done"

