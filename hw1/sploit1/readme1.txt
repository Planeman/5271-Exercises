Sploit1 Description
===================
Sploit1 takes advantage of a buffer overflow in the checkin conditional
of the copyFile function. This sploit is a standard buffer overflow
leading to a control flow hijack. The overwritten return pointer of the
copyFile function points back down the stack into the approximate region
where the src and dest buffers are which hits a nop sled.


Sploit1 Step-by-Step
====================
* bcvs starts normally and passes through the block list checks and log
operations (which should fail to open the log).

* This exploits lies in copyfile which main calls with argv[2], our
shellcode. copyFile enters the checkin clause of its first conditional.

* Fist, argv[2] is copied into the src buffer using strcpy. This will
overflow but the way our shellcode is setup this likely won't give us
what we want.

* Second, copyFile fills the dst buffer with the repository directory
and then our shellcode which also overflows and this is where we overwrite
the return address.

* Since the contents of src and dst are gibberish they won't result in a
file successuflly being opened so copyFile will return after the file check.

* The return jumps into our nopsled which leads to the standard shellcode
for a exec of /bin/sh 


Design Changes to Prevent Sploit1
=================================
This sploit could most simply be prevented by a proper use of the strncpy
and strncat functions to avoid the buffer overflow. For the checkin clause
of copyFile this is specifically on lines 151-156. They should all be
changed you use their bound enforcing brothers strncpy and strncat.

Then the question becomes what to do when some input becomes truncated,
do you explcitly check if the input string is too long for the
destination buffer and return an error or do you take whatever was
copied?


Arugement for Sploit Uniqueness
===============================
This is the only sploit we have to overflow the src/dst buffers of copyFile
using the checkin conditional. Sploit5 uses the checkout conditional to
overflow the src buffer to overwrite the chmod string. From the lazy
programmer perspective we consider these to be separate exploits and sploit5
could be made to not even require an overflow but it was done just for
experience.

