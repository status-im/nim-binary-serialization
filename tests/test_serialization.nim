import
  strutils, unittest, stew/byteutils,
  serialization/object_serialization,
  serialization/testing/generic_suite,
  ../binary_serialization

## IP
type
  Ip4Packet = object
    ihl {.bin_bitsize: 4, bin_value: (20 + it.options.len) div 4.}: uint8
    dscp {.bin_bitsize: 6.}: uint8
    ecn {.bin_bitsize: 2.}: uint8
    totalLength {.bin_value: it.payload.len + 20 + it.options.len.}: uint16
    identification: uint16
    flags {.bin_bitsize: 3.}: uint8
    # doesn't handle bitsize > 8 for now
    fragmentOffset1 {.bin_bitsize: 5.}: uint8
    fragmentOffset2: uint8
    ttl: uint8
    protocol: uint8
    headerChecksum: uint16
    sourceIpAddress: array[4, byte]
    targetIpAddress: array[4, byte]
    options {.bin_len: it.ihl * 4 - 20.}: seq[byte]
    payload {.bin_len: it.totalLength - it.ihl * 4.}: seq[byte]

  Ip6Packet = object
    # doesn't handle bitsize > 8 for now
    trafficClass1 {.bin_bitsize: 4.}: uint8
    trafficClass2 {.bin_bitsize: 4.}: uint8
    flowLabel1 {.bin_bitsize: 4.}: uint8
    flowLabel2: uint16
    payloadLength {.bin_value: it.payload.len.}: uint16
    nextHeader: uint8
    hopLimit: uint8
    sourceIpAddress: array[16, byte]
    targetIpAddress: array[16, byte]
    payload {.bin_len: it.payloadLength.}: seq[byte]

  IpPacket = object
    case version {.bin_bitsize: 4.}: uint8
    of 4: ip4Packet: Ip4Packet
    of 6: ip6Packet: Ip6Packet
    else: discard

## Yamux

type
  MsgType {.size: 2.} = enum
    Data = 0x0
    WindowUpdate = 0x1
    Ping = 0x2
    GoAway = 0x3

  MsgFlags {.size: 2.} = enum
    Syn
    Ack
    Fin
    Rst

  YamuxHeader = object
    version: uint8
    msgType: MsgType
    flags: set[MsgFlags]
    streamId: uint32
    length: uint32



suite "simple tests":
  test "Ip":
    let
      # we don't need to specify ihl & totalLength, but `==` would fail without them
      ipPacket = IpPacket(version: 4, ip4Packet: Ip4Packet(ihl: 5, totalLength: 20))
      asBin = Binary.encode(ipPacket)
      rt = Binary.decode(asBin, IpPacket)
    check $ipPacket == $rt
    check $Binary.decode("45000014dc14400037067a0fa35f87eac0a80113".hexToSeqByte(), IpPacket) ==
      $IpPacket(version: 4, ip4Packet:
        Ip4Packet(ihl: 5,
        dscp: 0, ecn: 0, totalLength: 20,
        identification: 56340, flags: 2, fragmentOffset1: 0, fragmentOffset2: 0,
        ttl: 55, protocol: 6, headerChecksum: 31247,
        sourceIpAddress: [163.byte, 95, 135, 234], targetIpAddress: [192.byte, 168, 1, 19], options: @[], payload: @[]))

  test "Yamux":
    let
      ipPacket = YamuxHeader()
      asBin = Binary.encode(ipPacket)
      rt = Binary.decode(asBin, YamuxHeader)

    check $rt == $ipPacket
