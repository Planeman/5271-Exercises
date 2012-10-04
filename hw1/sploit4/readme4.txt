Sploit4 Description
===================
Sploit4 takes advantage of the buffer overflow of log in main. The
majority of this exploit is a standard control flow hijack by buffer
overflow where you have an attack string with a nop sled followed by
shellcode and finally return addresses. There are a few complications
however.

In the process of overflowing the log buffer there are other strcpy and
strcat operations which are outside the attacker's control. The one that
is especially troublesome is the final strcat of the ".comments" string.
After overwriting the return address for main the added ".comments"
mangles the pointers following, specifically argv. Since the byte value
of this string does not specify a valid memory address, when main tries
to dereference argv[2] while calling copy file it will segfault and main
will never return.

To get around this we added more to our attack string beyond the return
addresses. In the sploit script, these additions are called the
shellcode addition (SC_ADD). What it does is essentially rewrite the
pointers for argv rather than leaving ".comments" to provide an invalid
address. After our "shellcode addition" overwrites these pointers here
is how argv[2] ends up getting dereferenced.

Here is the assembly when dereferencing argv[2]:
0x08048c13 <+438>:mov       0xc(%ebp),%eax
0x08048c16 <+441>:add       $0x8,%eax
0x08048c19 <+444>:mov       (%eax),%eax
0x08048c168c1b <+446>:mov   %eax,(%esp)
0x08048c1e <+449>:call      0x8048c85     <copyFile>

First we make the address at 0xc(%ebp) (content of argv pointer) point
to an address that is 12 bytes (0xc) below &argv. This ends up just
pointing back to the frame pointer, %ebp.

The second thing is that we make the 4 byte memory segment that was
previously argc now an address that is one word past argv. When the
address obtained from the first instruction is incremented by 8 it will
land on this address which is then dereferenced to obtain the address of
our string (argv[2]) which is setup in the next/last step.

Lastly we make the word after argv point to the end of the copied string
".comments". Putting this all together, when the above assembly
executes we have manipulated the pointers to just jump around in a small
area and end up pointing to ".comments".

With this addition the call to copyFile can be made successfully and
when it returns main will do so shortly after, executing our shellcode.

Since doing this requires us knowing the exact addresses for main's
stack we cannot take a simple guess approach as for other overflows. For
this we have a python program which runs bcvs with mock input under gdb
and obtains a good guess for the frame address in main (%ebp). Then the
attack script tries the attack on bcvs using different frame addresses
in increments of 16 bytes out from our guess in either direction.
Usually we hit the correct address within one offset from the guess.


Sploit4 Step-by-Step
====================
I will avoid rehashing the argv manipulation and just go through the
high level scenario for the sploit.

* bcvs passes through the block.list loading. Then our attack string
  which came in on argv[2] is copied into log which overwrites main's
return pointer and arguments as described above.

* Then bcvs passes through the is_blocked and the writeLog functions.
  Then comes the copyFile call where our rewriting of argv[2] is put to
the test. If we failed it will segfault and the sploit will try a
different address. Otherwise copyFile will execute and most likely fail
to open the files for writing although this isn't important.

* After copyFile returns main will do so as well and then jump to our
  nop sled in the log buffer.

* Then you should have a shell with an euid of 0.


Design Changes to Prevent Sploit4
=================================
This whole sploit was made possible by the buffer overflow of log in
main. If the strcpy and strncpy methods used on log were replaced by
strncpy and strncat the attack could be prevented. Here is a more
appropriate way to copy argv[2] into log.

strncpy(log, REPOSITORY, 6);
strncat(log,  "/", 1);
strncat(log, argv[2], 240);
strncat(log, LOGEXT, 9);

Accounting for the null-terminator and the strings which must be there
you end up having 256 - 16 bytes left for the user input. This will
prevent the buffer overflow.


Argument for Sploit Uniqueness
==============================
There are other sploits(2) which use the log buffer to hold attack code but
none others that depend on overflowing log in order for sploit success.

The changes described in the previous section would only prevent
sploit4.
