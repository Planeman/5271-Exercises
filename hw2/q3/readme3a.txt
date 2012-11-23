We started by creating an account on the provided webpage and observed
the cookie that was set after logging into that account. Everything was
normal according to the standard cookie format (netscape format) but the
part we were interested in was the cookie value.

It is clear that the first part of the cookie value is the username of
the logged in user. Since we weren't sure on the second half of the value we
created a second account with a different password for comparison. What
we noticed was that part of the value was still the same, %3D5C3F3EE. By
editing the current cookie we created one with a new value, Nick%3D5C3F3E.
This cookie worked successfully to access the hidden content which is
the following text:

"I am deeply afraid of Micky Mouse, but no one will know this but
me!!!!1!"

The viewing/editing of the cookie was done in firefox using an extension. The
line in cookies.txt was written by hand after looking up the format of
the Netscape cookies.txt format and copying what was presented in
firefox.
