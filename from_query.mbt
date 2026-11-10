///|
pub(open) trait FromQuery {
  /// Schema for the query fields, not an OpenAPI Parameter Object.
  /// false means no query input is documented; the default {} is unconstrained.
  fn schema() -> @json.Json = _
  fn from_query(@moonback.QueryParams) -> Self raise HandlerError
}

///|
impl FromQuery with fn schema() {
  {}
}

///|
pub impl FromQuery for Unit with fn from_query(_) {
  ()
}

///|
pub impl FromQuery for Unit with fn schema() {
  @json.Json::boolean(false)
}

///|
/// Repeated parameter names keep the last value.
pub impl[T : FromString] FromQuery for Map[String, T] with fn from_query(query) {
  let values : Map[String, T] = Map([])
  for (name, value) in query.iter() {
    let parsed : T = FromString::from_string(value) catch {
      error =>
        raise QueryMismatch(
          "Invalid query parameter '\{name}': \{(error : Error)}",
        )
    }
    values[name] = parsed
  }
  values
}

///|
pub impl[T : FromString] FromQuery for Map[String, T] with fn schema() {
  { "type": "object", "additionalProperties": T::schema() }
}

///|
/// Parameter order and repeated names are preserved.
pub impl[T : FromString] FromQuery for Array[(String, T)] with fn from_query(
  query,
) {
  let values : Array[(String, T)] = []
  for (name, value) in query.iter() {
    let parsed : T = FromString::from_string(value) catch {
      error =>
        raise QueryMismatch(
          "Invalid query parameter '\{name}': \{(error : Error)}",
        )
    }
    values.push((name, parsed))
  }
  values
}

///|
pub impl[T : FromString] FromQuery for Array[(String, T)] with fn schema() {
  {
    "type": "object",
    "additionalProperties": {
      "anyOf": [T::schema(), { "type": "array", "items": T::schema() }],
    },
  }
}
