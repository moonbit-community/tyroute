///|
pub(open) trait FromBody {
  /// Schema for the request body; the default is unconstrained.
  /// false means no request body is documented.
  fn schema() -> @json.Json = _
  async fn from_body(@moonback.RequestBody) -> Self
}

///|
impl FromBody with fn schema() {
  {}
}

///|
pub impl FromBody for Unit with fn from_body(_) {
  ()
}

///|
pub impl FromBody for Unit with fn schema() {
  @json.Json::boolean(false)
}

///|
pub impl FromBody for @json.Json with fn from_body(body) {
  let data : &@io.Data = body.binary()
  data.json() catch {
    error => raise BodyMismatch(error.to_string())
  }
}

///|
pub impl[T : FromJson] FromBody for ViaJson[T] with fn from_body(body) {
  let json : @json.Json = FromBody::from_body(body)
  let value : T = @json.from_json(json) catch {
    error => raise BodyMismatch(error.to_string())
  }
  ViaJson(value)
}

///|
pub extend ViaJson with FromBody::{from_body}
