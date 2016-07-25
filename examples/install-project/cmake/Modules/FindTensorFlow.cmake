# FindTensorFlow.cmake
# Connor Weeks
# Locates the tensorFlow include directories and library.

include(FindPackageHandleStandardArgs)
unset(TensorFlow_FOUND)

find_path(TensorFlow_INCLUDE_DIR
        NAMES
        tensorflow/core
        tensorflow/cc
        third_party
        HINTS
	/usr/local/include/google/tensorflow
        /usr/include/google/tensorflow)
      
find_library(TensorFlow_LIBRARY NAMES tensorflow_all
        HINTS
        /usr/lib
        /usr/local/lib)

set(TensorFlow_LIBS ${TensorFlow_LIBRARY})


# handle the QUIETLY and REQUIRED arguments and set LOGGING_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(TensorFlow DEFAULT_MSG TensorFlow_INCLUDE_DIR TensorFlow_LIBRARY)

if (TensorFlow_FOUND)
    set(TensorFlow_LIBRARIES ${TensorFlow_LIBRARY} )
    set(TensorFlow_INCLUDE_DIRS ${TensorFlow_INCLUDE_DIR} )
    set(TensorFlow_DEFINITIONS )
endif()

mark_as_advanced(TensorFlow_INCLUDE_DIR TensorFlow_LIBRARY)
