///|
#derive(ToJson)
priv struct User {
  id : Int32
  name : String
}

///|
impl @tyroute.ToSchema for User with fn to_schema(_ctx) {
  {
    "type": "object",
    "properties": {
      "id": { "type": "integer", "format": "int32" },
      "name": { "type": "string" },
    },
    "required": ["id", "name"],
  }
}

///|
priv enum GetUserRequest {
  Valid(Int32, String?)
  Invalid
}

///|
impl @tyroute.FromRequest for GetUserRequest with fn from_request(request) {
  guard request.params().get("id") is Some(value) else { return Invalid }
  let id = @string.parse_int(value) catch {
    Failure(_) => return Invalid
    error => raise error
  }
  Valid(id, request.query().get("name"))
}

///|
impl @tyroute.ToSchema for GetUserRequest with fn to_schema(_ctx) {
  {
    "parameters": [
      {
        "name": "id",
        "in": "path",
        "required": true,
        "schema": { "type": "integer", "format": "int32" },
      },
      { "name": "name", "in": "query", "schema": { "type": "string" } },
    ],
  }
}

///|
priv enum GetUserResponse {
  Ok(User)
  Invalid(String)
}

///|
impl @tyroute.ToResponse for GetUserResponse with fn to_response(self) {
  match self {
    Ok(user) =>
      Response(
        status=200,
        headers={ "Content-Type": "application/json" },
        body=Json(user),
      )
    Invalid(detail) =>
      Response(
        status=400,
        headers={ "Content-Type": "text/plain; charset=utf-8" },
        body=detail,
      )
  }
}

///|
impl @tyroute.ToSchema for GetUserResponse with fn to_schema(ctx) {
  {
    "200": {
      "description": "User",
      "content": {
        "application/json": {
          "schema": ctx.ref(
            "#/components/schemas/User",
            (@tyroute.Tag : @tyroute.Tag[User]),
          ),
        },
      },
    },
    "400": {
      "description": "Invalid id",
      "content": {
        "text/plain; charset=utf-8": { "schema": { "type": "string" } },
      },
    },
  }
}

///|
#warnings("-unused_async")
async fn get_user(ctx : String, request : GetUserRequest) -> GetUserResponse {
  match request {
    Valid(id, name) => Ok({ id, name: name.unwrap_or(ctx), })
    Invalid => Invalid("Invalid id")
  }
}

///|
async fn main {
  let router = @tyroute.Router()
    ..get("/users/:id", get_user, "MoonBit", schema=@tyroute.inferred())
    ..openapi("/openapi.json", title="Users API", version="1.0.0")
  let app = @moonback.App(ctx => ctx.use_(router))
  defer app.close()
  println("Listening on http://127.0.0.1:3000")
  app.serve(@moonback.listen(host="127.0.0.1", port=3000))
}
