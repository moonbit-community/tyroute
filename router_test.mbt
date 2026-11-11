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
  ctx : String,
  id : Int32,
  query : @tyroute.ViaJson[AsyncUserQuery],
  _headers : Unit,
) -> @tyroute.ViaJson[AsyncUser] {
  @async.sleep(1)
  @tyroute.ViaJson({ id, name: query.0.name.unwrap_or(ctx), })
}

///|
async fn async_create_user(
  status : Int32,
  _params : Unit,
  _query : Unit,
  _headers : Unit,
  body : @tyroute.ViaJson[AsyncUser],
) -> (@tyroute.StatusCode, @tyroute.ViaJson[AsyncUser]) {
  @async.sleep(1)
  (@tyroute.StatusCode(status), body)
}

///|
priv struct HandlerContext {
  name : String
  calls : Ref[Int32]
}

///|
async fn context_read(
  ctx : HandlerContext,
  id : Int32,
  _query : Unit,
  _headers : Unit,
) -> @tyroute.Response {
  @async.sleep(1)
  ctx.calls.val += 1
  @tyroute.Response(
    status=200,
    headers={ "X-Context": ctx.name },
    body=id.to_string(),
  )
}

///|
async fn context_write(
  ctx : HandlerContext,
  id : Int32,
  _query : Unit,
  _headers : Unit,
  body : Json,
) -> @tyroute.Response {
  @async.sleep(1)
  ctx.calls.val += 1
  let payload : Json = { "id": id, "body": body }
  @tyroute.Response(status=200, headers={ "X-Context": ctx.name }, body=payload)
}

///|
async test "all HTTP methods and add preserve typed handler contexts" {
  @async.with_timeout(5000, () => {
    @async.with_task_group(group => {
      let calls = Ref(0)
      let read_ctx : HandlerContext = { name: "read", calls, }
      let write_ctx : HandlerContext = { name: "write", calls, }
      let router = @tyroute.Router()
        ..get("/context/:id", context_read, read_ctx)
        ..head("/context/:id", context_read, read_ctx)
        ..options("/context/:id", context_read, read_ctx)
        ..post("/context/:id", context_write, write_ctx)
        ..put("/context/:id", context_write, write_ctx)
        ..patch("/context/:id", context_write, write_ctx)
        ..delete("/context/:id", context_write, write_ctx)
        ..add("/direct/:id", Post, context_write, { name: "direct", calls, })
      let app = @moonback.App(ctx => ctx.use_(router))
      defer app.close()
      let server = @moonback.listen(host="127.0.0.1", port=0)
      group.spawn_bg(no_wait=true, () => app.serve(server))
      let base = "http://127.0.0.1:\{server.addr.port()}"
      let methods : Array[@http.RequestMethod] = [Get, Head, Options]
      for meth in methods {
        let (response, body) = @http.request("\{base}/context/42", meth, {}, "")
        assert_eq(response.code, 200)
        assert_eq(response.headers.get("X-Context"), Some("read"))
        assert_eq(body.text(), if meth == Head { "" } else { "42" })
      }
      let requests : Array[(String, @http.RequestMethod, String)] = [
        ("/context/42", Post, "write"),
        ("/context/42", Put, "write"),
        ("/context/42", Patch, "write"),
        ("/context/42", Delete, "write"),
        ("/direct/42", Post, "direct"),
      ]
      for (path, meth, name) in requests {
        let (response, body) = @http.request(
          "\{base}\{path}",
          meth,
          { "Content-Type": "application/json" },
          "{\"value\":7}",
        )
        assert_eq(response.code, 200)
        assert_eq(response.headers.get("X-Context"), Some(name))
        assert_eq(body.json(), { "id": 42, "body": { "value": 7 } })
      }
      assert_eq(calls.val, 8)
    })
  })
}

///|
async test "async handlers extract inputs and encode responses across suspension" {
  @async.with_timeout(5000, () => {
    @async.with_task_group(group => {
      let router = @tyroute.Router()
        ..get("/users/:id", async_get_user, "MoonBit")
        ..post("/users", async_create_user, 201)
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
      let (response, body) = @http.request("\{base}/users/42", Get, {}, "")
      assert_eq(response.code, 200)
      assert_eq(body.json(), { "id": 42, "name": "MoonBit" })
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
async test "lazy body extraction starts in the handler and caches the typed value" {
  @async.with_timeout(5000, () => {
    @async.with_task_group(group => {
      async fn handle(
        _ctx : Unit,
        mode : String,
        _query : Unit,
        _headers : Unit,
        body : @async.Lazy[Json],
      ) -> @tyroute.Response {
        if mode == "reject" {
          return @tyroute.Response(status=401)
        }
        let value = body.wait()
        assert_eq(body.wait(), value)
        @tyroute.Response(status=200, body=value)
      }
      let router = @tyroute.Router()..post("/lazy/:mode", handle, ())
      let app = @moonback.App(ctx => ctx.use_(router))
      defer app.close()
      let server = @moonback.listen(host="127.0.0.1", port=0)
      group.spawn_bg(no_wait=true, () => app.serve(server))
      let base = "http://127.0.0.1:\{server.addr.port()}"
      let (response, _) = @http.request(
        "\{base}/lazy/reject",
        Post,
        {},
        "invalid json",
      )
      assert_eq(response.code, 401)
      let (response, body) = @http.request(
        "\{base}/lazy/accept",
        Post,
        {},
        "{\"value\":7}",
      )
      assert_eq(response.code, 200)
      assert_eq(body.json(), { "value": 7 })
      let (response, _) = @http.request(
        "\{base}/lazy/accept",
        Post,
        {},
        "invalid json",
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
async test "response headers can be omitted with or without a body" {
  @async.with_timeout(5000, () => {
    @async.with_task_group(group => {
      async fn response(
        _ctx : Unit,
        mode : String,
        _query : Unit,
        _headers : Unit,
      ) -> @tyroute.Response {
        @async.sleep(1)
        match mode {
          "empty" => @tyroute.Response(status=204)
          "body" => @tyroute.Response(status=202, body="accepted")
          _ =>
            @tyroute.Response(
              status=201,
              headers={ "X-Response": "created" },
              body="created",
            )
        }
      }
      let router = @tyroute.Router()..get("/response/:mode", response, ())
      let app = @moonback.App(ctx => ctx.use_(router))
      defer app.close()
      let server = @moonback.listen(host="127.0.0.1", port=0)
      group.spawn_bg(no_wait=true, () => app.serve(server))
      let base = "http://127.0.0.1:\{server.addr.port()}"
      let (response, body) = @http.request(
        "\{base}/response/empty",
        Get,
        {},
        "",
      )
      assert_eq(response.code, 204)
      assert_eq(body.text(), "")
      let (response, body) = @http.request("\{base}/response/body", Get, {}, "")
      assert_eq(response.code, 202)
      assert_eq(body.text(), "accepted")
      let (response, body) = @http.request(
        "\{base}/response/headers",
        Get,
        {},
        "",
      )
      assert_eq(response.code, 201)
      assert_eq(response.headers.get("X-Response"), Some("created"))
      assert_eq(body.text(), "created")
    })
  })
}

///|
async test "async handler errors retain extraction handling and middleware propagation" {
  @async.with_timeout(5000, () => {
    @async.with_task_group(group => {
      async fn invalid(
        _ctx : Unit,
        _params : Unit,
        _query : Unit,
        _headers : Unit,
      ) -> String {
        @async.sleep(1)
        raise @tyroute.QueryMismatch("invalid query")
      }
      async fn unavailable(
        _ctx : Unit,
        _params : Unit,
        _query : Unit,
        _headers : Unit,
      ) -> String {
        @async.sleep(1)
        raise Unavailable
      }
      let router = @tyroute.Router()
        ..get("/invalid", invalid, ())
        ..get("/unavailable", unavailable, ())
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
