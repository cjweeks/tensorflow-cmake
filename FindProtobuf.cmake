include(FindPackageHandleStandardArgs)
include(Protobuf_VERSION)
unset(PROTOBUF_FOUND)

find_path(Protobuf_INCLUDE_DIR
        NAMES
        protobuf
        HINTS
        ${Protobuf_INSTALL_DIR}/include/google)

find_library(Protobuf_LIBRARY NAMES protobuf
        HINTS
        ${Protobuf_INSTALL_DIR}/lib)
# set Protobuf_FOUND
find_package_handle_standard_args(Protobuf DEFAULT_MSG Protobuf_INCLUDE_DIR Protobuf_LIBRARY)

# set external variables for usage in CMakeLists.txt
if(PROTOBUF_FOUND)
    set(Protobuf_LIBRARIES ${Protobuf_LIBRARY})
    set(Protobuf_INCLUDE_DIRS ${Protobuf_INCLUDE_DIR})
endif()



# hide locals from GUI
mark_as_advanced(Protobuf_INCLUDE_DIR)
