#!/bin/bash

set -e

while IFS= read -r line
do
#  echo "$line"
  echo "${line}" | grep -v '^\#' | cut -d " " -f 2 | tr '\n' ' '
done < feeds.conf
