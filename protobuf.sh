#!/usr/bin/env bash
# Author: Connor Weeks

SCRIPT_DIR="$(cd "$(dirname "${0}")"; pwd)"
NUMJOBS=${NUMJOBS:-1}
RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"

# Prints an error message and exits with an error code of 1
fail () {
    echo -e "${RED}Command failed - script terminated${NO_COLOR}"
    exit 1
}

# Prints usage information concerning this script
print_usage () {
    echo "|
| Usage: ${0} generate|install [args]
|
| --> ${0} generate installed|external <tensorflow-source-dir> [<cmake-dir> <install-dir>]:
|
|     Generates the cmake files for the given installation of tensorflow
|     and writes them to <cmake-dir>. If 'generate installed' is executed,
|     <install-dir> corresponds to the directory Protobuf was installed to;
|     defaults to /usr/local.
|
| --> ${0} install <tensorflow-source-dir> [<install-dir> <download-dir>]
|
|     Downloads Protobuf to <download-dir> (defaults to the current directory),
|     and installs it to <install-dir> (defaults to /usr/local).
|"
}





# Tries to find protobuf using the given method
# Methods begin at 0 and increase as integers.
# If this function is called with a method that
# does not exist, it will print an error message
# and exit the program.
find_protobuf () {
    # Check for argument
    if [ -z "${1}" ]; then
	fail
    fi
    ATTEMPT_NUMBER=${1}

    echo "Finding Protobuf version in ${TF_DIR} using method ${ATTEMPT_NUMBER}..."
    # defs here
    ANY="[^\)]*"
    ANY_NO_QUOTES="[^\)\\\"]*"
    HTTP_HEADER="tf_http_archive\(\s"
    NAME_START="name\s*=\s*\\\""
    QUOTE_START="\s*=\s*\\\""
    QUOTE_END="\\\"\s*,\s*"
    FOOTER="\)"
    
    if [ ${ATTEMPT_NUMBER} -lt 2 ]; then
	PROTOBUF_NAME="${NAME_START}protobuf${QUOTE_END}"
    else
	# set name and reset the number
	# we want to repeat each method below for both names
	PROTOBUF_NAME="${NAME_START}com_google_protobuf${QUOTE_END}"
	ATTEMPT_NUMBER=$((${ATTEMPT_NUMBER} - 2))
    fi
    

    if [ ${ATTEMPT_NUMBER} -eq 0 ]; then
	PROTOBUF_REGEX="${HTTP_HEADER}${ANY}${PROTOBUF_NAME}${ANY}${FOOTER}"
	FOLDER="s/strip_prefix${QUOTE_START}\(${ANY_NO_QUOTES}\)${QUOTE_END}/\1/p"

	URL="s/url${QUOTE_START}\(${ANY_NO_QUOTES}\)${QUOTE_END}/\1/p"

	PROTOBUF_TEXT=$(grep -Pzo ${PROTOBUF_REGEX} ${TF_DIR}/tensorflow/workspace.bzl)
	PROTOBUF_TEXT=${PROTOBUF_TEXT//[[:space:]]/}
	PROTOBUF_URL=$(echo "${PROTOBUF_TEXT}" | sed -n ${URL})
	PROTOBUF_URLS[0]=${PROTOBUF_URL}
	PROTOBUF_FOLDER=$(echo "${PROTOBUF_TEXT}" | sed -n ${FOLDER})
    elif [ ${ATTEMPT_NUMBER} -eq 1 ]; then
	# find protobuf using arrays
        URL_SED="s/.*urls=\[\([^]]*\)\].*/\1/p"
	FOLDER="s/.*strip_prefix=\\\"\(${ANY_NO_QUOTES}\)\\\".*/\1/p"

	PROTOBUF_TEXT=$(grep -Pzo ${PROTOBUF_REGEX} ${TF_DIR}/tensorflow/workspace.bzl)
	PROTOBUF_TEXT=${PROTOBUF_TEXT//[[:space:]]/}
	PROTOBUF_URL=$(echo "${PROTOBUF_TEXT}" | sed -n ${URL_SED})
	PROTOBUF_URL=$(echo "${PROTOBUF_URL}" | sed 's/\"//g')
	IFS=',' read -r -a PROTOBUF_URLS <<< "${PROTOBUF_URL}"
	PROTOBUF_FOLDER=$(echo "${PROTOBUF_TEXT}" | sed -n ${FOLDER})
    else
	# no methods left to try
	echo -e "${RED}Failure: could not find Protobuf version in ${TF_DIR}${NO_COLOR}"
	exit 1
    fi


    # check if all variables were defined and are unempty
    if [ -z "${PROTOBUF_URL}" ] || [ -z "${PROTOBUF_URLS}" ] || [ -z "${PROTOBUF_FOLDER}" ];  then
	# unset varibales and return 1 (not found)
	unset PROTOBUF_URL
	unset PROTOBUF_URLS
	unset PROTOBUF_FOLDER
	return 1
    fi

    # return found
    return 0
}










# validate and assign input
if [ ${#} -lt 2 ]; then
    print_usage
    exit 1
fi
# Determine mode
if [ "${1}" == "install" ] || [ "${1}" == "generate" ]; then
    MODE="${1}"
else
    print_usage
    exit 1
fi

# get arguments
if [ "${MODE}" == "install" ]; then
    TF_DIR="${2}"
    INSTALL_DIR="/usr/local"
    DOWNLOAD_DIR="${PWD}"
    if [ ${#} -gt 2 ]; then
       INSTALL_DIR="$(cd ${3}; pwd)"
    fi
    if [ ${#} -gt 3 ]; then
	DOWNLOAD_DIR="$(cd ${4}; pwd)"
    fi
elif [ "${MODE}" == "generate" ]; then
    GENERATE_MODE="${2}"
    if [ "${GENERATE_MODE}" != "installed" ] && [ "${GENERATE_MODE}" != "external" ]; then
	print_usage
	exit 1
    fi
    TF_DIR="${3}"
    CMAKE_DIR="${PWD}"
    if [ ${#} -gt 3 ]; then
	CMAKE_DIR="$(cd ${4}; pwd)"
    fi
    INSTALL_DIR="/usr/local"
    if [ "${GENERATE_MODE}" == "installed" ] && [ ${#} -gt 4 ]; then
	INSTALL_DIR="$(cd ${5}; pwd)"
    fi
fi

# try to find protobuf information
N=0
find_protobuf ${N}
while [ ${?} -eq 1 ]; do
    N=$((N+1))
    find_protobuf ${N}
done



# print information
echo
echo -e "${GREEN}Found Protobuf information in ${TF_DIR}:${NO_COLOR}"
echo "Protobuf URL:  ${PROTOBUF_URL}"
echo "Protobuf folder:  ${PROTOBUF_FOLDER}"
echo

# perform requested action
if [ "${MODE}" == "install" ]; then
    # see if protobuf already exists in DONWLOAD_DIR

    # download and check for success
    DOWNLOAD="true"
    if [ -d "${DOWNLOAD_DIR}/${PROTOBUF_FOLDER}" ]; then
	echo -e "${YELLOW}Warning: Found protobuf directory, will delete and download latest version.${NO_COLOR}"
	rm -r ${DOWNLOAD_DIR}/${PROTOBUF_FOLDER} || fail
	echo "Removed ${DOWNLOAD_DIR}/${PROTOBUF_FOLDER}"
    fi
  
    FOUND_URL=0
    for URL in "${PROTOBUF_URLS[@]}"; do
	echo "Trying URL: ${URL}"
	PROTOBUF_ARCHIVE=$(echo "${URL}" | rev | cut -d'/' -f 1 | rev)
	echo "Protobuf Archive: ${PROTOBUF_ARCHIVE}"
	if [ "${DOWNLOAD}" == "true" ]; then
	    rm -f ${DOWNLOAD_DIR}/${PROTOBUF_ARCHIVE}
	    # download protobuf from http archive
	    cd ${DOWNLOAD_DIR} || fail
	    wget ${URL} && FOUND_URL=1 && break

	fi
    done
    if [ ${FOUND_URL} -eq 0 ]; then
	echo "${RED}Could not download Protobuf${NO_COLOR}"
	exit 1
    fi

    tar -xf ${PROTOBUF_ARCHIVE} || fail
    cd ${PROTOBUF_FOLDER} || fail




    # configure
    ./autogen.sh || fail
    ./configure --prefix=${INSTALL_DIR} || fail
    echo "Starting protobuf install."
    # build and install
    make -j$NUMJOBS || fail
    make check || fail
    make install || fail
    if [ `id -u` == 0 ]; then
        ldconfig || fail
    fi
    cd ${DOWNLOAD_DIR} || fail
    rm ${PROTOBUF_ARCHIVE} || fail
    echo "Protobuf has been installed to ${INSTALL_DIR}"
elif [ "${MODE}" == "generate" ]; then

    if [ "${GENERATE_MODE}" == "installed" ]; then
	# try to locate protobuf in INSTALL_DIR
	if [ -d "${INSTALL_DIR}/include/google/protobuf" ]; then
            echo -e "${GREEN}Found Protobuf in ${INSTALL_DIR}${NO_COLOR}"
	else
 	    echo -e "${YELLOW}Warning: Could not find Protobuf in ${INSTALL_DIR}${NO_COLOR}"
	fi
    fi

    PROTOBUF_OUT="${CMAKE_DIR}/Protobuf_VERSION.cmake"
    echo "set(Protobuf_URL ${PROTOBUF_URL})" > ${PROTOBUF_OUT} || fail
    if [ "${GENERATE_MODE}" == "external" ]; then
	echo "Wrote Protobuf_VERSION.cmake to ${CMAKE_DIR}"
	cp ${SCRIPT_DIR}/Protobuf.cmake ${CMAKE_DIR} || fail
	echo "Copied Protobuf.cmake to ${CMAKE_DIR}"
    elif [ "${GENERATE_MODE}" == "installed" ]; then
	echo "set(Protobuf_INSTALL_DIR ${INSTALL_DIR})" >> ${PROTOBUF_OUT} || fail
	echo "Wrote Protobuf_VERSION.cmake to ${CMAKE_DIR}"
	cp ${SCRIPT_DIR}/FindProtobuf.cmake ${CMAKE_DIR} || fail
	echo "Copied FindProtobuf.cmake to ${CMAKE_DIR}"
    fi
fi
echo -e "${GREEN}Done${NO_COLOR}"
exit 0
