///|
/// Convert request data into an application request value.
/// Expected validation failures should be represented in Self, not raised.
pub(open) trait FromRequest {
  async fn from_request(Request) -> Self
}

///|
pub impl FromRequest for Unit with fn from_request(_request) {
  ()
}
