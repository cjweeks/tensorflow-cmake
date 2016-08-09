include(ExternalProject)
include(Eigen_VERSION)

set(Eigen_INSTALL ${EXTERNAL_DIR}/include/eigen/${Eigen_DIR})

set(Eigen_INCLUDE_DIRS
        ${PROJECT_SOURCE_DIR}/external/include/eigen
        ${Eigen_INSTALL})

ExternalProject_Add(Eigen
        PREFIX ${PROJECT_SOURCE_DIR}/external/src/eigen
        URL ${Eigen_URL}
        URL_HASH ${Eigen_HASH}
        DOWNLOAD_DIR ${DOWNLOAD_LOCATION}

        CMAKE_ARGS
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF
        -DCMAKE_INSTALL_PREFIX:STRING=${Eigen_INSTALL}
        -DINCLUDE_INSTALL_DIR:STRING=${Eigen_INSTALL})

include_directories(${Eigen_INCLUDE_DIRS})
