# tensorflow-cmake (currently not finished)
Integrate TnesorFlow with projects that use cmake without having to build inside the TensorFlow repository.

## TensorFlow
[TensorFlow](https://www.tensorflow.org/) is an amazing tool for machine learning and intelligence using computational graphs.
TensorFlow includes APIs for both Python and C++, although the C++ API is slightly less documented.  However, the most standard
way to integrate C++ projects with TensorFlow is to build the project *inside* the TensorFlow repository, yielding a massive binary.
Additionally, [Bazel](http://www.bazel.io/) is the only certified way to build such projects. This document and the code in this
reoository will allow one to build a C++ project using cmake without needing to build inside the TensorFlow repsoitory or generate a
large binary.

Note: The instructions here correspond to an Ubuntu Linux environment; although some commands may differ for other operating systems and distributions, the general ideas are identical.

## Step 1: Install TensorFlow
Donwload TensorFlow from its git repository: `git clone https://github.com/tensorflow/tensorflow`
Install Bazel and Python dependencies: 
```bash
sudo apt-get install bazel
sudo apt-get install python-numpy swig python-dev python-wheel
```
Enter the cloned repository, and append the following to the `tensorflow/BUILD` file:
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
Install:
```bash
./configure      # Note that this requires user input
bazel build tensorflow:libtensorflow_full.so
sudo cp bazel-bin/tensorflow/libtensorflow_full.so /usr/local/lib
```
Copy source to /usr/local/include/google and remove unneeded items
```bash
sudo mkdir -p /usr/local/include/google/tensorflow
sudo cp -r tensorflow /usr/local/include/google/tensorflow/
sudo find /usr/local/include/google/tensorflow/tensorflow -type f  ! -name "*.h" -delete
```
Copy all generated files from bazel-genfiles
```bash
sudo cp bazel-genfiles/tensorflow/core/framework/*.h  /usr/local/include/google/tensorflow/tensorflow/core/framework
sudo cp bazel-genfiles/tensorflow/core/kernels/*.h  /usr/local/include/google/tensorflow/tensorflow/core/kernels
sudo cp bazel-genfiles/tensorflow/core/lib/core/*.h  /usr/local/include/google/tensorflow/tensorflow/core/lib/core
sudo cp bazel-genfiles/tensorflow/core/protobuf/*.h  /usr/local/include/google/tensorflow/tensorflow/core/protobuf
sudo cp bazel-genfiles/tensorflow/core/util/*.h  /usr/local/include/google/tensorflow/tensorflow/core/util
sudo cp bazel-genfiles/tensorflow/cc/ops/*.h  /usr/local/include/google/tensorflow/tensorflow/cc/ops
```
Copy the third party directory:
```bash
sudo cp -r third_party  /usr/local/include/google/tensorflow/
sudo rm -r /usr/local/include/google/tensorflow/third_party/py
sudo rm -r /usr/local/include/google/tensorflow/third_party/avro
```


## Step 2: Install Eigen and Protobuf
The TensorFlow runtime library requires both [Protobuf](https://developers.google.com/protocol-buffers/) and [Eigen](http://eigen.tuxfamily.org/index.php?title=Main_Page).
However, specific versions are required, and these may clash with currently installed versions of either software.  Therefore, two options are
provided:

- Install the packages to `/usr/local`, which will overwrite / clash with any previous versions (but allow multiple projects to reference them).
- Add the packages as external dependencies, allowing CMake to download and build them
inside the project directory, not affecting any current versions.

Choose the option that best fits your needs; you may mix these options as well, installing one to `/usr/local`, while keeping the other confined in the current project.

### Eigen: Installing to `/usr/local`
Execute the `eigen.sh` script as follows: `sudo eigen.sh install <tensorflow-root> [<cmake-path>]`. The `insatll` command specifies that Eigen is to be installed to 
`usr/local/include`. The `<tensorflow-root>` argument should be the root of the TensorFlow repository. The optional `<cmake-path>` argument specifies the path to
copy the required CMake modules to (this should be your CMake modules directory); if left blank, the current directory will be used. This script installs Eigen
and copies `FindEigen.cmake` to the specified directory.  Add the following to your `CMakeLists.txt`:
```CMake
# Eigen
find_package(Eigen REQUIRED)
include_directories(${Eigen_INCLUDE_DIRS})
```

### Eigen: Adding as External Dependency
Execute the `eigen.sh` script as follows: `eigen.sh external <tensorflow-root> [<cmake-path>]`. The `external` command specifies that Eigen should not be 
installed, but rather treated as an external CMake dependency. The `<tensorflow-root>` argument again should be the root directory of the TensorFlow repository,
and the optional `<cmake-path>` argument is the location to copy the required CMake modules to (defaults to the current directory).  Two files will be copied
to the specified directory: `eigen.cmake` and `eigen_VERSION.cmake`. The former contains the specification of the external project, whereas the latter defines
exactly what version of Eigen to obtain.  Add the following to your `CMakeLists.txt`:
```CMake
# Eigen
include(Eigen)
add_dependencies(<EXECUTABLE_NAME> Eigen) # replace <EXECUTABLE_NAME> with name of executable
```


### Protobuf: Installing to `/usr/local`
Execute the `protobuf.sh` script as follows: `sudo protobuf.sh install <tensorflow-root> [<cmake-path>]`. The arguments are identical to those described in the Eigen
section above.  Add the following to your `CMakeLists.txt`:
```CMake
# Protobuf - CMake provides the FindProtobuf module
find_package(Protobuf REQUIRED)
include_directories(${PROTOBUF_INCLUDE_DIRS})
target_link_libraries(<EXECUTABLE_NAME> ${PROTOBUF_LIBRARIES})
```

### Protobuf: Adding as External Dependency
Execute the `protobuf.sh` script as follows: `protobuf.sh external <tensorflow-root> [<cmake-path>]`. The arguments are also identical to those described in the Eigen
section above.  Add the following to your `CMakeLists.txt`:
```CMake
# Protobuf
include(Protobuf)
add_dependencies(<EXECUTABLE_NAME> Protobuf) # replace <EXECUTABLE_NAME> with name of executable
```

## Step 3: Configure the CMake Project

Edit your `CMakeLists.txt` to append your new directory to the list of modules:
```CMake
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules")
# replace "${PROJECT_SOURCE_DIR}/cmake/Modules" with your path
```
If *either* Protobuf or Eigen was added as an external dependency, add the follwing to your `CMakeLists.txt`:
 
```CMake
# specify download location
set (DOWNLOAD_LOCATION "${PROJECT_SOURCE_DIR}/external/src"
        CACHE PATH "Location where external projects will be downloaded.")
mark_as_advanced(DOWNLOAD_LOCATION)
```

##MORE INFO TO COME
