///|
struct Response {
  status : Int32
  headers : @moonback.Headers
  body : &@io.Data?
}
