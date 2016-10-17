include(ExternalProject)
include(Protobuf_VERSION)

set(Protobuf_INCLUDE_DIRS ${EXTERNAL_DIR}/include/google/protobuf)
set(Protobuf_DOWNLOAD_DIR ${DOWNLOAD_LOCATION}/protobuf)

ExternalProject_Add(Protobuf
        PREFIX ${PROJECT_SOURCE_DIR}/external/src/protobuf
        URL ${Protobuf_URL}
        DOWNLOAD_DIR ${DOWNLOAD_LOCATION}
        BUILD_IN_SOURCE 1
        CONFIGURE_COMMAND  pwd && ./autogen.sh && ./configure --prefix=${PROJECT_SOURCE_DIR}/external
        BUILD_COMMAND cd ${Protobuf_DOWNLOAD_DIR} & make
        #TEST_BEFORE_INSTALL 1
        #TEST_COMMAND cd ${Protobuf_DOWNLOAD_DIR} && make check
        INSTALL_COMMAND make install)

include_directories(${Protobuf_INCLUDE_DIRS})
