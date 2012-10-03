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
mangles the pointer following, specifically argv. Since the byte value
of this string does not specify a valid memory address, when main trys
to dereference argv[2] while calling copy file it will segfault and main
will never return.

To get around this we added more to our attack string beyond the return
addresses.
