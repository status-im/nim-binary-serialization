import
  std/[typetraits, macros],
  stew/endians2,
  faststreams/[outputs], serialization,
  format

export outputs

type
  BinaryWriter* = object
    stream: OutputStream
    bitSize: int
    workingByte: byte
    position: int

Binary.setWriter BinaryWriter,
                 PreferredOutput = seq[byte]

proc init*(W: type BinaryWriter, stream: OutputStream,
           pretty = false, typeAnnotations = false): W =
  W(stream: stream)

proc writeValue*(w: var BinaryWriter, value: auto) =
  let it = value

  assert (value is uint8 and w.bitSize != 0) or w.position == 0 or value is object

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
      if w.bitSize > 0:
        assert w.position + w.bitSize <= 8
        let
          mask = ((1 shl w.bitSize) - 1).uint8
          masked = value and mask
          shifted = masked shl (8 - w.position - w.bitSize)
        assert masked == value
        w.workingByte = w.workingByte or shifted
        w.position.inc(w.bitSize)
        if w.position == 8:
          w.stream.write w.workingByte
          w.position = 0
          w.workingByte = 0
        return

    w.stream.write toBytes(value, bigEndian)
  elif value is enum:
    w.writeValue(E(value))
  elif value is set:
    w.writeValue(cast[E](value))
  elif value is object:
    value.enumInstanceSerializedFields(fieldName, field):
      var fieldVal = field

      when field.hasCustomPragma(bin_bitsize):
        when field isnot uint8:
          {.error: "bit_bitsize only applies to byte".}
        w.bitSize = (int)field.getCustomPragmaVal(bin_bitsize)
        assert w.bitSize in 1 ..< 8

      when field.hasCustomPragma(bin_value):
        #TODO safer conversion
        fieldVal = (type field)field.getCustomPragmaVal(bin_value)
      w.writeFieldIMPL(FieldTag[type value, fieldName], fieldVal, value)
      w.bitSize = 0

    if w.position > 0:
      w.stream.write w.workingByte
      w.position = 0
      w.workingByte = 0
  elif value is seq | array | openarray:
    for subV in value:
      w.writeValue(subV)
  else:
    {.error: "Unsupported type " & $type(value).}
