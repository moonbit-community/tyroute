///|
pub(open) trait ToResponse {
  /// OpenAPI 3.2 payload schema. For a bodyless response this returns false;
  /// the OpenAPI response must omit content, rather than describe JSON null.
  fn schema() -> @json.Json = _
  fn to_response(Self) -> Response raise HandlerError
}

///|
impl ToResponse with fn schema() {
  {}
}

///|
pub impl ToResponse for Response with fn to_response(self) {
  self
}

///|
pub extend Response with ToResponse::{to_response}

///|
pub fn[A : @moonback.ToHeaders] Response::Response(
  status~ : Int32,
  headers~ : A,
  body? : &@io.Data,
) -> Self {
  { status, headers: headers.to_headers(), body, }
}

///|
pub impl[A : @json.ToJson] ToResponse for ViaJson[A] with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "application/json")],
    body=ToJson::to_json(self.0),
  )
}

///|
pub impl ToResponse for Unit with fn to_response(_self) {
  { status: 200, headers: @moonback.Headers::default(), body: None, }
}

///|
pub impl ToResponse for Unit with fn schema() {
  @json.Json::boolean(false)
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
pub impl ToResponse for String with fn schema() {
  { "type": "string" }
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
pub impl ToResponse for StringView with fn schema() {
  { "type": "string" }
}

///|
pub impl ToResponse for Bool with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for Bool with fn schema() {
  { "type": "boolean" }
}

///|
pub impl ToResponse for Char with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for Char with fn schema() {
  { "type": "string", "minLength": 1, "maxLength": 1 }
}

///|
pub impl ToResponse for Byte with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_int().to_string(),
  )
}

///|
pub impl ToResponse for Byte with fn schema() {
  { "type": "integer", "minimum": 0, "maximum": 255 }
}

///|
pub impl ToResponse for Int16 with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for Int16 with fn schema() {
  { "type": "integer", "minimum": -32768, "maximum": 32767 }
}

///|
pub impl ToResponse for UInt16 with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for UInt16 with fn schema() {
  { "type": "integer", "minimum": 0, "maximum": 65535 }
}

///|
pub impl ToResponse for Int32 with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for Int32 with fn schema() {
  {
    "type": "integer",
    "format": "int32",
    "minimum": -2147483648,
    "maximum": 2147483647,
  }
}

///|
pub impl ToResponse for UInt32 with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for UInt32 with fn schema() {
  { "type": "integer", "minimum": 0, "maximum": 4294967295.0 }
}

///|
pub impl ToResponse for Int64 with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for Int64 with fn schema() {
  {
    "type": "integer",
    "format": "int64",
    "minimum": @json.Json::number(
      -9223372036854775808.0,
      repr="-9223372036854775808",
    ),
    "maximum": @json.Json::number(
      9223372036854775807.0,
      repr="9223372036854775807",
    ),
  }
}

///|
pub impl ToResponse for UInt64 with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for UInt64 with fn schema() {
  {
    "type": "integer",
    "minimum": 0,
    "maximum": @json.Json::number(
      18446744073709551615.0,
      repr="18446744073709551615",
    ),
  }
}

///|
pub impl ToResponse for Float with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for Float with fn schema() {
  { "type": "number", "format": "float" }
}

///|
pub impl ToResponse for Double with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "text/plain; charset=utf-8")],
    body=self.to_string(),
  )
}

///|
pub impl ToResponse for Double with fn schema() {
  { "type": "number", "format": "double" }
}

///|
pub impl ToResponse for Bytes with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "application/octet-stream")],
    body=self,
  )
}

///|
pub impl ToResponse for Bytes with fn schema() {
  { "contentMediaType": "application/octet-stream" }
}

///|
pub impl ToResponse for BytesView with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "application/octet-stream")],
    body=self,
  )
}

///|
pub impl ToResponse for BytesView with fn schema() {
  { "contentMediaType": "application/octet-stream" }
}

///|
pub impl ToResponse for @json.Json with fn to_response(self) {
  Response(
    status=200,
    headers=[("Content-Type", "application/json")],
    body=self,
  )
}
