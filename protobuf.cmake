include(ExternalProject)
include(protobuf_VERSION)

set(protobuf_INCLUDE_DIRS ${PROJECT_SOURCE_DIR}/external/protobuf)
set(protobuf_LIB_DIR ${PROJECT_SOURCE_DIR}/external/lib

ExternalProject_Add(protobuf
        PREFIX ${PROJECT_SOURCE_DIR}/external/protobuf
        GIT_REPOSITORY ${protobuf_URL}
        GIT_TAG ${protobuf_commit}
        # DOWNLOAD_DIR "${DOWNLOAD_LOCATION}"
        INSTALL_DIR "${eigen_INSTALL}"
        #BINARY_DIR "${eigen_INSTALL}"
	CONFIGURE_COMMAND ./autogen.sh && ./configure --prefix=${PROJECT_SOURCE_DIR}/external
	BUILD_COMMAND make
	TEST_BEFORE_INSTALL 1
	TEST_COMMAND make check
	INSTALL_COMMAND make install
        #CMAKE_ARGS
        #-DCMAKE_BUILD_TYPE:STRING=Release
        #-DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF
        #-DCMAKE_INSTALL_PREFIX:STRING=${eigen_INSTALL}
        #-DINCLUDE_INSTALL_DIR:STRING=${PROJECT_SOURCE_DIR}/external/eigen-archive/${eigen_dir}

include_directories(${protobuf_INCLUDE_DIRS})
