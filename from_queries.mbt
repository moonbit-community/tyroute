///|
pub(open) trait FromQueries {
  /// Schema for the query fields, not an OpenAPI Parameter Object.
  /// false means no query input is documented; the default {} is unconstrained.
  fn schema() -> @json.Json = _
  fn from_queries(@moonback.QueryParams) -> Self raise HandlerError
}

///|
impl FromQueries with fn schema() {
  {}
}

///|
pub impl FromQueries for Unit with fn from_queries(_) {
  ()
}

///|
pub impl FromQueries for Unit with fn schema() {
  @json.Json::boolean(false)
}

///|
/// Repeated parameter names keep the last value.
pub impl[T : FromString] FromQueries for Map[String, T] with fn from_queries(
  query,
) {
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
pub impl[T : FromString] FromQueries for Map[String, T] with fn schema() {
  { "type": "object", "additionalProperties": T::schema() }
}

///|
/// Parameter order and repeated names are preserved.
pub impl[T : FromString] FromQueries for Array[(String, T)] with fn from_queries(
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
pub impl[T : FromString] FromQueries for Array[(String, T)] with fn schema() {
  {
    "type": "object",
    "additionalProperties": {
      "anyOf": [T::schema(), { "type": "array", "items": T::schema() }],
    },
  }
}
