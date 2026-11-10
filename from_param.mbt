///|
/// Parameters are consumed from the end of the array, including tuple elements.
pub(open) trait FromParam {
  /// OpenAPI 3.2 schema for the decoded capture value. Parameter names and
  /// required flags belong to the route's OpenAPI Parameter Objects.
  fn schema() -> @json.Json = _
  fn from_param(Array[(StringView, StringView)]) -> Self raise HandlerError
}

///|
impl FromParam with fn schema() {
  {}
}

///|
pub impl FromParam for Unit with fn from_param(_) {
  ()
}

///|
pub impl FromParam for Unit with fn schema() {
  @json.Json::boolean(false)
}

///|
pub impl[A : FromString, B : FromString] FromParam for (A, B) with fn from_param(
  arr,
) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let a : A = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let b : B = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  (a, b)
}

///|
pub impl[A : FromString, B : FromString] FromParam for (A, B) with fn schema() {
  {
    "type": "array",
    "prefixItems": [A::schema(), B::schema()],
    "minItems": 2,
    "maxItems": 2,
  }
}

///|
pub impl[A : FromString, B : FromString, C : FromString] FromParam for (A, B, C) with fn from_param(
  arr,
) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let a : A = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let b : B = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let c : C = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  (a, b, c)
}

///|
pub impl[A : FromString, B : FromString, C : FromString] FromParam for (A, B, C) with fn schema() {
  {
    "type": "array",
    "prefixItems": [A::schema(), B::schema(), C::schema()],
    "minItems": 3,
    "maxItems": 3,
  }
}

///|
pub impl[A : FromString, B : FromString, C : FromString, D : FromString] FromParam for (
  A,
  B,
  C,
  D,
) with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let a : A = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let b : B = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let c : C = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let d : D = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  (a, b, c, d)
}

///|
pub impl[A : FromString, B : FromString, C : FromString, D : FromString] FromParam for (
  A,
  B,
  C,
  D,
) with fn schema() {
  {
    "type": "array",
    "prefixItems": [A::schema(), B::schema(), C::schema(), D::schema()],
    "minItems": 4,
    "maxItems": 4,
  }
}

///|
pub impl[
  A : FromString,
  B : FromString,
  C : FromString,
  D : FromString,
  E : FromString,
] FromParam for (A, B, C, D, E) with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let a : A = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let b : B = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let c : C = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let d : D = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let e : E = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  (a, b, c, d, e)
}

///|
pub impl[
  A : FromString,
  B : FromString,
  C : FromString,
  D : FromString,
  E : FromString,
] FromParam for (A, B, C, D, E) with fn schema() {
  {
    "type": "array",
    "prefixItems": [
      A::schema(),
      B::schema(),
      C::schema(),
      D::schema(),
      E::schema(),
    ],
    "minItems": 5,
    "maxItems": 5,
  }
}

///|
pub impl[
  A : FromString,
  B : FromString,
  C : FromString,
  D : FromString,
  E : FromString,
  F : FromString,
] FromParam for (A, B, C, D, E, F) with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let a : A = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let b : B = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let c : C = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let d : D = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let e : E = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  let f : F = FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
  (a, b, c, d, e, f)
}

///|
pub impl[
  A : FromString,
  B : FromString,
  C : FromString,
  D : FromString,
  E : FromString,
  F : FromString,
] FromParam for (A, B, C, D, E, F) with fn schema() {
  {
    "type": "array",
    "prefixItems": [
      A::schema(),
      B::schema(),
      C::schema(),
      D::schema(),
      E::schema(),
      F::schema(),
    ],
    "minItems": 6,
    "maxItems": 6,
  }
}

///|
pub impl FromParam for String with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for String with fn schema() {
  { "type": "string" }
}

///|
pub impl FromParam for StringView with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for StringView with fn schema() {
  { "type": "string" }
}

///|
pub impl FromParam for Bool with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for Bool with fn schema() {
  { "type": "boolean" }
}

///|
pub impl FromParam for Char with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for Char with fn schema() {
  { "type": "string", "minLength": 1, "maxLength": 1 }
}

///|
pub impl FromParam for Int32 with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for Int32 with fn schema() {
  {
    "type": "integer",
    "format": "int32",
    "minimum": -2147483648,
    "maximum": 2147483647,
  }
}

///|
pub impl FromParam for UInt32 with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for UInt32 with fn schema() {
  { "type": "integer", "minimum": 0, "maximum": 4294967295.0 }
}

///|
pub impl FromParam for Int64 with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for Int64 with fn schema() {
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
pub impl FromParam for UInt64 with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for UInt64 with fn schema() {
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
pub impl FromParam for Float with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for Float with fn schema() {
  { "type": "number", "format": "float" }
}

///|
pub impl FromParam for Double with fn from_param(arr) {
  guard arr.pop() is Some((name, value)) else {
    raise ParamMismatch("Missing path parameter")
  }
  FromString::from_string(value) catch {
    error =>
      raise ParamMismatch(
        "Invalid path parameter '\{name}': \{(error : Error)}",
      )
  }
}

///|
pub impl FromParam for Double with fn schema() {
  { "type": "number", "format": "double" }
}
