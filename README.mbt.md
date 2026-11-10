# tyroute

Typed request extraction, responses, and OpenAPI 3.2 export for
[MoonBack](https://github.com/moonbitlang/moonback).

The module is `moonbit-community/tyroute`; its root package is `@tyroute`.
It uses MoonBack 0.8.9 and moonbitlang/async 0.22.5. The default target is
`wasm`; the HTTP example supports both `wasm` and `native`.

## Use with MoonBack

In your application's `moon.pkg`, import:

```moonbit nocheck
import {
  "moonbit-community/tyroute",
  "moonbitlang/moonback",
  "moonbitlang/async",
  "moonbitlang/core/json",
}

options("is-main": true)
```

The corresponding modules must also be dependencies in your `moon.mod`.
Set `options(preferred_target: "wasm")` there.

Put the following code in the application's `main.mbt`:

```mbt check
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
  _params : Unit,
  _query : Unit,
  _headers : Unit,
  body : @tyroute.ViaJson[User],
) -> (@tyroute.StatusCode, @tyroute.ViaJson[User]) {
  (@tyroute.StatusCode(201), body)
}

///|
async fn serve() -> Unit {
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
```

The handlers and `serve` function above are compiled as part of this README.
The `main` entry point belongs to the application package.

`Router` implements MoonBack's `Extension` trait. `ctx.use_(router)` registers
its routes in the app, where they can coexist with MoonBack routes.

Run the bundled example from the tyroute module directory:

```sh
moon run example
```

Its source is in [`example/main.mbt`](example/main.mbt). For a separate
application, run `moon run .` in its directory.

Then try:

```sh
curl 'http://127.0.0.1:3000/users/42?name=MoonBit'
curl -i -X POST http://127.0.0.1:3000/users \
  -H 'Content-Type: application/json' \
  -d '{"id":42,"name":"MoonBit"}'
curl http://127.0.0.1:3000/openapi.json
```

The GET returns `200` with `{"id":42,"name":"MoonBit"}`. The POST decodes
the JSON body into `User` and returns it with status `201`.

## Handler arguments and responses

GET, HEAD, and OPTIONS handlers take path parameters, query parameters, and
headers, in that order. POST, PUT, PATCH, and DELETE handlers also take a
fourth argument for the body. Use `Unit` for an input the handler does not need.

Path captures use MoonBack's `:name` syntax. A tuple such as `(String, Int)`
extracts two captures in path order. Query and header maps use `FromString`
to parse their values. `ViaJson[T]` decodes JSON bodies through `FromJson` and
encodes JSON responses through `ToJson`.

Custom types can implement `FromParam`, `FromQuery`, `FromHeaders`,
`FromBody`, and `ToResponse`. Each trait has a default unconstrained
`schema()` that custom types can override.

## OpenAPI

`router.openapi(title="My API", version="1.0.0")` returns an OpenAPI 3.2
JSON document without calling the handlers. It preserves whole-query schemas,
including combinations such as `anyOf`, through an `in: querystring` parameter.
Pass `components=...` when custom schemas reference local components.

`FromJson` and `ToJson` do not provide field schemas, so `ViaJson[T]` uses the
unconstrained default. The current export uses `default` responses and `*/*`
media types because the schema interface does not declare status codes or
media types.

## Development

Run these commands from this directory. `README.md` links to this file, and
the MoonBit example is checked with the package.

```sh
moon check
moon test
moon fmt
moon info
```
