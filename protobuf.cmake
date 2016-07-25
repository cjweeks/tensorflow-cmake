include(ExternalProject)
include(protobuf_VERSION)

set(protobuf_INCLUDE_DIRS ${PROJECT_SOURCE_DIR}/external/protobuf)

set(protobuf_BUILD ${PROJECT_SOURCE_DIR}/external/third_party/eigen/src/eigen)
set(protobuf_INSTALL ${PROJECT_SOURCE_DIR}/external/third_party/eigen/install)

ExternalProject_Add(eigen
        PREFIX ${PROJECT_SOURCE_DIR}/external/eigen
        URL ${eigen_URL}
        URL_HASH ${eigen_HASH}
        DOWNLOAD_DIR "${DOWNLOAD_LOCATION}"
        INSTALL_DIR "${eigen_INSTALL}"
        BINARY_DIR "${eigen_INSTALL}"

        CMAKE_ARGS
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF
        -DCMAKE_INSTALL_PREFIX:STRING=${eigen_INSTALL}
        -DINCLUDE_INSTALL_DIR:STRING=${PROJECT_SOURCE_DIR}/external/eigen-archive/${eigen_dir}

include_directories(${eigen_INCLUDE_DIRS})
