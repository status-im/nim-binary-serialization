
import
  std/[tables, strutils, typetraits, macros, strformat],
  stew/[endians2, objects],
  faststreams/inputs, serialization/[formats, object_serialization, errors],
  format

export
  inputs

type
  BinaryReader* = object
    stream: InputStream
    arrayLen: int

    bitSize: int
    workingByte: byte
    remaining: int

Binary.setReader BinaryReader

proc init*(T: type BinaryReader, stream: InputStream): T =
  T(stream: stream)

proc readValue*[T](r: var BinaryReader, value: var T) =
  when sizeof(value) == 1:
    type E = uint8
  elif sizeof(value) == 2:
    type E = uint16
  elif sizeof(value) == 4:
    type E = uint32
  elif sizeof(value) == 8:
    type E = uint64

  when value is SomeUnsignedInt:
    when value is uint8:
      if r.bitSize > 0:
        let mask = ((1 shl r.bitSize) - 1).uint8
        r.remaining.dec(r.bitSize)
        value = (r.workingByte shr r.remaining) and mask
        return
    let length = sizeof(value)
    value = fromBytes(type value, r.stream.read(length), bigEndian)
  elif value is enum:
    var asUInt: E
    r.readValue(asUint)
    #TODO raise instead
    assert value.checkedEnumAssign(asUInt):
  elif value is set:
    var asUInt: E
    r.readValue(asUint)
    #TODO is this safe enough?
    value = cast[type(value)](asUInt)
  elif value is object:
    value.enumInstanceSerializedFields(fieldName, field):
      when field.hasCustomPragma(bin_len):
        let it = value
        #TODO safer conversion
        r.arrayLen = int(field.getCustomPragmaVal(bin_len))

      when field.hasCustomPragma(bin_bitsize):
        when field isnot uint8:
          {.error: "bit_bitsize only applies to byte".}
        r.bitSize = (int)field.getCustomPragmaVal(bin_bitsize)
        assert r.bitSize in 1 ..< 8

        if r.remaining == 0:
          r.workingByte = r.stream.read
          r.remaining = 8

      var vall: type(field)
      r.readValue(vall)
      field = vall
      r.bitSize = 0
  elif value is seq:
    for _ in 0 ..< r.arrayLen:
      var subValue: type(value[0])
      r.readValue(subValue)
      value.add(subValue)
  elif value is array:
    for i in 0 ..< value.len:
      r.readValue(value[i])
  else:
    {.error: "Unsupported type " & $type(value).}
