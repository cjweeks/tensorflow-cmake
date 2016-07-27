cmake_minimum_required(VERSION 3.5)
project(external-project)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)
set(SOURCE_FILES main.cc)
set(EXECUTABLE external-project)

# Add modules
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules")

find_package(TensorFlow REQUIRED)

# Location where external projects will be downloaded
set(DOWNLOAD_LOCATION "${PROJECT_SOURCE_DIR}/external/src" CACHE PATH "Location where external projects will be downloaded")
mark_as_advanced(DOWNLOAD_LOCATION)

include(Protobuf)
include(Eigen)

set(INCLUDE_DIRS ${TensorFlow_INCLUDE_DIRS})
set(LIBRARIES ${TensorFlow_LIBRARIES})
set(DEPENDENCIES Eigen Protobuf)

include_directories(${INCLUDE_DIRS})
add_executable(${EXECUTABLE} ${SOURCE_FILES})
target_link_libraries(${EXECUTABLE} ${LIBRARIES})
add_dependencies(${EXECUTABLE} ${DEPENDENCIES})
