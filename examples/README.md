# Examples

This directory contains two simple TensorFlow projects that may be built using cmake. The `external-project`
directory contains a project set up using Eigen and Protobuf as exteral dependencies (they wil be donwloaded
inside the external/ directory of the project wwhen built).  The `install-project`, however, requires you to
install both Eigen and Protobuf on your machine before building.

## Building and Running
To build either of theese projects, create a directory inside the project to build from; then call cmake
from that directory:

```bash
mkdir build
cd build
cmake ..
make
```

This will create a `bin/` directory in the project root, holding the executable. Run it *from the project root
directory* like this: `bin/<binary-name>` where `<binary-name>` is either `external-project` or `install-project`.

## Gnerating the Projects
These projects already have the required CMake modules listed.  However, they were generated using the scripts from
this repository.  This assumes you are in the root directory of this repository, the directory structure for the
projects exist, main.cc and graph.pb are already positioned, and the TensorFlow repository is located in
`~/git/tensorflow`.  The steps for generating the projects are as follows:

### External-Project
```bash
# This will generate / copy Eigen.cmake, Eigen_VERSION.cmake,
# Protobuf.cmake, and Protobuf_VERSION.cmake
./eigen.sh external ~/git/tensorflow examples/external-project/cmake/Modules
./protobuf.sh external ~/git/tensorflow examples/external-project/cmake/Modules
cp FindTensorFlow.cmake examples/external-project/cmake/Modules 
```

### Install-Project
```bash
# This will install Protobuf and Eigen to /usr/local and
# copy FindEigen.cmake
./eigen.sh external ~/git/tensorflow examples/external-project/cmake/Modules
./protobuf.sh external ~/git/tensorflow examples/external-project/cmake/Modules
cp FindTensorFlow.cmake  examples/external-project/cmake/Modules
```
