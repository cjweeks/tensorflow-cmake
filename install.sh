#!/bin/bash
src_dir="/usr/local/src"
cmake_dir="/usr/local/include/cmake-3.5/Modules"

# Install deps
sudo apt-get install autoconf automake libtool curl make g++ unzip python-numpy swig python-dev python-wheel

# Install bazel
echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | sudo tee /etc/apt/sources.list.d/bazel.list
curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install bazel

# Install tensorflow
cd ${src_dir}
git clone https://github.com/tensorflow/tensorflow --depth=1
cd tensorflow
echo -e \
"cc_binary(\n
    name = "libtensorflow_all.so",\n
    linkshared = 1,\n
    linkopts = ["-Wl,--version-script=tensorflow/tf_version_script.lds"],\n
    deps = [\n
        "//tensorflow/cc:cc_ops",\n
        "//tensorflow/core:framework_internal",\n
        "//tensorflow/core:tensorflow",\n
    ],\n
)" >> tensorflow/BUILD
./configure
bazel build tensorflow:libtensorflow_all.so
cp bazel-bin/tensorflow/libtensorflow_all.so /usr/local/lib
mkdir -p /usr/local/include/google/tensorflow
cp -r tensorflow /usr/local/include/google/tensorflow/
find /usr/local/include/google/tensorflow/tensorflow -type f  ! -name "*.h" -delete
cp bazel-genfiles/tensorflow/core/framework/*.h  /usr/local/include/google/tensorflow/tensorflow/core/framework
cp bazel-genfiles/tensorflow/core/kernels/*.h  /usr/local/include/google/tensorflow/tensorflow/core/kernels
cp bazel-genfiles/tensorflow/core/lib/core/*.h  /usr/local/include/google/tensorflow/tensorflow/core/lib/core
cp bazel-genfiles/tensorflow/core/protobuf/*.h  /usr/local/include/google/tensorflow/tensorflow/core/protobuf
cp bazel-genfiles/tensorflow/core/util/*.h  /usr/local/include/google/tensorflow/tensorflow/core/util
cp bazel-genfiles/tensorflow/cc/ops/*.h  /usr/local/include/google/tensorflow/tensorflow/cc/ops
cp -r third_party /usr/local/include/google/tensorflow/
rm -r /usr/local/include/google/tensorflow/third_party/py

# Install Eigen and Protobuf
cd ${src_dir}
git clone https://github.com/sjdrc/tensorflow-cmake --depth=1
cd tensorflow-cmake
./eigen.sh install ../tensorflow
./eigen.sh generate installed ../tensorflow ${cmake_dir}
./protobuf.sh install ../tensorflow
./protobuf.sh generate installed ../tensorflow ${cmake_dir}
cp FindTensorFlow.cmake ${cmake_dir}
