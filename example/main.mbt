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
fn get_user(
  id : Int32,
  query : @tyroute.ViaJson[UserQuery],
  _headers : Unit,
) -> @tyroute.ViaJson[User] {
  let name = query.0.name.unwrap_or("MoonBit")
  @tyroute.ViaJson({ id, name, })
}

///|
fn create_user(
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
    ..get("/users/:id", get_user)
    ..post("/users", create_user)
  let document = router.openapi(title="Users API", version="1.0.0")
  let app = @moonback.App(ctx => {
    ctx.use_(router)
    ctx.get("/openapi.json", (_request, response) => {
      response.send_json(document)
    })
  })
  defer app.close()
  let server = @moonback.listen(host="127.0.0.1", port=3000)
  println("Listening on http://127.0.0.1:3000")
  app.serve(server)
}
