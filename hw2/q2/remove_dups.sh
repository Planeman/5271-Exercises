#!/bin/bash

if [[ $# != 2 ]]; then
  echo "Usage: $0 [input file] [output file]"
  exit 1
fi

echo "Removing duplicates from $1 -> $2"
awk '!seen[$0]++' ${1} > ${2}
