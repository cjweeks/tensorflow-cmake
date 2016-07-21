#!/usr/bin/env bash

# Connor Weeks
#
# We are looking for the following:
#
# native.git_repository(
#     name = "protobuf",
#     remote = "https://github.com/google/protobuf",
#     commit = "ed87c1fe2c6e1633cadb62cf54b2723b2b25c280", (or any commit hash)
# )
#
# ...
#
# native.new_http_archive(
#     name = "eigen_archive",
#     url = "https://bitbucket.org/eigen/eigen/get/b4fa9622b809.tar.gz", (any url in this form)
#     sha256 = "2862840c2de9c0473a4ef20f8678949ae89ab25965352ee53329e63ba46cec62", (any hash in this form)
#     build_file = path_prefix + "eigen.BUILD",
# )


# Builds and installs protobuf from source.
# This function expects two arguments:
#     - The URL of the protobuf git repo
#     - The commit hash to reset to
install_protobuf() {
    # clone protobuf into ~/git
    mkdir -p ~/git
    cd ~/git
    git clone ${1}

    # reset back to specified commit
    cd protobuf
    git reset --hard ${2}

    # build and install
    ./autogen.sh
    ./configure
    make
    make check
    sudo make install
    sudo ldconfig
    echo "Installation finished"
}

# validate and assign input
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <tensorflow-source-dir> [cmake-dir] [install-protobuf]"
    exit 1
fi

CMAKE_DIR="."
if [ "$#" -gt 1 ]; then
    CMAKE_DIR="$2"
fi

PROMPT_FOR_INSTALL="true"
if [ "$#" -gt 2 ]; then
    PROMPT_FOR_INSTALL="false"
    if [ "${3}" == "y" ] || [ "${3}" == "Y" ]; then
        INSTALL_PROTOBUF="true"
    elif [ "${3}" == "n" ] || [ "${3}" == "N" ]; then
	    INSTALL_PROTOBUF="false"
    else
	    echo "Error: Must specifiy either 'y' or 'n' for argument 3 (install-protobuf)"
	    exit 1
    fi
fi

# define regular expressions to use
ANY="[^\)]*"
ANY_NO_QUOTES="[^\)\\\"]*"
ANY_HEX="[a-fA-F0-9]*"
GIT_HEADER="native.git_repository\(\s*"
ARCHIVE_HEADER="native.new_http_archive\(\s*"
NAME_START="name\s*=\s*\\\""
QUOTE_START="\s*=\s*\\\""
QUOTE_END="\\\"\s*,\s*"
FOOTER="\)"

PROTOBUF_NAME="${NAME_START}protobuf${QUOTE_END}"
EIGEN_NAME="${NAME_START}eigen_archive${QUOTE_END}"

PROTOBUF_REGEX="${GIT_HEADER}${ANY}${PROTOBUF_NAME}${ANY}${FOOTER}"
EIGEN_REGEX="${ARCHIVE_HEADER}${ANY}${EIGEN_NAME}${ANY}${FOOTER}"

COMMIT="s/\s*commit${QUOTE_START}\(${ANY_HEX}\)${QUOTE_END}/\1/p"
REMOTE="s/\s*remote${QUOTE_START}\(${ANY_NO_QUOTES}\)${QUOTE_END}/\1/p"
URL="s/\s*url${QUOTE_START}\(${ANY_NO_QUOTES}\)${QUOTE_END}/\1/p"
HASH="s/\s*sha256${QUOTE_START}\(${ANY_HEX}\)${QUOTE_END}/\1/p"
ARCHIVE_HASH="s=.*/\(${ANY_HEX}\)\\.tar\\.gz=\1=p"

echo "Finding protobuf and eigen versions in ${1}..."
PROTOBUF_TEXT=$(grep -Pzro ${PROTOBUF_REGEX} ${1})
EIGEN_TEXT=$(grep -Pzro ${EIGEN_REGEX} ${1})

PROTOBUF_COMMIT=$(echo "${PROTOBUF_TEXT}" | sed -n ${COMMIT})
PROTOBUF_URL=$(echo "${PROTOBUF_TEXT}" | sed -n ${REMOTE})
EIGEN_URL=$(echo "${EIGEN_TEXT}" | sed -n ${URL})
EIGEN_HASH=$(echo "${EIGEN_TEXT}" | sed -n ${HASH})
EIGEN_ARCHIVE_HASH=$(echo "${EIGEN_URL}" | sed -n ${ARCHIVE_HASH})

if [ -z "${PROTOBUF_URL}" ] || [ -z "${PROTOBUF_COMMIT}" ] || [ -z "${EIGEN_URL}" ] || [ -z "${EIGEN_HASH}" ]; then
    echo "Failure: Could not find all required strings in ${1}"
    exit 1
fi

# print information
echo
echo "Protobuf Repo:       ${PROTOBUF_URL}"
echo "Protobuf Commit:     ${PROTOBUF_COMMIT}"
echo "Eigen URL:           ${EIGEN_URL}"
echo "Eigen URL Hash:      ${EIGEN_HASH}"
echo "Eigen Archive Hash:  ${EIGEN_ARCHIVE_HASH}"
echo

# output Eigen information to file
EIGEN_OUT="${CMAKE_DIR}/eigen_VERSION.cmake"
echo "set(eigen_URL ${EIGEN_URL})" > ${EIGEN_OUT}
echo "set(eigen_archive_hash ${EIGEN_ARCHIVE_HASH})" >> ${EIGEN_OUT}
echo "set(eigen_HASH SHA256=${EIGEN_HASH})" >> ${EIGEN_OUT}
echo "Eigen variables written to ${EIGEN_OUT}"

if [ "${PROMPT_FOR_INSTALL}" == "true" ]; then
    # ask user before installing protobuf
    read -p "Clone protobuf to ~/git and install? [y/N]" RESPONSE
    if [ "${RESPONSE}" == "y" ] || [ "${RESPONSE}" == "y" ]; then
	    INSTALL_PROTOBUF="true"
    else
	    INSTALL_PROTOBUF="false"
    fi
fi

if [ "${INSTALL_PROTOBUF}" == "true" ]; then
    install_protobuf ${PROTOBUF_URL} ${PROTOBUF_COMMIT}
fi

echo "Done"
