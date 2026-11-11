name = "moonbit-community/tyroute"

version = "0.3.1"

readme = "README.mbt.md"

license = "Apache-2.0"

repository = "https://github.com/moonbit-community/tyroute"

description = "Typed request extraction, responses, and OpenAPI export for MoonBack."

options(
  preferred_target: "wasm",
)

import {
  "moonbitlang/moonback@0.8.9",
  "moonbitlang/async@0.22.5",
}
