Sploit2 Description
===================
Sploit2 takes advantage of the uncontrolled format string vulnerability
in writeLog. There were several complications with this sploit and I
will describe how I overcame them.

As the sploit currently stands there are two buffers required for the
exploit, the log buffer in main and the hap buffer for tempString in the
writeLog function. I needed to separate the attack info because of the
terminating characters used in writeLog. Specifically the 0xFF byte
which is used in the addresses I needed to write to.

The buffer in main contains the sequence of addresses that the printf
statement ultimately wants to overwrite. These addresses are the
individual byte addresses of writeLog's return pointer as well as the
pointer for tempString. Since my printf attack overwrites one byte at
a time I needed to place the full address for each of the 4 bytes (another 4
including tempString addresses) of the return pointer in log. I also repeated
the 4 addresses several times in case things get shifted on the stack
but so far this hasn't been necessary.

The heap buffer in writeLog is setup to hold the printf directives as
well as the shellcode. Since my addresses will no longer be stored right
above the printf stack I had to figure out how far up to go. I
determined that the offset for the first direct parameter access (dpa)
was 20. The python script for this exploit will generate this format
string with the correct %x padding and %n dpa so that the desired bytes
will be written to the given address (the one that ends up in main).

With the exception of the split addresses and format string this is
fairly close to a regular printf format string exploit. The other
problem I ran into was the opened shell not staying open after it
executed. I could see it execute in gdb so I knew most of the exploit
was working. After a lot of head scratching I found that the shell was
still trying to read from stdin which was at EOF after taking in the
format string. Luckily I found shellcode online (source in python
script) that re-opens the stdin file descriptor before executing the
shell.

** Note: I have this printf brute forcing some of the addresses just to
	be sure but it has been consistently working at base pointer
	offset 96 and printf dpa offset 0. These values get printed as
	the script executes and I just wanted you to know so you don't
	assume it isn't working.  


Sploit2 Step-by-Step
====================
* bcvs starts and makes it through the block list loading. The data in
  argv[2] (the addresses for the %n directives) are writtent to the log
buffer in main.
* The writeLog method is entered and the tempString buffer is allocated.
* Then the printf directives and shellcode are copied into the
  tempString.
* When writeLog executes 'printf(tempString)' and overwrites writeLog's
  return address to point into the heap at tempstring + ~75bytes to
account for the directives.
  * While debugging this sploit I was concerned about the
    free(tempString) call mangling the shellcode before writeLog would
return so I added printf directives to overwrite tempString with NULL. I
don't think this is required anymore.


Design Changes to Prevent Sploit2
=================================
While this was one of the more complicated sploits it has the easiest fix. Simply
use "printf("%s", tempString)" in writeLog so that tempString is interpreted strictly
as a string to be printed and not as a format string with printf
directives.

Argument for Sploit Uniqueness
==============================
This exploit does not depend on any bad coding practices or
vulnerabilities outside fot he uncontroled format string in writeLog.
The addresses put into main are significantly lower than the size of log
so it is not overflowed. Not even tempString in writeLog is overflowed.

There is no other sploit that utilizes the uncontrolled printf string so
therefore this is a unique sploit.
