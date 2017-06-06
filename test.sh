#!/usr/bin/env bash
# Author: Connor Weeks



# test the funcionality of eigen and protobuf scripts by using the gen folder nd the examples


# This will generate / copy Eigen.cmake, Eigen_VERSION.cmake, Protobuf.cmake, and Protobuf_VERSION.cmake
#./eigen.sh generate external ~/git/tensorflow examples/external-project/cmake/Modules gen
#./protobuf.sh generate external ~/git/tensorflow examples/external-project/cmake/Modules gen

sudo ./eigen.sh install ../tensorflow gen
