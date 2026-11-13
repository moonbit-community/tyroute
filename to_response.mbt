///|
/// Convert an application response value into an HTTP response.
pub(open) trait ToResponse {
  fn to_response(Self) -> Response
}

///|
pub impl ToResponse for Unit with fn to_response(_self) {
  { status: 200, headers: @moonback.Headers::default(), body: None, }
}

///|
pub impl ToResponse for String with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self,
  )
}

///|
pub impl ToResponse for StringView with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self,
  )
}

///|
pub impl ToResponse for @json.Json with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "application/json")],
    body=self,
  )
}
