# Finds the required directories to include Eigen. Since Eigen is
# only header files, there is no library to locate, and therefore
# no *_LIBS variable is set.

include(FindPackageHandleStandardArgs)
include(eigen_VERSION)
unset(Eigen_FOUND)

find_path(Eigen_INCLUDE_DIR
        NAMES
        eigen/${eigen_dir}
        HINTS
	/usr/local/include
        /usr/include)

# set Eigen_FOUND
find_package_handle_standard_args(Eigen DEFAULT_MSG Eigen_INCLUDE_DIR)

# set external variables for usage in CMakeLists.txt
if (Eigen_FOUND)
    set(Eigen_INCLUDE_DIRS ${Eigen_INCLUDE_DIR})
endif()

# hide locals from GUI
mark_as_advanced(Eigen_INCLUDE_DIR)
