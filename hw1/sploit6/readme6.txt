Sploit6 Description
===================
Sploit6 takes advantage of a buffer overflow ("user") in the checkout conditional
of the copyFile function by inputting an attack string through environment variable USER.
This sploit is a standard buffer overflow leading to a control flow hijack. The overwritten return pointer of the
copyFile function points back up the stack into the approximate region
where the buffer has overflowed and hits a nop sled.


Sploit6 Step-by-Step
====================
* In order for this sploit to work, a file must first be successfully checked in
to bcvs. The file does not matter, so a temporary file is made and dummy text redirected
in for the comments that bcvs prompts for.

* After checking in a file, bcvs is run to check a file out.

* Inputted into bcvs for the checkout file is just another temporary file with some dummy
input for comments.

* The attack string we generate contains the return address, nop sled and shell code. We had to
find a different shell code for this sploit due to how redirection works. When a root shell 
would be opened, it would immediately terminate as it was reading from stdin and getting an EOF.
To get around this, shell code was found that would close and then reopen the stdin file descriptor that would be bound
to the terminal.

* The buffer that we want to overflow is "user" in copyFile. As "user" is only 16 bytes, we decided to have the return 
address point "up", so that the return address would point higher up the stack.

* To overflow "user", we targeted the strcat() function, which fails to check the size of the buffer it is copying into. The
data it copies is the environment variable "User". We overwrite environment variable USER with the attack string, so that
bcvs copies in this string to the buffer "user" which then overflows.

* There was one additional trick, a couple of lines prior, bcvs forked itself. Our attack takes place in the child process that calls
execlp to "chown" a file. If the execlp executes successfully, our attack would not work as the process image of the bcvs child is destroyed.
So we need the execlp to fail and the child process to return in order to for the sploit to work. The solution was to overwrite environment variable PATH
to just be "", so that "chown" fails.

* Now that the execlp call fails, we return into the child process and then return from copyFile. The return address of copyFile points into the nop
sled of the overflowed "user" buffer. The nops are hit and slid down, then the shell code is executed.

* A root shell should now be open.


Design Changes to Prevent Sploit6
=================================
This sploit could most simply be prevented by a proper use of the strncat function to avoid the buffer overflow. For the checkout clause
of copyFile this is specifically on line 189. Here, strcat() should be changed to strncat(), which will only copy "n" bytes (of course the
terminating character must be taken into account). Hard links to "chown" should also probably be put in, in order to avoid setting env PATH
to be "".

Then the question becomes what to do when some input becomes truncated,
do you explicitly check if the input string is too long for the
destination buffer and return an error or do you take whatever was
copied?


Argument for Sploit Uniqueness
===============================
This is the only sploit that overflows the "user" buffer with strcat() in copyFile. This is also the only sploit that overwrites environment
variable USER to something other than what is expected (sploit3 overwrites env USER, however it does so with "root", which is a possible value for "User"
and would be difficult to check as the root user could actually be using bcvs). Additionally, this sploit differs from sploit5 by removing env PATH instead
of having a hard path to chown. The fix for this sploit (hard path to chown) would not break sploit5. Sploit3 also uses env USER, but it does not overflow
the "user" buffer, meaning any solutions using strncat() will stop this sploit (6) but not sploit3.
