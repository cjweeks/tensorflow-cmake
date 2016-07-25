include(ExternalProject)
include(eigen_VERSION)

set(eigen_INSTALL ${PROJECT_SOURCE_DIR}/external/include/eigen/eigen-eigen-${eigen_archive_hash})

set(eigen_INCLUDE_DIRS
        ${PROJECT_SOURCE_DIR}/external/include/eigen
        ${eigen_INSTALL})

ExternalProject_Add(eigen
        PREFIX ${PROJECT_SOURCE_DIR}/external/src/eigen
        URL ${eigen_URL}
        URL_HASH ${eigen_HASH}
        DOWNLOAD_DIR ${DOWNLOAD_LOCATION}
        
        CMAKE_ARGS
        -DCMAKE_BUILD_TYPE:STRING=Release
        -DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF
        -DCMAKE_INSTALL_PREFIX:STRING=${eigen_INSTALL}
        -DINCLUDE_INSTALL_DIR:STRING=${eigen_INSTALL})
      
include_directories(${eigen_INCLUDE_DIRS})
