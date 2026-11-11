///|
fn init {
  let router = @tyroute.Router()
  router.get("api/v0/modules", module_list, ())
  router.post("api/v0/modules/:user/:name", module_create, ())
}

///|
#derive(FromJson, ToJson)
struct Module {
  name : String
  desc : String
}

///|
#derive(FromJson)
struct ModuleListParams {
  user : String
  name : String
}

///|
#derive(FromJson)
struct ModuleListQuery {
  page : Int32?
  limit : Int32?
  offset : Int32?
}

///|
#derive(FromJson)
struct ModuleListHeaders {
  token : String
}

///|
async fn module_list(
  _ctx : Unit,
  _params : Unit,
  query : @tyroute.ViaJson[ModuleListQuery],
  headers : @tyroute.ViaJson[ModuleListHeaders],
) -> (StatusCode, ViaJson[Array[Module]]) {
  (StatusCode(200), [])
}

///|
async fn module_create(
  _ctx : Unit,
  params : (String, String),
  _query : Unit,
  _headers : Unit,
  body : @json.Json,
) -> ViaJson[Array[Module]] {
  let (user, name) = params
  ...
}
