///|
pub(all) struct Headers[T](T)

///|
pub(open) trait FromHeaders {
  /// Schema for the request header fields, not an OpenAPI Header Object.
  /// false means no header input is documented; the default {} is unconstrained.
  fn schema() -> @json.Json = _
  fn from_headers(@moonback.Headers) -> Self raise HandlerError
}

///|
impl FromHeaders with fn schema() {
  {}
}

///|
pub impl FromHeaders for Unit with fn from_headers(_) {
  ()
}

///|
pub impl FromHeaders for Unit with fn schema() {
  @json.Json::boolean(false)
}

///|
pub impl FromHeaders for @moonback.Headers with fn from_headers(headers) {
  headers
}

///|
pub impl FromHeaders for @moonback.Headers with fn schema() {
  { "type": "object", "additionalProperties": { "type": "string" } }
}

///|
/// Header names are lowercase; repeated entries keep the last value.
pub impl[T : FromString] FromHeaders for Map[String, T] with fn from_headers(
  headers,
) {
  let values : Map[String, T] = {}
  for (name, value) in headers.iter() {
    let parsed : T = FromString::from_string(value) catch {
      error =>
        raise HeaderMismatch("Invalid header '\{name}': \{(error : Error)}")
    }
    values[name] = parsed
  }
  values
}

///|
pub impl[T : FromString] FromHeaders for Map[String, T] with fn schema() {
  { "type": "object", "additionalProperties": T::schema() }
}

///|
/// Preserves the entries yielded by moonback without splitting header values.
pub impl[T : FromString] FromHeaders for Array[(String, T)] with fn from_headers(
  headers,
) {
  let values : Array[(String, T)] = []
  for (name, value) in headers.iter() {
    let parsed : T = FromString::from_string(value) catch {
      error =>
        raise HeaderMismatch("Invalid header '\{name}': \{(error : Error)}")
    }
    values.push((name, parsed))
  }
  values
}

///|
pub impl[T : FromString] FromHeaders for Array[(String, T)] with fn schema() {
  {
    "type": "object",
    "additionalProperties": {
      "anyOf": [T::schema(), { "type": "array", "items": T::schema() }],
    },
  }
}

///|
pub impl[T : FromJson] FromHeaders for ViaJson[T] with fn from_headers(headers) {
  let map = Map([])
  for (name, value) in headers.iter() {
    map[name] = @json.Json::string(value)
  }
  let value : T = @json.from_json(@json.Json::object(map)) catch {
    error => raise HeaderMismatch(error.to_string())
  }
  ViaJson(value)
}
