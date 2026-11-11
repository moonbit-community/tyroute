# Async handlers

All router methods accept async handlers. Handlers can call databases or other
async APIs before returning a value implementing `ToResponse`. Request extraction
and response conversion use the same typed traits as before.

Register named handlers as `router.get(path, handler, ctx)`. All HTTP method
helpers use this argument order; `add` uses `path, method, handler, ctx`.
The handler receives the same typed context as its first argument on each
request. Use `()` when no context is needed. The context is not extracted from
the request or included in OpenAPI schemas.

Declare named handlers with `async fn`. To reuse a synchronous function, pass a
closure that calls it: `router.get("/users/:id", (ctx, id, query, headers) =>
get_user(ctx, id, query, headers), ctx)`.

`HandlerError` retains its existing response mapping. Other errors propagate to
MoonBack middleware, including errors raised after an async operation.
