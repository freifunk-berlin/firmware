#!/bin/bash

PROFILE=$1
DEFAULT_SOURCE="packages/minimal.txt"
PACKAGES_DEFAULT="$(grep -v '^#' $DEFAULT_SOURCE | tr -t '\n' ' ')"
PACKAGES=${PACKAGES:-$PACKAGES_DEFAULT}
BUILD_DIR="bin/firmware"
IB_SRC=$2
IB_CMD=${IB:-"make image"}

if [ $# -ne 3 ]; then
  echo "Usage: $(basename $0) PROFILE IMAGE_BUILDER_TAR"
  exit 65
fi

mkdir -p $BUILD_DIR
cd $BUILD_DIR
tar xfv $IB_SRC
$IB_CMB $PROFILE $PACKAGES

