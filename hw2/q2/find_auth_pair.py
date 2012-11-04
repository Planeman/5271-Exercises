#!/usr/bin/python

import re
import gc
import sys
import time
import hashlib

req_header_re = re.compile("(?P<method>GET)\s*(?P<uri>.+?)\s*HTTP/1\.1", re.M | re.I)

auth_server_raw = "WWW-Authenticate: Digest realm=\"(?P<realm>[A-Z]+)\", nonce=\"(?P<snonce>.+?)\",\s*"
auth_server_raw += "algorithm=(?P<hashtype>MD5), qop=\"(?P<qop>auth)\""
auth_server_re = re.compile(auth_server_raw, re.M | re.I)

auth_resp_raw = "Authorization: Digest username=\"(?P<username>student2)\",\s*"
auth_resp_raw += "realm=\"(?P<realm>supercool)\", nonce=\"(?P<snonce>.+?)\",\s*"
auth_resp_raw += "uri=\"(?P<uri>.+?)\", cnonce=\"(?P<cnonce>.+?)\", nc=(?P<ncount>[0-9]+),\s*"
auth_resp_raw += "qop=\"(?P<qop>auth)\", response=\"(?P<cresp>.+?)\", algorithm=\"(?P<hashtype>MD5)\""
auth_resp_re = re.compile(auth_resp_raw, re.M | re.I)


# ASCII character ranges
numbers = range(48,58)
cap_letters = range(65,91)
low_letters = range(97,123)

def xselections(items, n):
  if n==0: yield []
  else:
    for i in xrange(len(items)):
      for ss in xselections(items, n-1):
        yield [items[i]]+ss


class AuthContextException(Exception):
  pass


class AuthContext:
  def __init__(self, pw_generator):
    self.realm = ""
    self.username = ""
    self.password = ""  # Our target

    self.qop = "auth"
    self.server_nonce = ""
    self.client_nonce = ""
    self.nonce_count = ""  # nc in the http header

    self.request_method = "GET"
    self.request_uri = ""

    self.client_resp = ""

    self.hashtype = "MD5"

    self.pw_gen = pw_generator


  def crackPassword(self, data=None, filename=None):
    if data is None:
      if filename is None:
        raise AuthContextException("No data provided and filename is None")
      else:
        with open(filename, 'r') as f:
          data = f.read()

    self.extractServerAuthData(data)
    self.extractClientAuthData(data)

    print(str(self))
    print("Starting password crack...")

    # Using the notation from the wikipedia page here:
    # http://en.wikipedia.org/wiki/Digest_access_authentication

    ha1_template = "{0.username}:{0.realm}:{{}}".format(self)
    ha2 = hashlib.md5("{0.request_method}:{0.request_uri}".format(self)).hexdigest()

    # HA1:snonce:nc:cnonce:qop:HA2
    resp = "{{}}:{0.server_nonce}:{0.nonce_count}:{0.client_nonce}:{0.qop}:{1}".format(self, ha2)
    print("HA1 template = " + ha1_template)
    print("HA2 = " + ha2)
    print("resp template = " + resp)

    # This is code from the old brute force method where we would just cruise through all
    # various permutation.
    #ascii_list = []
    #for i in self.charset:
    #  ascii_list.append(str(chr(i)))

    count = 0
    stime = time.time()
    for pw in self.pw_gen:
        ha1 = hashlib.md5(ha1_template.format(pw)).hexdigest()
        full_resp = resp.format(ha1)
        if hashlib.md5(full_resp).hexdigest() == self.client_resp:
          print("Found password: {}".format(pw))
          return

        count += 1
        if count % 10000 == 0:
          print("Tried {} passwords: running time = {} seconds".format(count, time.time() - stime))
          print("\tMost recent pass {}".format(pw))


  def extractServerAuthData(self, data):
    m = auth_server_re.search(data)
    if m is None:
      raise AuthContextException("Failed to find server authorization request")

    self.realm = m.group('realm')
    self.server_nonce = m.group('snonce')
    self.hashtype = m.group('hashtype')
    self.qop = m.group('qop')


  def extractClientAuthData(self, data):
    m = auth_resp_re.search(data)
    if m is None:
      raise AuthContextException("Failed to find client authorization response")

    if self.server_nonce == "":
      raise AuthContextException("Must extract server auth data first")

    self.username = m.group('username')

    temp = m.group('realm')
    if temp != self.realm:
      raise AuthContextExcpetion("Server/Client realm mismatch")

    temp = m.group('snonce')
    if temp != self.server_nonce:
      raise AuthContextException("Server/Client nonce mismatch")

    self.request_uri = m.group('uri')
    self.client_nonce = m.group('cnonce')
    self.nonce_count = m.group('ncount')

    temp = m.group('qop')
    if temp != self.qop:
      raise AuthContextException("Server/Client using different qop")


    self.client_resp = m.group('cresp')

    temp = m.group('hashtype')
    if temp != self.hashtype:
      raise AuthContextException("Server/Client using different hash type ({}:{})".format(self.hashtype, temp))


  def __str__(self):
    repr = "realm = {0.realm}\n".format(self)
    repr += "username = {0.username}\n".format(self)
    repr += "password = {0.password}\n".format(self)
    repr += "qop = {0.qop}\n".format(self)
    repr += "server_nonce = {0.server_nonce}\n".format(self)
    repr += "client_nonce = {0.client_nonce}\n".format(self)
    repr += "nonce_count = {0.nonce_count}\n".format(self)
    repr += "method = {0.request_method}\n".format(self)
    repr += "uri = {0.request_uri}\n".format(self)
    repr += "hash = {0.hashtype}\n".format(self)

    return repr


def usage(name):
    print("Usage: {} [tcpdump_output] [dictionary]".format(name))
    print("Note: This is not the raw packet data but the result of running 'tcpdump -A [packets]'")

if __name__ == '__main__':
    if len(sys.argv) < 3:
        usage(sys.argv[0])
        sys.exit(1)

    data = ""
    with open(sys.argv[1], 'r') as f:
        data = f.read()

    pw_dict = []
    stime = time.time()
    with open(sys.argv[2], 'r') as f:
        print("Reading passwords from {}".format(sys.argv[2]))

        gc.disable()
        for line in f:
          pw_dict.append(line)

        gc.enable()

        print("Loaded {} from dictionary in {} seconds".format(len(pw_dict), time.time() - stime))
        time.sleep(5)

    #print("Formatted tcpdump data:\n{}".format(data))

    auth_context = AuthContext(pw_dict)
    auth_context.crackPassword(data)
