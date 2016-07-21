unset(TensorFlow_FOUND)

find_path(TensorFlow_INCLUDE_DIRS
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

if(TesorFlow_LIBS AND TensorFlow_INCLUDE_DIRS)
    message(FATAL_ERROR "Setting")
    set(TensorFlow_FOUND 1)
endif()
