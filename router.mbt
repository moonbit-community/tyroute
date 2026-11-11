///|
struct Router {
  routes : Array[Route]
  openapi_routes : Array[OpenApiRoute]
}

///|
priv struct Route {
  meth : @http.RequestMethod
  path : String
  handler : @moonback.Handler
  params_schema : @json.Json
  query_schema : @json.Json
  headers_schema : @json.Json
  body_schema : @json.Json
  response_schema : @json.Json
}

///|
pub fn Router::Router() -> Router {
  { routes: [], openapi_routes: [], }
}

///|
pub fn[
  C,
  P : FromParam,
  Q : FromQuery,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::add(
  self : Router,
  path : String,
  meth : @http.RequestMethod,
  handler : async (C, P, Q, H, B) -> R,
  ctx : C,
) -> Unit {
  self.routes.push({
    meth,
    path,
    params_schema: P::schema(),
    query_schema: Q::schema(),
    headers_schema: H::schema(),
    body_schema: B::schema(),
    response_schema: R::schema(),
    handler: (req, res) => {
      let response = try {
        let params = req.params.to_array()
        // FromParam pops from the end; reverse captures to preserve path order.
        params.rev_in_place()
        let params : P = FromParam::from_param(params)
        let query : Q = FromQuery::from_query(req.query())
        let headers : H = FromHeaders::from_headers(req.headers)
        let body : B = FromBody::from_body(req.body)
        ToResponse::to_response(handler(ctx, params, query, headers, body))
      } catch {
        ResponseMismatch(_) => Response(status=500)
        HandlerError::_ as e =>
          Response(
            status=400,
            headers=[("Content-Type", "text/plain; charset=utf-8")],
            body=e.to_string(),
          )
        error => raise error
      }
      let writer = res.respond(status=response.status, headers=response.headers)
      if req.meth != Head && response.body is Some(body) {
        writer.write(body)
      }
    },
  })
}

///|
pub fn[C, P : FromParam, Q : FromQuery, H : FromHeaders, R : ToResponse] Router::get(
  self : Router,
  path : String,
  handler : async (C, P, Q, H) -> R,
  ctx : C,
) -> Unit {
  self.add(
    path,
    Get,
    (ctx, params, query, headers, _body : Unit) => {
      handler(ctx, params, query, headers)
    },
    ctx,
  )
}

///|
pub fn[
  C,
  P : FromParam,
  Q : FromQuery,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::post(
  self : Router,
  path : String,
  handler : async (C, P, Q, H, B) -> R,
  ctx : C,
) -> Unit {
  self.add(path, Post, handler, ctx)
}

///|
pub fn[
  C,
  P : FromParam,
  Q : FromQuery,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::put(
  self : Router,
  path : String,
  handler : async (C, P, Q, H, B) -> R,
  ctx : C,
) -> Unit {
  self.add(path, Put, handler, ctx)
}

///|
pub fn[
  C,
  P : FromParam,
  Q : FromQuery,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::patch(
  self : Router,
  path : String,
  handler : async (C, P, Q, H, B) -> R,
  ctx : C,
) -> Unit {
  self.add(path, Patch, handler, ctx)
}

///|
pub fn[
  C,
  P : FromParam,
  Q : FromQuery,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::delete(
  self : Router,
  path : String,
  handler : async (C, P, Q, H, B) -> R,
  ctx : C,
) -> Unit {
  self.add(path, Delete, handler, ctx)
}

///|
pub fn[C, P : FromParam, Q : FromQuery, H : FromHeaders, R : ToResponse] Router::head(
  self : Router,
  path : String,
  handler : async (C, P, Q, H) -> R,
  ctx : C,
) -> Unit {
  self.add(
    path,
    Head,
    (ctx, params, query, headers, _body : Unit) => {
      handler(ctx, params, query, headers)
    },
    ctx,
  )
}

///|
pub fn[C, P : FromParam, Q : FromQuery, H : FromHeaders, R : ToResponse] Router::options(
  self : Router,
  path : String,
  handler : async (C, P, Q, H) -> R,
  ctx : C,
) -> Unit {
  self.add(
    path,
    Options,
    (ctx, params, query, headers, _body : Unit) => {
      handler(ctx, params, query, headers)
    },
    ctx,
  )
}

///|
pub impl @moonback.Extension for Router with fn initialize(self, ctx) {
  for route in self.routes {
    ctx.add_route(route.meth, route.path, route.handler)
  }
  for route in self.openapi_routes {
    let components = route.components
    let document = self.generate_openapi(
      title=route.title,
      version=route.version,
      components?,
    )
    ctx.get(route.url, (_request, response) => response.send_json(document))
  }
}

///|
pub extend Router with @moonback.Extension::{initialize}
