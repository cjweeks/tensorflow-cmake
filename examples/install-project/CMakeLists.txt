cmake_minimum_required(VERSION 3.5)
project(install-project)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/bin)
set(SOURCE_FILES main.cc)
set(EXECUTABLE external-project)

# add modules
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules")

# find packages
find_package(TensorFlow REQUIRED)
find_package(Eigen REQUIRED)
find_package(Protobuf REQUIRED)

set(INCLUDE_DIRS ${TensorFlow_INCLUDE_DIRS} ${Eigen_INCLUDE_DIRS} ${PROTOBUF_INCLUDE_DIRS})
set(LIBRARIES ${TensorFlow_LIBRARIES} ${PROTOBUF_LIBRARIES})

include_directories(${INCLUDE_DIRS})
add_executable(${EXECUTABLE} ${SOURCE_FILES})
target_link_libraries(${EXECUTABLE} ${LIBRARIES})
