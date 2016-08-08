# Locates the tensorFlow library and include directories.

include(FindPackageHandleStandardArgs)
unset(TENSORFLOW_FOUND)

find_path(TensorFlow_INCLUDE_DIR
        NAMES
        tensorflow/tensorflow/core
        tensorflow/tensorflow/cc
        tensorflow/third_party
        HINTS
        /usr/local/include/google
        /usr/include/google)

find_library(TensorFlow_LIBRARY NAMES tensorflow_all
        HINTS
        /usr/lib
        /usr/local/lib)

# set TensorFlow_FOUND
find_package_handle_standard_args(TensorFlow DEFAULT_MSG TensorFlow_INCLUDE_DIR TensorFlow_LIBRARY)

# set external variables for usage in CMakeLists.txt
if(TENSORFLOW_FOUND)
    set(TensorFlow_LIBRARIES ${TensorFlow_LIBRARY})
    set(TensorFlow_INCLUDE_DIRS ${TensorFlow_INCLUDE_DIR} ${TensorFlow_INCLUDE_DIR}/tensorflow)
endif()

# hide locals from GUI
mark_as_advanced(TensorFlow_INCLUDE_DIR TensorFlow_LIBRARY)
