Sploit3 Descripiton
===================
Sploit3 takes advantage of the weak block list enforcement in BCVS.
Since the block list is loaded in bcvs as a relative path
(".bcvs/block.list") it is easy to create your own directory structure
like this and fake a block.list. With this in mind, sploit3 creates its
own empty block.list and uses this new lack of restriction to overwrite
the sudoers file to give the student group sudo access without a password.

Since the sudoers file has strict rules on file ownership(root) and file
permissions (440) we had to prevent bcvs from using chmod and chown on
the written file. To do this we created our own chmod script in the
local directory and added '.' to the front of the path so that when
'chmod' was exec'd it would use our script. We actually don't prevent
the chown but instead we manipulate the 'USER' environment variable to
be root. We could have simply made our own local chown script but we
chose this method to prevent a potential overlap with another sploit.


Sploit3 Step-by-Step
====================
* The sploit3 script creates its own sploit3_dir and cd's to it. In here
  a .bcvs directory is created with an empty block.list. Then our
version of the sudoers file is placed in the new repository (.bcvs).
Then a symlink is created in the sploit3_dir that links a file of the
same name as the one in the repo to the /etc/sudoers file.

* Finally the sploit creates a script called 'chmod' in the local
  directory, makes it executable and adds the current directory to the
front of the PATH env variable. We also change the USER environment
variable to be root as described in the intro.

* The next step is to invoke bcvs to checkout the file we just added to
  the .bcvs directory. Since the symlink in the cwd has the same name it
will end up writing to this location which is actually /etc/sudoers.

* After overwriting the sudoers file with our own version, the student
  group should have sudo permission without even requiring a password
and so we execute 'sudo /bin/sh' to get a root shell.


Design Changes to Prevent Sploit3
=================================
There may be a reason to allow a user to specify their own block.list in
a similar fashion to the .gitignore file but this list should not be
taken as the authority.

A better approach would be to either use an absolute path to bcvs's
block list (ie "/opt/bcvs/.bcvs/block.list") or to enforce the blocked
directories in the program by hardcoding them. You can still give the
option to load a user specified list that will *add* to the strictly
enforced rules.

Even with these changes you are still subject to an attack if the user
is able to compromise your block list, either on the filesystem or in
memory using some other vulnerability of the program. This change
however would prevent the specific attack presented in this sploit.

To prevent the fooling of the execution of chmod you should use absolute
paths such as "/bin/chmod" rather than "chmod". This will help you as
long as you don't have some other vulnerability in your program that
allows a user to overwrite something directly in bin (see sploit5).

To prevent the USER environment variable hack you should not depend on
the environment variable at all. Instead you should use the c function
getuid to get the actual user id of the user executing bcvs. Then you
can use this id with the call to chown. As long as you presume the
system is secure the getuid function will return you the true user's id.

Argument for Sploit Uniqueness
==============================
There is one other sploit we have which targets the sudoers file and
overwrites it with the same content (sploit5). Sploit5 does so
by exploiting a TOCTOU race condition in bcvs and does not require that
the block.list file be empty so switching to a strictly enforced list
will not stop sploit5.

Sploit6 modifies the path in a similar way to sploit3 but their end
goals are separate. Sploit6 actually doesn't create any fake scripts it
just nukes the PATH variable to be "". Causing the exec of 'chown' to
fail so that the process doesn't exec and the return can jump to our
shellcode. This was why we made this sploit (sploit3) execute the real
chown with a changed user variable.

If you took the laziest approach and just fixed the "chmod" exec to be
an absolute path it would still leave sploit6 open. If you fix the USER
environment variable hack it would still leave sploit6 open.
