# tyroute

Typed requests, responses, and OpenAPI export for MoonBack.

Handlers accept `(Ctx, CustomRequest)` and return `CustomResponse`. Implement
`FromRequest` to extract and validate a complete request, and `ToResponse` to
choose the HTTP status, headers, and body.

See [the handler API](docs/handlers.md) and the runnable
[example](example/main.mbt).

## Development

```sh
moon update
moon fmt --check . example/serve.mbtx
moon check --target wasm
moon test --target wasm
moon build example --target wasm
moon check --target native
moon test --target native
moon build example --target native
moon info
```

Run the example with `moon run example --target native`, then visit
`http://127.0.0.1:3000/users/42?name=Alice` or `/openapi.json`.
