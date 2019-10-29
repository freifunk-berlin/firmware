#!/bin/sh
#
# 2016 Alexander Couzens

# generate LEDE images

### inputs
# profile file
# package list
# an imagebuilder filename
# a target directory to save files

set -e

IB_FILE=""
PROFILES=""
TEMP_DIR=""
PKGLIST_DIR="$(dirname "$0")/imagetypes"
DEST_DIR="$(dirname "$0")/firmwares"
DEBUG=""
USECASES=""

signal_handler() {
	# only remove directory when not in debug mode
	if [ -z "$DEBUG" ] ; then
		rm -Rf "$TEMP_DIR"
	else
		info "Not removing temp dir $TEMP_DIR"
	fi
}

info() {
	echo "$@"
}

error() {
	echo "$@" >&2
}

# DEST_DIR needs to be an absolute path, otherwise it got broken
# because the imagebuilder is two levels deeper.
to_absolute_path() {
	input="$1"
	if [ "$(echo "$1" | cut -c 1)" = "/" ] ; then
		# abs path already given
		echo $1
	else
		# we append the $pwd to it
		echo $(pwd)/$1
	fi
}

parse_pkg_list_file() {
	# parse a package list file
	# ignores all lines starting with a #
	# returns a space seperated list of the packages
	pkg_file="$1"

	grep -v '^\#' $pkg_file | tr -t '\n' ' '
}

usage() {
	echo "
$0 -i <IB_FILE> -b <profile>

-d enable debug
-i <file> path to the image builder file
-b <file> board-list of openwrt-target
-t <dir> destination directory where to save the files
-n <dir> (optional) path to a temp directory
-e <dir> (optional) directory of files to directtly include into image
"
}

while getopts "di:n:b:t:e:" option; do
	case "$option" in
		d)
			DEBUG=y
			;;
		i)
			IB_FILE="$OPTARG"
			;;
		e)
			MBED_DIR="$OPTARG"
			;;
		t)
			DEST_DIR="$OPTARG"
			;;
		b)
			BOARDLIST="$OPTARG"
			;;
		n)
			TEMP_DIR="$OPTARG"
			;;
		*)
			echo "Invalid argument '-$OPTARG'."
			usage
			exit 1
			;;
	esac
done
shift $((OPTIND - 1))

if [ ! -e "$IB_FILE" ] ; then
	error "IB_FILE does not exist $IB_FILE"
	exit 1
fi

if [ -z "$TEMP_DIR" ] ; then
	TEMP_DIR=$(mktemp -d imgXXXXXX)
fi

if [ -z "$BOARDLIST" ] ; then
	error "No profile(s) given"
	exit 1
fi

mkdir -p "$TEMP_DIR"
trap signal_handler 0 1 2 3 15

# sanitize dest_dir
DEST_DIR=$(to_absolute_path "$DEST_DIR")
info $DEST_DIR

PROFILES=$(cat ${BOARDLIST} | cut -d : -f 1)
info "generating images for this boards: $(echo $PROFILES)"

info "Extract image builder $IB_FILE"
tar xf "$IB_FILE" --strip-components=1 -C "$TEMP_DIR"

for profile in $PROFILES ; do
	info "Building a profile for $profile"

	USECASES=default
	for usecase in $USECASES ; do
		package_list=""
		packages=""
		img_params=""

		packages="$(grep ${profile} ${BOARDLIST} | cut -d : -f 2)"

		if [ -z "${packages}" ] ; then
			info "skipping this usecase, as package list is empty"
			continue
		fi

		hookfile=$(to_absolute_path "${PKGLIST_DIR}/${package_list}.sh")
		if [ -f "$hookfile" ]; then
			info "Using a post inst hook."
			img_params="$img_params CUSTOM_POSTINST_SCRIPT=$hookfile"
		fi

		if [ -n "$MBED_DIR" ]; then
			mbed_dir=$(to_absolute_path "${MBED_DIR}")
			info "embedding files from $mbed_dir."
			if [ $(ls $mbed_dir | wc -l) -gt 0 ]; then
				img_params="$img_params FILES=$mbed_dir"
			fi
		fi

		# ensure BIN_DIR is valid
		mkdir -p "${DEST_DIR}/${package_list}"

		make -C "${TEMP_DIR}/" image "PROFILE=$profile" "PACKAGES=$packages" "BIN_DIR=${DEST_DIR}/${package_list}" $img_params
	done
done
