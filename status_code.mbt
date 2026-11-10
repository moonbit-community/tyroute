///|
pub(all) struct StatusCode(Int32)

///|
pub impl ToResponse for StatusCode with fn to_response(self) {
  { status: self.0, headers: @moonback.Headers::default(), body: None, }
}

///|
pub impl[A : ToResponse] ToResponse for (StatusCode, A) with fn to_response(
  self,
) {
  let res : Response = self.1.to_response()
  { ..res, status: self.0.0, }
}

///|
pub impl ToResponse for StatusCode with fn schema() {
  @json.Json::boolean(false)
}

///|
pub impl[A : ToResponse] ToResponse for (StatusCode, A) with fn schema() {
  A::schema()
}
