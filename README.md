# tensorflow-cmake
Integrate TnesorFlow with projects that use cmake without having to build inside the TensorFlow repository.

## TensorFlow
[TensorFlow](https://www.tensorflow.org/) is an amazing tool for machine learning and intelligence using computational graphs.
TensorFlow includes APIs for both Python and C++, although the C++ API is slightly less documented.  However, the most standard
way to integrate C++ projects with TensorFlow is to build the project *inside* the TensorFlow repository, yielding a massive binary.
Additionally, [Bazel](http://www.bazel.io/) is the only certified way to build such projects. This document and the code in this
reoository will allow one to build a C++ project using cmake without needing to build inside the TensorFlow repsoitory or generate a
large binary.

Note: The instructions here correspond to an Ubuntu Linux environment; although some command may differ for other operating systems and distributions, the general ideas are identical.

## Step 1: Install TensorFlow
- Donwload TensorFlow from its git repository: `git clone https://github.com/tensorflow/tensorflow`
- Install Bazel and Python dependencies: 
```
sudo apt-get install bazel
sudo apt-get install python-numpy swig python-dev python-wheel
```
- Make alterations to the `tensorflow/BUILD` file; append the following:
```
# Added build rule
cc_binary(
        name = "libtensorflow_all.so",
        linkshared = 1,
        deps = [
            "//tensorflow/cc:cc_ops",
            "//tensorflow/core:framework_internal",
            "//tensorflow/core:tensorflow",
        ],
)
```
- Install:
```
./configure      # Note that this requires user input
cd tensorflow
bazel build tensorflow:libtensorflow_full.so
sudo cp bazel-bin/tensorflow/libtensorflow_full.so /usr/local/lib
```
- Copy source to /usr/local/include/google and remove unneeded items
```
sudo mkdir -p /usr/local/include/google/tensorflow
sudo cp -r tensorflow /usr/local/include/google/tensorflow/
sudo find /usr/local/include/google/tensorflow/tensorflow -type f  ! -name "*.h" -delete
```
- Copy all generated files from bazel-genfiles
```
sudo cp bazel-genfiles/tensorflow/core/framework/*.h  /usr/local/include/google/tensorflow/tensorflow/core/framework
sudo cp bazel-genfiles/tensorflow/core/kernels/*.h  /usr/local/include/google/tensorflow/tensorflow/core/kernels
sudo cp bazel-genfiles/tensorflow/core/lib/core/*.h  /usr/local/include/google/tensorflow/tensorflow/core/lib/core
sudo cp bazel-genfiles/tensorflow/core/protobuf/*.h  /usr/local/include/google/tensorflow/tensorflow/core/protobuf
sudo cp bazel-genfiles/tensorflow/core/util/*.h  /usr/local/include/google/tensorflow/tensorflow/core/util
sudo cp bazel-genfiles/tensorflow/cc/ops/*.h  /usr/local/include/google/tensorflow/tensorflow/cc/ops
```
- Copy the third party directory:
```
sudo cp -r third_party  /usr/local/include/google/tensorflow/
sudo rm -r /usr/local/include/google/tensorflow/third_party/py
sudo rm -r /usr/local/include/google/tensorflow/third_party/avro
```
- Run `tfind.sh` to generate the correct eigen cmake file and install the correct protobuf version:
    - The usage is `tfind.sh <tensorflow-source-dir> [<cmake-dir> <install-protobuf>]`
    - `tensorflow-source-dir` is the directory containing the tensorflow repository; in my case it is `~/git/tensorflow`
    - `cmake-dir` is the directory to generate the new cmake module; in this case it is `<PROJECT_ROOT>/cmake/Modules`
    - `install-protobuf` is either 'y' or 'n'. If the user specifies 'y', the required protobuf version will be cloned,
    built, tested, and installed. If 'n' is specified, the script simply prints out the protobuf repository URL and hash 
    corresponding to the required commit.  Execution of this script from the `resources` directory will look similar to:
    `./tfind.sh ~/git/tensorflow/ ../cmake/Modules/ y`

##MORE INFO TO COME
