#!/bin/bash

# Input: MAINTARGET SUBTARGET PACKAGE_SELECTIONS

set -e

MAINTARGET=""
SUBTARGET=""
PACKAGE_SELECTIONS=""

error() {
	echo "$@" >&2
}

usage() {
	echo "
$0 -m <MAINTARGET> -s <SUBTARGET> -p PACKAGE_SELECTIONS

-m <MAINTARGET> name of main target, e.g., ar71xx
-s <SUBTARGET> name of subtarget, e.g., generic
-p <PACKAGE_SELECTIONS> selections of packages, e.g. \"default backbone\"
"
}

while getopts "m:s:p:" option; do
  case "$option" in
		m)
			MAINTARGET="$OPTARG"
			;;
    s)
      SUBTARGET="$OPTARG"
      ;;
		p)
			PACKAGE_SELECTIONS="$OPTARG"
			;;
    *)
      echo "Invalid argument '-$OPTARG'."
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [ -z "$MAINTARGET" ]; then
  error "main target missing"
  exit 1
fi

if [ -z "$SUBTARGET" ]; then
  error "subtarget missing"
  exit 1
fi

if [ -z "$PACKAGE_SELECTIONS" ]; then
	error "package selections are missing"
fi

PROFILES_FILE="$(dirname $0)/profiles/${MAINTARGET}-${SUBTARGET}.profiles"
if [ ! -e "$PROFILES_FILE" ]; then
  error "no profile for ${MAINTARGET}-${SUBTARGET}"
  exit 1
fi

# read profiles
PROFILES=$(<$PROFILES_FILE)

for profile in $PROFILES; do
	# profiles can have a suffix. like 4mb devices get a smaller package list pro use case
	# UBNT:4MB -> profile "UBNT" suffix "4MB"
	suffix=""
	if [ ! "${profile/:}" = "$profile" ]; then
		suffix=${profile##*:}
		profile=${profile%:*}
	fi

	for package_selection in $PACKAGE_SELECTIONS; do
		echo "${profile},${suffix},${package_selection}"
	done
done
