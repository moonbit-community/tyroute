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
  schema : ((SchemaContext) -> (Json, Json))?
}

///|
pub fn Router::Router() -> Router {
  { routes: [], openapi_routes: [], }
}

///|
/// A request/response contract tied to the handler's types.
#warnings("-unused_type_variable")
struct RouteSchema[Req, Res]((SchemaContext) -> (Json, Json))

///|
/// Select the handler types' schemas, generated during OpenAPI export.
pub fn[Req : ToSchema, Res : ToSchema] inferred() -> RouteSchema[Req, Res] {
  RouteSchema(ctx => (Req::to_schema(ctx), Res::to_schema(ctx)))
}

///|
pub fn[Ctx, Req : FromRequest, Res : ToResponse] Router::add(
  self : Router,
  path : String,
  meth : @http.RequestMethod,
  handler : async (Ctx, Req) -> Res,
  ctx : Ctx,
  schema? : RouteSchema[Req, Res],
) -> Unit {
  self.routes.push({
    meth,
    path,
    schema: schema.map(schema => schema.0),
    handler: (req, res) => {
      let request : Req = FromRequest::from_request(Request(req))
      let response = ToResponse::to_response(handler(ctx, request))
      let writer = res.respond(status=response.status, headers=response.headers)
      if req.meth != Head && response.body is Some(body) {
        writer.write(body)
      }
    },
  })
}

///|
pub fn[Ctx, Req : FromRequest, Res : ToResponse] Router::get(
  self : Router,
  path : String,
  handler : async (Ctx, Req) -> Res,
  ctx : Ctx,
  schema? : RouteSchema[Req, Res],
) -> Unit {
  self.add(path, Get, handler, ctx, schema?)
}

///|
pub fn[Ctx, Req : FromRequest, Res : ToResponse] Router::post(
  self : Router,
  path : String,
  handler : async (Ctx, Req) -> Res,
  ctx : Ctx,
  schema? : RouteSchema[Req, Res],
) -> Unit {
  self.add(path, Post, handler, ctx, schema?)
}

///|
pub fn[Ctx, Req : FromRequest, Res : ToResponse] Router::put(
  self : Router,
  path : String,
  handler : async (Ctx, Req) -> Res,
  ctx : Ctx,
  schema? : RouteSchema[Req, Res],
) -> Unit {
  self.add(path, Put, handler, ctx, schema?)
}

///|
pub fn[Ctx, Req : FromRequest, Res : ToResponse] Router::patch(
  self : Router,
  path : String,
  handler : async (Ctx, Req) -> Res,
  ctx : Ctx,
  schema? : RouteSchema[Req, Res],
) -> Unit {
  self.add(path, Patch, handler, ctx, schema?)
}

///|
pub fn[Ctx, Req : FromRequest, Res : ToResponse] Router::delete(
  self : Router,
  path : String,
  handler : async (Ctx, Req) -> Res,
  ctx : Ctx,
  schema? : RouteSchema[Req, Res],
) -> Unit {
  self.add(path, Delete, handler, ctx, schema?)
}

///|
pub fn[Ctx, Req : FromRequest, Res : ToResponse] Router::head(
  self : Router,
  path : String,
  handler : async (Ctx, Req) -> Res,
  ctx : Ctx,
  schema? : RouteSchema[Req, Res],
) -> Unit {
  self.add(path, Head, handler, ctx, schema?)
}

///|
pub impl @moonback.Extension for Router with fn initialize(self, ctx) {
  for route in self.routes {
    ctx.add_route(route.meth, route.path, route.handler)
  }
  for route in self.openapi_routes {
    let document = self.generate_openapi(
      title=route.title,
      version=route.version,
    )
    ctx.get(route.url, (_request, response) => response.send_json(document))
  }
}

///|
pub extend Router with @moonback.Extension::{initialize}
