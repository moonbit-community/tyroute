///|
#derive(FromJson, ToJson)
struct User {
  id : Int32
  name : String
}

///|
#derive(FromJson)
struct UserQuery {
  name : String?
}

///|
async fn get_user(
  ctx : String,
  id : Int32,
  query : @tyroute.ViaJson[UserQuery],
  _headers : Unit,
) -> @tyroute.ViaJson[User] {
  let name = query.0.name.unwrap_or(ctx)
  @tyroute.ViaJson({ id, name, })
}

///|
async fn create_user(
  _ctx : Unit,
  _ : Unit,
  _ : Unit,
  _ : Unit,
  body : @tyroute.ViaJson[User],
) -> (@tyroute.StatusCode, @tyroute.ViaJson[User]) {
  (@tyroute.StatusCode(201), body)
}

///|
async fn main {
  let router = @tyroute.Router()
    ..openapi("/openapi.json", title="Users API", version="1.0.0")
    ..get("/users/:id", get_user, "MoonBit")
    ..post("/users", create_user, ())
  let app = @moonback.App(ctx => ctx.use_(router))
  defer app.close()
  println("Listening on http://127.0.0.1:3000")
  app.serve(@moonback.listen(host="127.0.0.1", port=3000))
}
