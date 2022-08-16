import re
import os
import socket
import time

import numpy as np

from esi_cosim import CosimBase

def isPortOpen(port):
  sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  result = sock.connect_ex(('127.0.0.1', port))
  sock.close()
  return True if result == 0 else False

class Cosim(CosimBase):
  def __init__(self, port):
    super().__init__("PyCDESystem/schema.capnp", f"{os.uname()[1]}:{port}")
    self.ctrl = self.openEP(1001, sendType=self.schema.I1, recvType=self.schema.I1)
    self.port0 = self.openEP(1002, sendType=self.schema.I64, recvType=self.schema.I32)
    self.port1 = self.openEP(1003, sendType=self.schema.I64, recvType=self.schema.I32)
    self.result = self.openEP(1004, sendType=self.schema.I32, recvType=self.schema.I1)
    self.port0_mem = [0, 0, 0, 0, 0]
    self.port1_mem = [0, 0, 0, 0, 0]

  def run(self, a, b):
    self.ctrl.send(self.schema.I1.new_message(i=False))
    self.port0_mem = a
    self.port1_mem = b

    while self.readMsg(self.ctrl, self.schema.I1) is None:
      self.service_memories()
      time.sleep(0.01)

    result = None
    while result is None:
      result = self.readMsg(self.result, self.schema.I32)
      time.sleep(0.01)
    return result.i

  def run_checked(self, a, b):
    print(f"Computing dot product of {a} and {b}")
    result = self.run(a, b)
    dot = np.dot(np.array(a), np.array(b))
    print(f"from cosim: {result}, from numpy: {dot}")

  def service_memories(self):

    def service(mem, port):
      addr = self.readMsg(port, self.schema.I64)
      if addr is not None:
        port.send(self.schema.I64.new_message(i=mem[addr.i]))

    service(self.port0_mem, self.port0)
    service(self.port1_mem, self.port1)

portFileName = "cosim.cfg"
checkCount = 0
port = -1
while not os.path.exists(portFileName):
  time.sleep(0.05)
  checkCount += 1
  if checkCount > 200:
    raise Exception(f"Cosim never wrote cfg file: {portFileName}")

portFile = open(portFileName, "r")
for line in portFile.readlines():
  m = re.match("port: (\\d+)", line)
  if m is not None:
    port = int(m.group(1))
    portFile.close()

assert(port != -1)

checkCount = 0
while not isPortOpen(port):
  checkCount += 1
  if checkCount > 200:
    raise Exception(f"Cosim RPC port ({port}) never opened")
  time.sleep(0.05)


def rand_vec():
  return [np.random.randint(0, 100) for i in range(5)]

cosim = Cosim(port)
