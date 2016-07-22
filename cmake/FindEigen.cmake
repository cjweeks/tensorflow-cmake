unset(Eigen_FOUND)
include(eigen_VERSION)
find_path(Eigen_INCLUDE_DIRS
        NAMES
        eigen/${eigen_dir}
        HINTS
	/usr/local/include/google/tensorflow
        /usr/include/google/tensorflow)

if(Eigen_INCLUDE_DIRS)
    set(Eigen_FOUND 1)
endif()
