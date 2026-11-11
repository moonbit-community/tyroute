# Async handlers

All router methods accept async handlers. Handlers can call databases or other
async APIs before returning a value implementing `ToResponse`. Request extraction
and response conversion use the same typed traits as before.

Declare named handlers with `async fn`. To reuse a synchronous function, pass a
closure that calls it: `router.get("/users/:id", (id, query, headers) =>
get_user(id, query, headers))`.

`HandlerError` retains its existing response mapping. Other errors propagate to
MoonBack middleware, including errors raised after an async operation.
