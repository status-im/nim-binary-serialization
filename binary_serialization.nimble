packageName   = "binary_serialization"
version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "Flexible binary serialization not relying on run-time type information"
license       = "Apache License 2.0"
skipDirs      = @["tests"]

requires "nim >= 1.2.16",
         "serialization",
         "stew"
