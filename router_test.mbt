///|
#derive(FromJson, ToJson)
priv struct AsyncUser {
  id : Int32
  name : String
}

///|
#derive(FromJson)
priv struct AsyncUserQuery {
  name : String?
}

///|
async fn async_get_user(
  id : Int32,
  query : @tyroute.ViaJson[AsyncUserQuery],
  _headers : Unit,
) -> @tyroute.ViaJson[AsyncUser] {
  @async.sleep(1)
  @tyroute.ViaJson({ id, name: query.0.name.unwrap_or("MoonBit"), })
}

///|
async fn async_create_user(
  _params : Unit,
  _query : Unit,
  _headers : Unit,
  body : @tyroute.ViaJson[AsyncUser],
) -> (@tyroute.StatusCode, @tyroute.ViaJson[AsyncUser]) {
  @async.sleep(1)
  (@tyroute.StatusCode(201), body)
}

///|
async test "async handlers extract inputs and encode responses across suspension" {
  @async.with_timeout(5000, () => {
    @async.with_task_group(group => {
      let router = @tyroute.Router()
        ..get("/users/:id", async_get_user)
        ..post("/users", async_create_user)
      let app = @moonback.App(ctx => ctx.use_(router))
      defer app.close()
      let server = @moonback.listen(host="127.0.0.1", port=0)
      group.spawn_bg(no_wait=true, () => app.serve(server))
      let base = "http://127.0.0.1:\{server.addr.port()}"
      let (response, body) = @http.request(
        "\{base}/users/42?name=Alice",
        Get,
        {},
        "",
      )
      assert_eq(response.code, 200)
      assert_eq(response.headers.get("Content-Type"), Some("application/json"))
      assert_eq(body.json(), { "id": 42, "name": "Alice" })
      let (response, body) = @http.request(
        "\{base}/users",
        Post,
        { "Content-Type": "application/json" },
        "{\"id\":7,\"name\":\"Bob\"}",
      )
      assert_eq(response.code, 201)
      assert_eq(body.json(), { "id": 7, "name": "Bob" })
      let (response, _) = @http.request(
        "\{base}/users/not-an-integer",
        Get,
        {},
        "",
      )
      assert_eq(response.code, 400)
    })
  })
}

///|
priv suberror AsyncHandlerFailure {
  Unavailable
}

///|
async test "async handler errors retain extraction handling and middleware propagation" {
  @async.with_timeout(5000, () => {
    @async.with_task_group(group => {
      async fn invalid(
        _params : Unit,
        _query : Unit,
        _headers : Unit,
      ) -> String {
        @async.sleep(1)
        raise @tyroute.QueryMismatch("invalid query")
      }
      async fn unavailable(
        _params : Unit,
        _query : Unit,
        _headers : Unit,
      ) -> String {
        @async.sleep(1)
        raise Unavailable
      }
      let router = @tyroute.Router()
        ..get("/invalid", invalid)
        ..get("/unavailable", unavailable)
      let app = @moonback.App(ctx => {
        ctx.add_middleware(
          @moonback.Middleware(next => {
            (req, res) => {
              next(req, res) catch {
                AsyncHandlerFailure::Unavailable =>
                  res.send_json({ "detail": "Unavailable" }, status=503)
                error => raise error
              }
            }
          }),
        )
        ctx.use_(router)
      })
      defer app.close()
      let server = @moonback.listen(host="127.0.0.1", port=0)
      group.spawn_bg(no_wait=true, () => app.serve(server))
      let base = "http://127.0.0.1:\{server.addr.port()}"
      let (response, body) = @http.request("\{base}/invalid", Get, {}, "")
      assert_eq(response.code, 400)
      assert_true(body.text().contains("invalid query"))
      let (response, body) = @http.request("\{base}/unavailable", Get, {}, "")
      assert_eq(response.code, 503)
      assert_eq(body.json(), { "detail": "Unavailable" })
    })
  })
}
