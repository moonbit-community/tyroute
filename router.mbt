///|
struct Router {
  routes : Array[Route]
}

///|
priv struct Route {
  meth : @http.RequestMethod
  path : String
  handler : @moonback.Handler
  params_schema : @json.Json
  queries_schema : @json.Json
  headers_schema : @json.Json
  body_schema : @json.Json
  response_schema : @json.Json
}

///|
pub fn Router::Router() -> Router {
  { routes: [], }
}

///|
pub fn[
  P : FromParam,
  Q : FromQueries,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::add(
  self : Router,
  path : String,
  meth : @http.RequestMethod,
  handler : (P, Q, H, B) -> R,
) -> Unit {
  self.routes.push({
    meth,
    path,
    params_schema: P::schema(),
    queries_schema: Q::schema(),
    headers_schema: H::schema(),
    body_schema: B::schema(),
    response_schema: R::schema(),
    handler: (req, res) => {
      let response = try {
        let params = req.params.to_array()
        // FromParam pops from the end; reverse captures to preserve path order.
        params.rev_in_place()
        let params : P = FromParam::from_param(params)
        let queries : Q = FromQueries::from_queries(req.query())
        let headers : H = FromHeaders::from_headers(req.headers)
        let body : B = FromBody::from_body(req.body)
        ToResponse::to_response(handler(params, queries, headers, body))
      } catch {
        ResponseMismatch(_) =>
          Response(status=500, headers=@moonback.Headers::default())
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
pub fn[P : FromParam, Q : FromQueries, H : FromHeaders, R : ToResponse] Router::get(
  self : Router,
  path : String,
  handler : (P, Q, H) -> R,
) -> Unit {
  self.add(path, Get, (params, queries, headers, _body : Unit) => {
    handler(params, queries, headers)
  })
}

///|
pub fn[
  P : FromParam,
  Q : FromQueries,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::post(
  self : Router,
  path : String,
  handler : (P, Q, H, B) -> R,
) -> Unit {
  self.add(path, Post, handler)
}

///|
pub fn[
  P : FromParam,
  Q : FromQueries,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::put(
  self : Router,
  path : String,
  handler : (P, Q, H, B) -> R,
) -> Unit {
  self.add(path, Put, handler)
}

///|
pub fn[
  P : FromParam,
  Q : FromQueries,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::patch(
  self : Router,
  path : String,
  handler : (P, Q, H, B) -> R,
) -> Unit {
  self.add(path, Patch, handler)
}

///|
pub fn[
  P : FromParam,
  Q : FromQueries,
  H : FromHeaders,
  B : FromBody,
  R : ToResponse,
] Router::delete(
  self : Router,
  path : String,
  handler : (P, Q, H, B) -> R,
) -> Unit {
  self.add(path, Delete, handler)
}

///|
pub fn[P : FromParam, Q : FromQueries, H : FromHeaders, R : ToResponse] Router::head(
  self : Router,
  path : String,
  handler : (P, Q, H) -> R,
) -> Unit {
  self.add(path, Head, (params, queries, headers, _body : Unit) => {
    handler(params, queries, headers)
  })
}

///|
pub fn[P : FromParam, Q : FromQueries, H : FromHeaders, R : ToResponse] Router::options(
  self : Router,
  path : String,
  handler : (P, Q, H) -> R,
) -> Unit {
  self.add(path, Options, (params, queries, headers, _body : Unit) => {
    handler(params, queries, headers)
  })
}

///|
pub impl @moonback.Extension for Router with fn initialize(self, ctx) {
  for route in self.routes {
    ctx.add_route(route.meth, route.path, route.handler)
  }
}

///|
pub extend Router with @moonback.Extension::{initialize}
