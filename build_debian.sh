#!/bin/bash -x
#
# Follow https://github.com/cjweeks/tensorflow-cmake

if [ $# -lt 2 ]; then
    echo "Usage: $0 <build-dir> <install-dir>"
    exit 0
fi

BUILDDIR=$(readlink -f "$1")
INSTALLDIR=$(readlink -f "$2")

#####################################################################
# optionals that can be overriden from outside

BAZEL_VER=${$BAZEL_VER:-"0.4.5"}
CACHEDIR=${CACHEDIR:-"$INSTALLDIR/cache"}
OSTYPE=${OSTYPE:-"linux-x86_64"}
PYTHONBIN=${PYTHONBIN:-"/usr/bin/python"}
PYTHONLIB=${PYTHONLIB:-"/usr/lib/python2.7/dist-packages"}
COMPILE_ARCH=${COMPILE_ARCH:-native}
USE_MKL=${USE_MKL:-N}
USE_JEMALLOC=${USE_JEMALLOC:-Y}
USE_CLOUD=${USE_CLOUD:-N}
USE_HADOOP=${USE_HADOOP:-N}
USE_XLA=${USE_XLA:-N}
USE_VERBS=${USE_VERBS:-N}
USE_OPENCL=${USE_OPENCL:-N}
USE_CUDA=${USE_CUDA:-N}


#####################################################################
# FUNCTIONS/HELPERS

function install_packages()
{
    for pkg in $*; do
        if ! dpkg -l $pkg > /dev/null 2>&1 ; then
            sudo apt-get -y install $pkg || exit 1
        fi
    done
}

function install_bazel()
{
    BAZEL_DEB=bazel_${BAZEL_VER}-${OSTYPE}.deb
    if ! dpkg -l bazel > /dev/null 2>&1; then
        #wget https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VER/bazel-$BAZEL_VER-installer-$OSTYPE.sh
        if [ ! -e $BAZEL_DEB ]; then
            wget --no-check-certificate https://github.com/bazelbuild/bazel/releases/download/$BAZEL_VER/$BAZEL_DEB -O $CACHEDIR/$BAZEL_DEB || exit 1
        fi
        sudo dpkg -i $CACHEDIR/$BAZEL_DEB || exit 1
    fi
}

####################################################################
# pre-requisites
install_packages git autoconf build-essential automake libtool curl \
                 make g++ unzip python-numpy swig \
                 python-dev python-wheel openjdk-8-jdk \
                 pkg-config zip zlib1g-dev wget
install_bazel


####################################################################
# Download and compile tensorflow from github
# Directory will be:
# $BUILDDIR
#     - tensorflow-cmake
#     - tensorflow-github
#
#rm -rf $INSTALLDIR
mkdir -p $INSTALLDIR/{include,lib,bin,share,cache}
mkdir -p $INSTALLDIR/share/cmake/Modules
rm -rf $BUILDDIR
mkdir -p $BUILDDIR


cd $BUILDDIR
if [ ! -e $CACHEDIR/tensorflow-cmake.tgz ]; then
    git clone https://github.com/Vitorian/tensorflow-cmake.git tensorflow-cmake
    tar czf $CACHEDIR/tensorflow-cmake.tgz tensorflow-cmake
fi
rm -rf tensorflow-cmake
tar xzf $CACHEDIR/tensorflow-cmake.tgz

if [ ! -e $CACHEDIR/tensorflow-github.tgz ]; then
    git clone https://github.com/tensorflow/tensorflow  tensorflow-github
    tar czf $CACHEDIR/tensorflow-github.tgz tensorflow-github
fi
rm -rf tensorflow-github
tar xzf $CACHEDIR/tensorflow-github.tgz

####################################################################
# This specifies a new build rule, producing libtensorflow_all.so,
# that includes all the required dependencies for integration with
# a C++ project.
# Build the shared library and copy it to $INSTALLDIR
cd $BUILDDIR/tensorflow-github
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

# except script to respond to ./configure
#> configure_script.exp
cat <<EOF | expect
spawn ./configure
sleep 1

expect "Please specify the location of python"
send "$PYTHONBIN\n"

expect "Please input the desired Python library path to use.  Default is"
send "$PYTHONLIB\n"

expect "Do you wish to build TensorFlow with MKL support? \\\\\[y/N\\\\\]"
send "$USE_MKL\n"

expect -re "Please specify optimization flags .*: "
send -- "-march=$COMPILE_ARCH -mtune=$COMPILE_ARCH\n"

expect "Do you wish to use jemalloc"
send "$USE_JEMALLOC\n"

expect "Do you wish to build TensorFlow with Google Cloud Platform support? \\\\\[y/N\\\\\]"
send "$USE_CLOUD\n"

expect "Do you wish to build TensorFlow with Hadoop File System support? \\\\\[y/N\\\\\]"
send "$USE_HADOOP\n"

expect "Do you wish to build TensorFlow with the XLA just-in-time compiler (experimental)? \\\\\[y/N\\\\\]"
send "$USE_XLA\n"

expect "Do you wish to build TensorFlow with VERBS support? \\\\\[y/N\\\\\]"
send "$USE_VERBS\n"

expect "Do you wish to build TensorFlow with OpenCL support? \\\\\[y/N\\\\\]"
send "$USE_OPENCL\n"

expect "Do you wish to build TensorFlow with CUDA support? \\\\\[y/N\\\\\]"
send "$USE_CUDA\n"

expect eof
EOF

#expect configure_script.exp
#./configure < configure_answers.txt
bazel build tensorflow:libtensorflow_all.so

# copy the library to the install directory
cp bazel-bin/tensorflow/libtensorflow_all.so $INSTALLDIR/lib

# Copy the source to $INSTALLDIR/include/google and remove unneeded items:
mkdir -p $INSTALLDIR/include/google/tensorflow
cp -r tensorflow $INSTALLDIR/include/google/tensorflow/
find $INSTALLDIR/include/google/tensorflow/tensorflow -type f  ! -name "*.h" -delete

# Copy all generated files from bazel-genfiles:
cp  bazel-genfiles/tensorflow/core/framework/*.h  $INSTALLDIR/include/google/tensorflow/tensorflow/core/framework
cp  bazel-genfiles/tensorflow/core/kernels/*.h  $INSTALLDIR/include/google/tensorflow/tensorflow/core/kernels
cp  bazel-genfiles/tensorflow/core/lib/core/*.h  $INSTALLDIR/include/google/tensorflow/tensorflow/core/lib/core
cp  bazel-genfiles/tensorflow/core/protobuf/*.h  $INSTALLDIR/include/google/tensorflow/tensorflow/core/protobuf
cp  bazel-genfiles/tensorflow/core/util/*.h  $INSTALLDIR/include/google/tensorflow/tensorflow/core/util
cp  bazel-genfiles/tensorflow/cc/ops/*.h  $INSTALLDIR/include/google/tensorflow/tensorflow/cc/ops

# Copy the third party directory:
cp -r third_party $INSTALLDIR/include/google/tensorflow/
rm -r $INSTALLDIR/include/google/tensorflow/third_party/py

# Note: newer versions of TensorFlow do not have the following directory
rm -r $INSTALLDIR/include/google/tensorflow/third_party/avro

# Install eigen
# eigen.sh install <tensorflow-root> [<install-dir> <download-dir>]
$BUILDDIR/tensorflow-cmake/eigen.sh install "$BUILDDIR/tensorflow-github" "$INSTALLDIR" "$INSTALLDIR/cache"
# eigen.sh generate installed <tensorflow-root> [<cmake-dir> <install-dir>]
$BUILDDIR/tensorflow-cmake/eigen.sh generate external "$BUILDDIR/tensorflow-github" "$INSTALLDIR/share/cmake" "$INSTALLDIR"

# Install protobuf
# protobuf.sh install <tensorflow-root> [<cmake-dir>]
$BUILDDIR/tensorflow-cmake/protobuf.sh install "$BUILDDIR/tensorflow-github" "$INSTALLDIR" "$INSTALLDIR/cache"
# protobuf.sh generate installed <tensorflow-root> [<cmake-dir> <install-dir>]
$BUILDDIR/tensorflow-cmake/protobuf.sh generate installed "$BUILDDIR/tensorflow-github" "$INSTALLDIR/share/cmake" "$INSTALLDIR"
