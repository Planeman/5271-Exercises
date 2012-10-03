Sploit7 Description
===================
Sploit7 takes advantage of a buffer overflow in the is_blocked fucntion caused by the realpath fucntion. 
This sploit is a buffer overflow leading to a control flow hijack. The overwritten return pointer of the
is_blocked function points back up the stack into the approximate region where the attack string is located
and hits a nop sled.


Sploit7 Step-by-Step
====================
* This sploit works by taking advantage of the realpath function inside of is_blocked. Ideally, if realpath worked as it should,
there would be no attack. However, it copies the path inputted into a buffer while not checking the size of the buffer, leading to
an overflow.

* We were a little surprised to find that realpath was simply copying bytes from the inputted path to the result buffer (specifically the
"canonical_pathname" buffer) without checking the size of the result buffer. We had originally envisioned an attack of making realpath
fail by having an incredibly long file path and then a symlink to the sudoers file (for example). We would then overwrite the sudoers
file to allow use to sudo into root. But, the sploit was made easy due to the fact that realpath just copied the bytes.

* It was trivial to generate an attack string and input it into bcvs. This attack string was quite large (800 bytes), but that was because
the "canononical_pathname" buffer was 500 bytes, with another 32 bytes or so inbetween the end of the buffer (higher address) and the lcoation
of is_blocked's return address.

* The attack string was formatted as such [ return address ][ nops ] [shell code]. We just want to highlight that the nop sled was made larger due
to some unexpected behavior described below.

* We found that realpath, while successfully copying the return address and nops, would mangle the shellcode. Random byte shifts would occur and
0x00000000 would be written in. This rendered the shellcode useless, we could easily hit the nop sled but the shellcode would not work. The solution was
to point the return address way up the stack into argv[2], which is where the un-mangled attack string was located. Then, the nop sled would be hit and
the shell code would execute.

* A root shell should now be open.


Design Changes to Prevent Sploit7
=================================
This sploit could most simply be prevented by a proper use of the realpath function. Specifically, instead of passing in a buffer, pass in "NULL", which
means realpath will allocate a buffer of at most PATH_MAX bytes. Of course this buffer needs to be freed before a function returns. By having realpath allocate
space, we avoid overflowing any buffers that are too small.


Arugement for Sploit Uniqueness
===============================
This is the only sploit that uses the realpath vulnerability.
