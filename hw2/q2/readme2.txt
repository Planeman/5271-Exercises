Password Cracker Walkthrough
============================
Our password cracker is a simple python script. Here are the steps it
takes to crack a password:
* Read in the formatted tcp dump
  - For the server -> client auth message it parses all information in
    the WWW-Authenticate header
  - For the client -> server auth response it parses all information in
    the Authorization header

* It then loads each line of the dictionary file into a list for
  checking.

* It starts the cracking process. Using the information provided on
  wikipedia for digest authentication we know this is how the response
  is formed.

  HA1 = md5({username}:{realm}:{password})
  HA2 = md5({method}:{digestURI}
  response = md5({HA1}:{nonce}:{nonceCount}:{clientNonce}:{qop}:{HA2})

  - The piece of information we don't know (yet) is {password} so we
    cannot construct the correct HA1 and therefore the correct response.

  - The cracker iterates all passwords in the loaded dictionary and
    inserts them into the template for HA1 and computes the hash to get
    an HA1 value. This value is then put into the response template where it
    is hashed again to get the response value. This response value is
    compared to the one we observed the client send to the server. If they
    match then we have likely found the client's password so we log it and
    stop.


Password Guess
==============
The password our cracker found for this page is 'bacon'
