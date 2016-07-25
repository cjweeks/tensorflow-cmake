# Examples

This directory contains two simple TensorFlow projects that may be built using cmake. The `external-project`
directory contains a project set up using Eigen and Protobuf as exteral dependencies (they wil be donwloaded
inside the external/ directory of the project wwhen built).  The `install-project`, however, requires you to
install both Eigen and Protobuf on your machine before building. To build either of theese projects, create a
directory inside the project to build from; then call cmake from that directory:

```
mkdir build
cd build
cmake ..
make
```

This will create a `bin/` directory in the project root, holding the executable. Run it *from the project root
directory* like this: `bin/<binary-name>` where `<binary-name>` is either `external-project` or `install-project`.