///|
struct Response {
  status : Int32
  headers : @moonback.Headers
  body : &@io.Data?
}

///|
pub fn Response::Response(
  status~ : Int32,
  headers~ : &@moonback.ToHeaders = @moonback.Headers::default(),
  body? : &@io.Data,
) -> Self {
  let headers = headers.to_headers()
  { status, headers, body, }
}
