///|
pub(open) trait FromString {
  /// OpenAPI 3.2 schema for the decoded value; the default is unconstrained.
  fn schema() -> @json.Json = _
  fn from_string(StringView) -> Self raise HandlerError
}

///|
impl FromString with fn schema() {
  {}
}

///|
pub impl FromString for String with fn from_string(value) {
  value.to_owned()
}

///|
pub impl FromString for String with fn schema() {
  { "type": "string" }
}

///|
pub impl FromString for StringView with fn from_string(value) {
  value
}

///|
pub impl FromString for StringView with fn schema() {
  { "type": "string" }
}

///|
pub impl FromString for Bool with fn from_string(value) {
  @string.parse_bool(value) catch {
    error => raise StringMismatch(error.to_string())
  }
}

///|
pub impl FromString for Bool with fn schema() {
  { "type": "boolean" }
}

///|
pub impl FromString for Char with fn from_string(value) {
  guard value is [char] else {
    raise StringMismatch("Expected a single character")
  }
  char
}

///|
pub impl FromString for Char with fn schema() {
  { "type": "string", "minLength": 1, "maxLength": 1 }
}

///|
pub impl FromString for Int32 with fn from_string(value) {
  @string.parse_int(value) catch {
    error => raise StringMismatch(error.to_string())
  }
}

///|
pub impl FromString for Int32 with fn schema() {
  {
    "type": "integer",
    "format": "int32",
    "minimum": -2147483648,
    "maximum": 2147483647,
  }
}

///|
pub impl FromString for UInt32 with fn from_string(value) {
  @string.parse_uint(value) catch {
    error => raise StringMismatch(error.to_string())
  }
}

///|
pub impl FromString for UInt32 with fn schema() {
  { "type": "integer", "minimum": 0, "maximum": 4294967295.0 }
}

///|
pub impl FromString for Int64 with fn from_string(value) {
  @string.parse_int64(value) catch {
    error => raise StringMismatch(error.to_string())
  }
}

///|
pub impl FromString for Int64 with fn schema() {
  {
    "type": "integer",
    "format": "int64",
    "minimum": @json.Json::number(
      -9223372036854775808.0,
      repr="-9223372036854775808",
    ),
    "maximum": @json.Json::number(
      9223372036854775807.0,
      repr="9223372036854775807",
    ),
  }
}

///|
pub impl FromString for UInt64 with fn from_string(value) {
  @string.parse_uint64(value) catch {
    error => raise StringMismatch(error.to_string())
  }
}

///|
pub impl FromString for UInt64 with fn schema() {
  {
    "type": "integer",
    "minimum": 0,
    "maximum": @json.Json::number(
      18446744073709551615.0,
      repr="18446744073709551615",
    ),
  }
}

///|
pub impl FromString for Float with fn from_string(value) {
  let parsed = @string.parse_double(value) catch {
    error => raise StringMismatch(error.to_string())
  }
  let result = Float::from_double(parsed)
  guard !parsed.is_finite() || result.is_finite() else {
    raise StringMismatch("Float is out of range")
  }
  result
}

///|
pub impl FromString for Float with fn schema() {
  { "type": "number", "format": "float" }
}

///|
pub impl FromString for Double with fn from_string(value) {
  @string.parse_double(value) catch {
    error => raise StringMismatch(error.to_string())
  }
}

///|
pub impl FromString for Double with fn schema() {
  { "type": "number", "format": "double" }
}

///|
pub impl[A : FromJson] FromString for ViaJson[A] with fn from_string(value) {
  try {
    let parsed = @json.parse(value)
    let decoded : A = @json.from_json(parsed)
    ViaJson(decoded)
  } catch {
    error => raise StringMismatch(error.to_string())
  }
}
