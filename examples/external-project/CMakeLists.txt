cmake_minimum_required(VERSION 3.5)
project(external-project)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)
set(SOURCE_FILES main.cc)
set(EXECUTABLE external-project)

add_executable(${EXECUTABLE} ${SOURCE_FILES})

# Add modules
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules")

# TensorFlow
find_package(TensorFlow REQUIRED)
include_directories(${TensorFlow_INCLUDE_DIRS})
target_link_libraries(${EXECUTABLE} ${TensorFlow_LIBS})

# External dependencies (Eigen and Protobuf)
# Location where external projects will be downloaded
set (DOWNLOAD_LOCATION "${PROJECT_SOURCE_DIR}/external/src"
  CACHE PATH "Location where external projects will be downloaded.")
mark_as_advanced(DOWNLOAD_LOCATION)

include(protobuf)
include(eigen)

add_dependencies(${EXECUTABLE} eigen protobuf)
