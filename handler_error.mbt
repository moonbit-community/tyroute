///|
pub(all) suberror HandlerError {
  StringMismatch(String)
  ParamMismatch(String)
  QueryMismatch(String)
  HeaderMismatch(String)
  BodyMismatch(String)
  ResponseMismatch(String)
}

///|
pub impl Show for HandlerError with fn to_string(self) {
  match self {
    StringMismatch(message)
    | ParamMismatch(message)
    | QueryMismatch(message)
    | HeaderMismatch(message)
    | BodyMismatch(message)
    | ResponseMismatch(message) => message
  }
}

///|
pub extend HandlerError with Show::{output, to_string}
