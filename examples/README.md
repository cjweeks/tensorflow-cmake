# Examples

This directory contains two simple TensorFlow projects that may be built using cmake. The `external-project`
directory contains a project set up using Eigen and Protobuf as exteral dependencies (they will be donwloaded
inside the `external/` directory of the project wwhen built).  The `install-project`, however, requires you to
install both Eigen and Protobuf on your machine before building.

Note: The `FindTensorFlow.cmake` module has already been copied into these projects for simplicity; this must be
done manually for other projects.

## Configuring
The following instructions assume you are in the root directory of this repository, no alterations have been made
to the directory sructure, and the TensorFlow repository is located in `~/git/tensorflow`.  The steps for generating
the projects are as follows:

### External-Project
```bash
# This will generate / copy Eigen.cmake, Eigen_VERSION.cmake, Protobuf.cmake, and Protobuf_VERSION.cmake
./eigen.sh generate external ~/git/tensorflow examples/external-project/cmake/Modules examples/external-project/cmake/Modules
./protobuf.sh generate external ~/git/tensorflow examples/external-project/cmake/Modules examples/external-project/cmake/Modules
```

### Install-Project
First, install Eigen and Protobuf (skip if you have already done this).  Both libraries are installed to `/usr/local` in this
exanple; if you wish to install them elsewhere, simply substitute your directory:
```bash
sudo ./eigen.sh install ~/git/tensorflow /usr/local
sudo ./protobuf.sh install ~/git/tensorflow /usr/local
```

Generate the required CMake files (be sure to substitute the name of your install directory if it is not `/usr/local`):
```bash
# This will generate / copy FindEigen.cmake, Eigen_VERSION.cmake, FindProtobuf.cmake, and Protobuf_VERSION.cmake
./eigen.sh generate installed ~/git/tensorflow examples/install-project/cmake/Modules /usr/local
./protobuf.sh genearte installed ~/git/tensorflow examples/install-project/cmake/Modules /usr/local
```

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
If the program executes correctly, it will output `Success: 42!`, the result of adding two tensor objects.