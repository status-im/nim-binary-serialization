import
  serialization/formats

serializationFormat Binary,
                    mimeType = "application/octet-stream"

template supports*(_: type Binary, T: type): bool =
  false

template bin_bitsize*(size: int) {.pragma.}
template bin_len*(size: untyped) {.pragma.}
template bin_value*(size: untyped) {.pragma.}
