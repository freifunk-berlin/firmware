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
PKGLIST_DIR="$(dirname "$0")/packages"
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
$0 -i <IB_FILE> -p <profile>

-d enable debug
-i <file> path to the image builder file
-p <list> profiles to build for. seperate multiple profiles by a space
-t <dir> destination directory where to save the files
-l <dir> (optional) directory to the package lists
-n <dir> (optional) path to a temp directory
-u <list> usecase. seperate multiple usecases by a space
-e <dir> (optional) directory of files to directtly include into image
"
}

while getopts "di:l:n:p:t:u:e:" option; do
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
		p)
			PROFILES="$OPTARG"
			;;
		t)
			DEST_DIR="$OPTARG"
			;;
		l)
			PKGLIST_DIR="$OPTARG"
			;;
		n)
			TEMP_DIR="$OPTARG"
			;;
		u)
			USECASES="$OPTARG"
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

if [ -z "$USECASES" ] ; then
	error "No usecase(s) given"
	exit 1
fi

if [ -z "$PROFILES" ] ; then
	error "No profile(s) given"
	exit 1
fi

mkdir -p "$TEMP_DIR"
trap signal_handler 0 1 2 3 15

# sanitize dest_dir
DEST_DIR=$(to_absolute_path "$DEST_DIR")
info $DEST_DIR

info "Extract image builder $IB_FILE"
tar xf "$IB_FILE" --strip-components=1 -C "$TEMP_DIR"

for profile in $PROFILES ; do
	info "Building a profile for $profile"

	# profiles can have a suffix. like 4mb devices get a smaller package list pro use case
	# UBNT:4MB -> profile "UBNT" suffix "4MB"
	suffix="$(echo $profile | cut -d':' -f 2)"
	profile="$(echo $profile | cut -d':' -f 1)"

	for usecase in $USECASES ; do
		package_list=""
		packages=""
		img_params=""

		# check if packagelist with suffix exist
		if [ -e "${PKGLIST_DIR}/${usecase}_${suffix}.txt" ] ; then
			package_list="${usecase}_${suffix}"
		else
			package_list="${usecase}"
		fi

		if [ -e "${PKGLIST_DIR}/${package_list}.txt" ]; then
			info "Building usecase $usecase"
		else
			error "usecase $usecase not defined"
			exit 1
		fi

		info "Using package list $package_list"

		packages=$(parse_pkg_list_file "${PKGLIST_DIR}/${package_list}.txt")

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

		# Don't use the "BIN_DIR" option of the imagebuilder, as this fails for some boards
		# Till it'S fixed upstream, we move the files manually to the required destination
		# (see https://github.com/freifunk-berlin/firmware/pull/434)
		make -C ${TEMP_DIR}/ image PROFILE="$profile" PACKAGES="$packages" $img_params
		find ${TEMP_DIR}/bin/targets/ -type f -exec mv '{}' ${DEST_DIR}/${package_list} \;
	done
done
