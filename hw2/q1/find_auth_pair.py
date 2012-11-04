#!/usr/bin/python

import re
import sys
import base64

# After tcpdump has captured the appropriate packets and we have printed
# them out, run this to find and decode the username:password pair

auth_header_re = re.compile('Authorization: Basic (.+)',re.MULTILINE)

def getAuthHeaderLine(data):
    if (data is None) or (len(data) == 0):
        print("No data given to getAuthHeaderLine")

    match = auth_header_re.search(data)

    if match is None:
        raise Exception("Failed to find auth header line")
    else:
        return match


def getAuthPair(b64_encoded):
    return base64.b64decode(b64_encoded)

def usage(name):
    print("Usage: {} [tcpdump_output]".format(name))
    print("Note: This is not the raw packet data but the result of running 'tcpdump -A [packets]'")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        usage(sys.argv[0])
        sys.exit(1)

    with open(sys.argv[1], 'r') as f:
        data = f.read()
        print("Formatted tcpdump data:\n{}".format(data))

        auth_line = getAuthHeaderLine(data)
        print("Authentication header line: {}".format(auth_line.group(0)))

        auth_pair = getAuthPair(auth_line.group(1))
        print("Authentication 'username:password' = {}".format(auth_pair))
