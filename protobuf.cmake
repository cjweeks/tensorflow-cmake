include(ExternalProject)
include(protobuf_VERSION)

set(protobuf_INCLUDE_DIRS ${PROJECT_SOURCE_DIR}/external/include/google/protobuf)
set(protobuf_DOWNLOAD_DIR ${DOWNLOAD_LOCATION}/protobuf)

ExternalProject_Add(protobuf
        PREFIX ${PROJECT_SOURCE_DIR}/external/src/protobuf
        GIT_REPOSITORY ${protobuf_URL}
        GIT_TAG ${protobuf_commit}
	DOWNLOAD_DIR ${DOWNLOAD_LOCATION}
	BUILD_IN_SOURCE 1
	INSTALL_DIR <SOURCE_DIR>
     	CONFIGURE_COMMAND  pwd && ./autogen.sh && ./configure --prefix=${PROJECT_SOURCE_DIR}/external
	BUILD_COMMAND cd ${protobuf_DOWNLOAD_DIR} & make
	#TEST_BEFORE_INSTALL 1
	#TEST_COMMAND #cd ${protobuf_DOWNLOAD_DIR make check
	INSTALL_COMMAND make install #cd ${protobuf_DOWNLOAD_DIR} && make install)
)
include_directories(${protobuf_INCLUDE_DIRS})
