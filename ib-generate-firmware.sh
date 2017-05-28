#!/bin/bash

# Input: JOB

set -e

DEST_DIR=""
IMG_PARAMS=""
JOB=""
PACKAGE_LIST_DIR="$(dirname "$0")/packages"

error() {
	echo "$@" >&2
}

parse_pkg_list_file() {
	# parse a package list file
	# ignores all lines starting with a #
	# returns a space seperated list of the packages
	pkg_file="$1"

	grep -v '^\#' $pkg_file | tr -t '\n' ' '
}

signal_handler() {
	# only remove directory when not empty
	if [ ! -z "$TEMP_DIR" ] ; then
		rm -Rf "$TEMP_DIR"
	fi
}

to_absolute_path() {
	# convert relative path into absolute path
	input="$1"
	if [ "$(echo "$1" | cut -c 1)" = "/" ] ; then
		# abs path already given
		echo $1
	else
		# we append the $pwd to it
		echo $(pwd)/$1
	fi
}

usage() {
	echo "
$0 -d <DEST_DIR> -i <IMAGEBUILDER> -j <JOB>

-d <DEST_DIR> destination dir
-i <IMAGEBUILDER> tar.xz of imagebuilder
-j <JOB> job, e.g., tl-wr842n-v1,4MB,backbone
"
}

while getopts "d:i:j:" option; do
  case "$option" in
		i)
			IB_FILE="$OPTARG"
			;;
		j)
			JOB="$OPTARG"
			;;
		d)
			DEST_DIR="$OPTARG"
			;;
    *)
      echo "Invalid argument '-${option}'."
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [ ! -f "$IB_FILE" ]; then
	error "image builder file is missing"
	exit 1
fi

if [ -z "$JOB" ]; then
  error "job missing"
  exit 1
fi

if [ -z "$DEST_DIR" ]; then
	error "destination dir is missing"
	exit 1
fi

# get profile
if [ "${JOB/,}" = "$JOB" ]; then
	error "malformed job"
	exit 1
fi
PROFILE=${JOB%%,*}
JOB=${JOB#*,}

# get suffix and package selection
if [ "${JOB/,}" = "$JOB" ]; then
	error "malformed job"
	exit 1
fi
PACKAGE_SELECTION_SUFFIX=${JOB%%,*}
PACKAGE_SELECTION=${JOB#*,}

PACKAGE_SELECTION_BASE="$PACKAGE_SELECTION"
if [ ! -z "$PACKAGE_SELECTION_SUFFIX" ]; then
	PACKAGE_SELECTION_BASE="${PACKAGE_SELECTION}_${PACKAGE_SELECTION_SUFFIX}"
fi

PACKAGE_LIST_FILE="${PACKAGE_LIST_DIR}/${PACKAGE_SELECTION_BASE}.txt"
if [ ! -f "$PACKAGE_LIST_FILE" ]; then
	error "package list does not exist: $PACKAGE_LIST_FILE"
fi
PACKAGES=$(parse_pkg_list_file "$PACKAGE_LIST_FILE")

POSTINST_SCRIPT=$(to_absolute_path "${PACKAGE_LIST_DIR}/${PACKAGE_SELECTION_BASE}.sh")
if [ -f "$POSTINST_SCRIPT" ]; then
	IMG_PARAMS="$IMG_PARAMS CUSTOM_POSTINST_SCRIPT=$POSTINST_SCRIPT"
fi

if [ -n "$EMBED_DIR" ]; then
	EMBED_DIR=$(to_absolute_path "${EMBED_DIR}")
	if [ $(ls $EMBED_DIR | wc -l) -gt 0 ]; then
			IMG_PARAMS="$IMG_PARAMS FILES=$EMBED_DIR"
	fi
fi

# extract imagebuilder to temporary dir (that should be removed on failure)
TEMP_DIR=$(mktemp -d imgXXXXXX)
trap signal_handler 0 1 2 3 15
tar xf "$IB_FILE" -C "$TEMP_DIR"

# sanitize dest_dir
mkdir -p "${DEST_DIR}/${PACKAGE_SELECTION}"
DEST_DIR=$(to_absolute_path "$DEST_DIR")

# execute imagebuilder
make -C "${TEMP_DIR}/$(ls ${TEMP_DIR}/)" image "PROFILE=$PROFILE" "PACKAGES=$PACKAGES" "BIN_DIR=${DEST_DIR}/${PACKAGE_SELECTION}" $IMG_PARAMS
