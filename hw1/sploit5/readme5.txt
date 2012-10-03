Sploit 5 Description
====================
Sploit5 takes advantage of the TOCTOU vulnerability between the
is_blocked check function in bcvs and the actual time of file open which
is in copyFile. We use this vulnerability to make bcvs overwrite the
sudoers file in a similar (but unique) fashion from sploit3.

We still have similar problems with file ownership and permissions as in
sploit3 but we overcome them differently here to maintain uniqueness. To
prevent bcvs from changing the file owner using chown we simply
overwrite chown. The "/bin/" directory does not exist in block.list and
so we can just wipe out the chown executable. The file we put in place
will still execute but we will just have it do nothing.

To prevent bcvs from changing the sudoers file from the required 0440
permissions we need to utilize an overflow in the checkout conditional
0f bcvs's copyFile. For this one you need to be cautious since you could
potentially create an infinite string copy if your input filename is
longer than 63 bytes. Our goal here is to overflow the chmodString in
copyFile by overflowing the src buffer. We create a string that is 60
bytes long and then append the permissions we want for the resulting
file (ie 440). The 440 will be written over the chmodString variable
giving us the permissions we need for the sudoers file.


Sploit5 Step-by-Step
====================
* First we create a fake chown script and check it into bcvs. Next we
  create a link under the same name as the checked-in file and link it
to the current /bin/chown file. Then we use bcvs to checkout our version
and overwrite the actual chown.

* New we use bcvs to check in a file that contains what we want to be in
  the sudoers file. The name of this file is described above and it is
crafted to overwrite the chmod string in copyFile.

* Now that everything is setup we start two python scripts which will
  run until the race condition is hit. We call these scripts the linker
and the runner (same script, just a falg to switch).

  Linker - The linker does the job of switching the file in the cwd
between an actual file and a link to the /etc/sudoers file. On each loop
it also checks if the target file's size (/etc/sudoers) matches the one
we made. If so we assume the exploit worked and exit. The linker does
have a small sleep because we found that if we let it go full speed it
usually took longer for the race condition to hit. The sleep occurs
after the file is linked to /etc/sudeors. Besides the sleep there is not
other timing between the linker and runner. 

  Runner - The runner's job is solely to run bcvs with the 'co' opcode
and the filename is the same as the one we previously checked-in. This
is also the name of the file/link that the linker will be switching in
the cwd.

* Usually it won't take too long to hit the race condition and once this
  happens the linker should exit and the sploit script will also exit
the runner and then execute 'sudo /bin/sh'


Design Changes to Prevent Sploit2
=================================
To prevent this race condition you could use various techniques but
essentially you need to make the check and open operations atomic or at
least to any other outside influences (ie another process).

If your system has filesystem level locking you could take the approach
of first locking whatever file is specified and then unlocking it once
all writing is completed. If an attacker where to try and exploit a race
condition they would fail because whatever the actual file was at the
time of the lock it will stay that way until the process is done with it
meaning that an external process can't change it to link to some
sensitive file.

To prevent the modification of the chmodString in copyFile would be
fixed by using strncpy and strncat just as described in readme1.txt for
the checkin clause of the conditional.

To prevent chown from being overwritten you should add /bin to your block
list at the very least but you would be naive to thing you are now
completely protected. Look at readme3.txt for more information on the
block list and enforcement of its intended rules.


Argument for Sploit Uniqueness
==============================
First of all this is the only sploit using the TOCTOU vulnerability so
the only other sources for overlap exist in the chmod/chown
circumvention.

The chown circumvention by simply overwriting the /bin/chown file is
different from how any of our other sploits do it and it would still
work if the exec calls were changed to use absolute paths since the
*actual* file that was originally intended to execute no longer exists.
This sploit is not stopped if the enforcement of the bcvs block.list is
made more secure as described in sploit3. This sploit would require
additions to the block.list, namely the /bin directory but probably
others as well. It may be simpler to implement a white-list approach.

Once again we are taking the lazy programmer approach in arguing that
this sploit is different from sploit1 in regards to the copyFile
overflow. This sploit uses an overflow in the checkout clause of the
conditional and sploit1 does so in the checkin clause. Also, sploit1
would not have worked using checkout because of the infinite string copy
problem.

Like sploit3, this sploit creates its own directory and .bcvs folder. This
is for convenience not necessity like sploit3. Without enough time left we
had to leave it in its original design. We do create an exact replica of
the .bcvs block.list file to show that it is not depending on the empty
block list.
