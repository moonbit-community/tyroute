# Handlers and HTTP contracts

Every route method takes a path, an `async (Ctx, Request) -> Response` handler,
and its context, in that order. `Router::add` also takes the HTTP method between
the path and handler. Request and response here are application types implementing
`FromRequest` and `ToResponse`.

```mbt nocheck
let router = @tyroute.Router()
  ..get("/users/:id", get_user, pool)
  ..post("/users", create_user, pool)
```

## Request conversion and failures

`FromRequest::from_request` asynchronously receives `@tyroute.Request`, an opaque
wrapper around the original MoonBack request. Use `params()`, `query()`,
`headers()`, and `body()` to access its data. `query()` forwards MoonBack's
`QueryParams`, preserving decoding, repeated names, and request order; `get`
returns the first value and `get_all` returns all values for a name. Implement
conversion manually; deriving `FromJson` does not register a request converter.
The library provides an implementation for `Unit` that ignores the request.

Represent expected validation failures in the request type, for example
`GetUserRequest::{Valid(Int32), Invalid}`. The handler maps those values into its
response enum; `ToResponse` chooses the status, headers, and body. The router does
not catch validation errors or generate an automatic 400/500 response.
Unexpected errors raised by request conversion or the handler propagate through
MoonBack middleware. `ToResponse::to_response` is synchronous and does not raise.

For deferred reads, a request field can hold `@async.Lazy[ConcreteType]`. Create
the lazy value inside `from_request`, with reading, decoding, and validation in
its closure. The handler waits for a typed value only when needed. Encode
expected decoding failures in that concrete type too. Reading is then skipped
when the handler returns early, and repeated waits reuse the result.

`Response(status~, headers?, body?)` accepts MoonBack-compatible headers and
`io.Data` bodies. Set Content-Type explicitly for custom responses. Built-in
`ToResponse` implementations return 200: Unit has no body, String and StringView
use `text/plain; charset=utf-8`, and JSON uses `application/json`.
HEAD always suppresses the body.

See [the complete example](../example/main.mbt) for manual conversion and a
response enum with distinct success and validation responses.

## Schema components and OpenAPI

`FromRequest` and `ToResponse` only perform conversion. Pass
`schema=@tyroute.inferred()` to a route method to opt into a route contract:

```mbt nocheck
let router = @tyroute.Router()
  ..get("/users/:id", get_user, pool, schema=@tyroute.inferred())
```

`inferred()` derives its `Req` and `Res` type arguments from the handler and
requires both types to implement `ToSchema`. It stores their schema generators;
they run during OpenAPI export, sharing one `SchemaContext` per document.
`RouteSchema[Req, Res]` prevents attaching a contract for different types.
The `add`, `get`, `post`, `put`, `patch`, `delete`, and `head` methods accept the
same optional schema argument.

For the request type, `ToSchema::to_schema` returns an OpenAPI operation object
containing input descriptions such as `parameters`, `requestBody`, and `security`.
It may also include operation metadata such as `summary`, but must not include
`responses`. `Unit` supplies an empty request contract (`{}`).
For the response type, it returns a nonempty OpenAPI responses
object keyed by status, status range, or `default`, with a description for each
response. Parameter and response references must resolve to local components
registered through `ctx.ref`.

Routes without a contract need no `ToSchema` implementations. Their responses
use an undocumented `default` entry. Export fills in missing path captures with
unconstrained schemas and normalizes capture names across matching path shapes.
Catch-all parameters have `x-moonback-catch-all: true`. HEAD response contracts
omit `content` without modifying shared components.

`generate_openapi(title~, version~)` exports OpenAPI 3.2.1.
`openapi("/openapi.json", title~, version~)` serves it through MoonBack.

`ToSchema::to_schema(ctx) -> Json` also describes reusable components.
`ctx.ref("#/components/schemas/User", (Tag : Tag[User]))` returns a `$ref` and
collects the definition from User's ToSchema implementation. Each reference is
generated once within a context, including recursive definitions. Other groups,
such as `securitySchemes`, use the same mechanism.
