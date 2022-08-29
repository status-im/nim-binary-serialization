# nim-binary-serialization

Binary packed serialization compatible with the [nim-serialization](https://github.com/status-im/nim-serialization) framework.

## Usage

```nim
type
  Example = object
    first: uint8
    second: uint16

let ex = Example(first: 5.uint8, second: 12.uint16)
assert Binary.encode(ex) == @[5.uint8, 0, 12]

type
  SeqHolder = object
    # bin_value is used during encoding instead of the actual value
    seqLength {.bin_value: it.vals.len.}: uint8
    # bin_len is the length of the sequence in element, used during decoding
    vals {.bin_len: it.seqLength.}: seq[Example]

assert Binary.encode(SeqHolder(vals: @[ex, ex])) == @[2.uint8, 5, 0, 12, 5, 0, 12]

type
  ByteSharing = object
    a {.bin_bitsize: 3.}: uint8
    b {.bin_bitsize: 5.}: uint8

assert Binary.encode(ByteSharing(a: 2.uint8, b: 4.uint8)) == @[68.uint8]
```

You can find real examples in the tests (including IP frames, Yamux header, more to come)

## License

Licensed and distributed under either of

* MIT license: [LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT

or

* Apache License, Version 2.0, ([LICENSE-APACHEv2](LICENSE-APACHEv2) or http://www.apache.org/licenses/LICENSE-2.0)

at your option. These files may not be copied, modified, or distributed except according to those terms.
