#!/usr/bin/python3

import capnp


class CosimBase:
  """Provides a base class for cosim tests"""

  def __init__(self, schemaPath, hostPort):
    """Load the schema and connect to the RPC server"""
    self.schema = capnp.load(schemaPath)
    self.rpc_client = capnp.TwoPartyClient(hostPort)
    self.cosim = self.rpc_client.bootstrap().cast_as(self.schema.CosimDpiServer)

  def openEP(self, epNum=1, sendType=None, recvType=None):
    """Open the endpoint, optionally checking the send and recieve types"""
    ifaces = self.cosim.list().wait().ifaces
    for iface in ifaces:
      if iface.endpointID == epNum:
        # Optionally check that the type IDs match.
        print(f"SendTypeId: {iface.sendTypeID:x}")
        print(f"RecvTypeId: {iface.recvTypeID:x}")
        if sendType is not None:
          assert (iface.sendTypeID == sendType.schema.node.id)
        if recvType is not None:
          assert (iface.recvTypeID == recvType.schema.node.id)

        openResp = self.cosim.open(iface).wait()
        assert openResp.iface is not None
        return openResp.iface
    assert False, "Could not find specified EndpointID"

  def readMsg(self, ep, expectedType):
    """Try to read, return None if a message was not immediately available"""
    recvResp = ep.recv(False).wait()
    if not recvResp.hasData:
      return None
    return recvResp.resp.as_struct(expectedType)
