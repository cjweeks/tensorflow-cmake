SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

# Exits if user doe not have root priveledges
check_root() {
    if [ "${EUID}" -ne 0 ]; then
	echo "Please run as root to install."
	exit 1
    fi
}

print_usage() {
    echo "Usage: ${0} <external|install> <tensorflow-source-dir> [cmake-dir]"
}


ANY="[^\)]*"
ANY_NO_QUOTES="[^\)\\\"]*"
ANY_HEX="[a-fA-F0-9]*"
ARCHIVE_HEADER="native.new_http_archive\(\s*"
NAME_START="name\s*=\s*\\\""
QUOTE_START="\s*=\s*\\\""
QUOTE_END="\\\"\s*,\s*"
FOOTER="\)"
EIGEN_NAME="${NAME_START}eigen_archive${QUOTE_END}"

EIGEN_REGEX="${ARCHIVE_HEADER}${ANY}${EIGEN_NAME}${ANY}${FOOTER}"

URL="s/\s*url${QUOTE_START}\(${ANY_NO_QUOTES}\)${QUOTE_END}/\1/p"
HASH="s/\s*sha256${QUOTE_START}\(${ANY_HEX}\)${QUOTE_END}/\1/p"
ARCHIVE_HASH="s=.*/\(${ANY_HEX}\)\\.tar\\.gz=\1=p"

echo "Finding eigen version in ${1}..."
EIGEN_TEXT=$(grep -Pzro ${EIGEN_REGEX} ${1})

EIGEN_URL=$(echo "${EIGEN_TEXT}" | sed -n ${URL})
EIGEN_HASH=$(echo "${EIGEN_TEXT}" | sed -n ${HASH})
EIGEN_ARCHIVE_HASH=$(echo "${EIGEN_URL}" | sed -n ${ARCHIVE_HASH})

if [ -z "${EIGEN_URL}" ] || [ -z "${EIGEN_HASH}" ] || [ -z "${EIGEN_ARCHIVE_HASH}" ]; then
    echo "Failure: Could not find all required strings in ${TF_DIR}"
    exit 1
fi

# validate and assign input
if [ "$#" -lt 2 ]; then
    print_usage 
    exit 1
fi
MODE="${1}"
TF_DIR="${2}"
CMAKE_DIR="."
if [ "$#" -gt 2 ]; then
    CMAKE_DIR="${3}"
fi

if [ "${MODE}" == "external" ]; then
    # add eigen as external cmake dependency
    
# set(eigen_dir eigen-eigen-${eigen_archive_hash})
