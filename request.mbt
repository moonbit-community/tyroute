///|
/// An opaque wrapper exposing request data through forwarding methods.
struct Request(@moonback.Request)

///|
pub fn Request::params(self : Request) -> Map[StringView, StringView] {
  self.0.params
}

///|
pub fn Request::query(self : Request) -> @moonback.QueryParams {
  self.0.query()
}

///|
pub fn Request::headers(self : Request) -> @moonback.Headers {
  self.0.headers
}

///|
pub fn Request::body(self : Request) -> @moonback.RequestBody {
  self.0.body
}
