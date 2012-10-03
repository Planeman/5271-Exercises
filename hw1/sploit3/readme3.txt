Sploit3 Descripiton
===================
Sploit3 takes advantage of the weak block list enforcement in BCVS.
Since the block list is loaded in bcvs as a relative path
(".bcvs/block.list") it is easy to create your own directory structure
like this and fake a block.list. With this in mind, sploit3 creates its
own empty block.list and uses this removal of restriction to overwrite
the sudoers file to give the student group sudo access without a password.

Design Changes to Protect BCVS
==============================
There may be a reason to allow a user to specify their own block.list in
a similar fashion to the .gitignore file but this list should not be
taken as the authority.

A better approach would be to either use an absolute path to bcvs's
block list (ie "/opt/bcvs/.bcvs/block.list") or to enforce the blocked
directories in the program by hardcoding them. You can still give the
option to load a user specified list that will add to the strictly
enforced rules.

Even with these changes you are still subject to an attack if the user
is able to compromise your block list, either on the filesystem or in
memory using some other vulnerability of the program. This change
however would prevent the specific attack presented in this sploit.
