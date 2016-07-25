cmake_minimum_required(VERSION 3.5)
project(install-project)

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
target_link_libraries(${EXECUTABLE} ${TensorFlow_LIBRARIES})

# Eigen
find_package(Eigen REQUIRED)
include_directories(${Eigen_INCLUDE_DIRS})
target_link_libraries(${EXECUTABLE} ${Eigen_LIBRARIES})

# Protobuf (this module ships with CMake)
find_package(Protobuf REQUIRED)
include_directories(${PROTOBUF_INCLUDE_DIRS})
target_link_libraries(${EXECUTABLE} ${PROTOBUF_LIBRARIES})
