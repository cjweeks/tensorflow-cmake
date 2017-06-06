#!/usr/bin/env bash
#
# Follow https://github.com/cjweeks/tensorflow-cmake
SCRIPT_DIR="$(cd "$(dirname "${0}")"; pwd)"
RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"

################################### Functions ###################################

# Prints an error message and exits with an error code of 1
fail () {
    echo -e "${RED}Command failed - script terminated${NO_COLOR}"
    exit 1
}

install_packages () {
    for PKG in ${*}; do
        if ! dpkg -l ${PKG} > /dev/null 2>&1; then
            apt-get -y install ${PKG} || fail
        fi
    done
    apt-get update -y
}

install_bazel () {
    BAZEL_DEB=bazel_${BAZEL_VER}-${OSTYPE}.deb
    if ! dpkg -l bazel > /dev/null 2>&1; then
        #wget https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VER/bazel-$BAZEL_VER-installer-$OSTYPE.sh
        if [ ! -e ${BAZEL_DEB} ]; then
            wget --no-check-certificate https://github.com/bazelbuild/bazel/releases/download/${BAZEL}_VER/${BAZEL_DEB} -O ${CACHE_DIR}/${BAZEL_DEB} || fail
        fi
        sudo dpkg -i ${CACHE_DIR}/${BAZEL_DEB} || fail
    fi
}

################################### Script ###################################

if [ ${#} -lt 2 ]; then
    echo "Usage: ${0} <build-dir> <install-dir>"
    exit 0
fi

# create the directorie if they don't already exist
mkdir -p "${1}" || fail
mkdir -p "${2}" || fail

BUILD_DIR=$(readlink -f "${1}")
INSTALL_DIR=$(readlink -f "${2}")
CACHE_DIR=${INSTALL_DIR}/cache

# install required packages
install_packages git autoconf build-essential automake libtool curl \
                 make g++ unzip python-numpy swig \
                 python-dev python-wheel openjdk-8-jdk \
                 pkg-config zip zlib1g-dev wget libcupti-dev || fail
install_bazel || fail


####################################################################
# Download and compile tensorflow from github
# Directory will be:
# $BUILD_DIR
#     - tensorflow-cmake
#     - tensorflow-github
#
mkdir -p ${INSTALL_DIR}/{include,lib,bin,share,cache}
mkdir -p ${INSTALL_DIR}/share/cmake/Modules
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

cd ${BUILD_DIR}

if [ ! -e ${CACHE_DIR}/tensorflow-github.tgz ]; then
    git clone https://github.com/tensorflow/tensorflow tensorflow-github || fail
    tar czf ${CACHE_DIR}/tensorflow-github.tgz tensorflow-github || fail
else
    cp ${CACHE_DIR}/tensorflow-github.tgz . || fail
    tar xzf ./tensorflow-github.tgz || fail
fi


####################################################################
# This specifies a new build rule, producing libtensorflow_all.so,
# that includes all the required dependencies for integration with
# a C++ project.
# Build the shared library and copy it to $INSTALLDIR
cd ${BUILD_DIR}/tensorflow-github
cat <<EOF >> tensorflow/BUILD
# Added build rule
cc_binary(
    name = "libtensorflow_all.so",
    linkshared = 1,
    linkopts = ["-Wl,--version-script=tensorflow/tf_version_script.lds"], # if use Mac remove this line
    deps = [
        "//tensorflow/cc:cc_ops",
        "//tensorflow/core:framework_internal",
        "//tensorflow/core:tensorflow",
    ],
)
EOF

./configure

#expect configure_script.exp
#./configure < configure_answers.txt
bazel build tensorflow:libtensorflow_all.so || fail

# copy the library to the install directory
cp bazel-bin/tensorflow/libtensorflow_all.so ${INSTALL_DIR}/lib || fail

# Copy the source to $INSTALL_DIR/include/google and remove unneeded items:
mkdir -p ${INSTALL_DIR}/include/google/tensorflow
cp -r tensorflow ${INSTALL_DIR}/include/google/tensorflow/
find ${INSTALL_DIR}/include/google/tensorflow/tensorflow -type f  ! -name "*.h" -delete

# Copy all generated files from bazel-genfiles:
cp  bazel-genfiles/tensorflow/core/framework/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/framework
cp  bazel-genfiles/tensorflow/core/kernels/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/kernels
cp  bazel-genfiles/tensorflow/core/lib/core/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/lib/core
cp  bazel-genfiles/tensorflow/core/protobuf/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/protobuf
cp  bazel-genfiles/tensorflow/core/util/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/core/util
cp  bazel-genfiles/tensorflow/cc/ops/*.h ${INSTALL_DIR}/include/google/tensorflow/tensorflow/cc/ops

# Copy the third party directory:
cp -r third_party ${INSTALL_DIR}/include/google/tensorflow/
rm -r ${INSTALL_DIR}/include/google/tensorflow/third_party/py

# Note: newer versions of TensorFlow do not have the following directory
rm -rf ${INSTALL_DIR}/include/google/tensorflow/third_party/avro

# Install eigen
# eigen.sh install <tensorflow-root> [<install-dir> <download-dir>]
${SCRIPT_DIR}/eigen.sh install "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}" "${INSTALL_DIR}/cache"
# eigen.sh generate installed <tensorflow-root> [<cmake-dir> <install-dir>]
#${SCRIPT_DIR}/eigen.sh generate external "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}/share/cmake" "${INSTALL_DIR}"

# Install protobuf
# protobuf.sh install <tensorflow-root> [<cmake-dir>]
${SCRIPT_DIR}/protobuf.sh install "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}" "${INSTALL_DIR}/cache"
# protobuf.sh generate installed <tensorflow-root> [<cmake-dir> <install-dir>]
#${SCRIPT_DIR}/protobuf.sh generate installed "${BUILD_DIR}/tensorflow-github" "${INSTALL_DIR}/share/cmake" "${INSTALL_DIR}"
