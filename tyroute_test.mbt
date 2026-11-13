///|
let export_calls : Ref[Int32] = Ref(0)

///|
priv struct ExportRequest(@tyroute.Request)

///|
impl @tyroute.FromRequest for ExportRequest with fn from_request(request) {
  export_calls.val += 1
  ExportRequest(request)
}

///|
priv struct ExportResponse(String)

///|
impl @tyroute.ToResponse for ExportResponse with fn to_response(self) {
  export_calls.val += 1
  Response(status=200, body=self.0)
}

///|
#warnings("-unused_async")
async fn exported(_ctx : Unit, request : ExportRequest) -> ExportResponse {
  export_calls.val += 1
  ExportResponse(request.0.params().get("id").unwrap_or("").to_owned())
}

///|
fn json_field(value : Json, key : String) -> Json raise {
  guard value is Object(fields) && fields.get(key) is Some(field) else {
    fail("Missing JSON field: \{key}")
  }
  field
}

///|
test "OpenAPI exports route facts without invoking converters or inventing contracts" {
  let router = @tyroute.Router()
    ..get("/users/:id", exported, ())
    ..head("/users/:id", exported, ())
  let document = router.generate_openapi(title="Users", version="1")
  assert_eq(export_calls.val, 0)
  assert_eq(json_field(document, "openapi"), "3.2.1")
  let item = json_field(json_field(document, "paths"), "/users/{id}")
  for verb in ["get", "head"] {
    assert_eq(json_field(item, verb), {
      "parameters": [
        { "name": "id", "in": "path", "required": true, "schema": {} },
      ],
      "responses": {
        "default": { "description": "Response (schema not provided)" },
      },
    })
  }
  assert_eq(router.generate_openapi(title="Users", version="1"), document)
  assert_eq(export_calls.val, 0)
}

///|
test "OpenAPI normalizes capture names and describes catch-all and CONNECT routes" {
  let router = @tyroute.Router()
    ..get("/users/:id", exported, ())
    ..post("/users/:user", exported, ())
    ..get("/files/*rest", exported, ())
    ..add("/tunnel", Connect, exported, ())
  let paths = json_field(
    router.generate_openapi(title="Routes", version="1"),
    "paths",
  )
  let item = json_field(paths, "/users/{id}")
  assert_eq(json_field(json_field(item, "post"), "parameters"), [
    { "name": "id", "in": "path", "required": true, "schema": {} },
  ])
  assert_eq(
    json_field(
      json_field(json_field(paths, "/files/{rest}"), "get"),
      "parameters",
    ),
    [
      {
        "name": "rest",
        "in": "path",
        "required": true,
        "schema": {},
        "x-moonback-catch-all": true,
      },
    ],
  )
  let connect = json_field(
    json_field(json_field(paths, "/tunnel"), "additionalOperations"),
    "CONNECT",
  )
  assert_eq(json_field(connect, "responses"), {
    "default": { "description": "Response (schema not provided)" },
  })
}

///|
test "OpenAPI rejects ambiguous routes and invalid paths" {
  let duplicate = @tyroute.Router()
    ..get("/users/:id", exported, ())
    ..get("/users/:other", exported, ())
  try duplicate.generate_openapi(title="Invalid", version="1") catch {
    DuplicateOperation(_) => ()
    error => raise error
  } noraise {
    _ => fail("Expected duplicate operation")
  }
  let invalid_path = @tyroute.Router()..get("/users/:id/:id", exported, ())
  try invalid_path.generate_openapi(title="Invalid", version="1") catch {
    InvalidPath(_) => ()
    error => raise error
  } noraise {
    _ => fail("Expected invalid path")
  }
}

///|
let contract_body_calls : Ref[Int32] = Ref(0)

///|
priv struct ContractBody(String)

///|
impl @tyroute.ToSchema for ContractBody with fn to_schema(_ctx) {
  contract_body_calls.val += 1
  { "type": "string" }
}

///|
#warnings("-unused_constructor")
priv struct ContractAuth(Unit)

///|
impl @tyroute.ToSchema for ContractAuth with fn to_schema(_ctx) {
  { "type": "http", "scheme": "bearer" }
}

///|
#warnings("-unused_constructor")
priv struct ContractQuery(Unit)

///|
impl @tyroute.ToSchema for ContractQuery with fn to_schema(_ctx) {
  { "name": "verbose", "in": "query", "schema": { "type": "boolean" } }
}

///|
#warnings("-unused_constructor")
priv struct ContractHttpResponse(Unit)

///|
impl @tyroute.ToSchema for ContractHttpResponse with fn to_schema(ctx) {
  {
    "description": "User",
    "headers": { "Retry-After": { "schema": { "type": "integer" } } },
    "content": {
      "application/json": {
        "schema": ctx.ref(
          "#/components/schemas/User",
          (@tyroute.Tag : @tyroute.Tag[ContractBody]),
        ),
      },
    },
  }
}

///|
let contract_path_parameter : Json = {
  "name": "id",
  "in": "path",
  "schema": { "type": "integer" },
}

///|
priv struct ContractRequest(@tyroute.Request)

///|
impl @tyroute.FromRequest for ContractRequest with fn from_request(request) {
  export_calls.val += 1
  ContractRequest(request)
}

///|
impl @tyroute.ToSchema for ContractRequest with fn to_schema(ctx) {
  let _ = ctx.ref(
    "#/components/securitySchemes/Token",
    (@tyroute.Tag : @tyroute.Tag[ContractAuth]),
  )
  {
    "summary": "Update a user",
    "parameters": [
      contract_path_parameter,
      ctx.ref(
        "#/components/parameters/Verbose",
        (@tyroute.Tag : @tyroute.Tag[ContractQuery]),
      ),
    ],
    "requestBody": {
      "required": true,
      "content": {
        "application/json": {
          "schema": ctx.ref(
            "#/components/schemas/User",
            (@tyroute.Tag : @tyroute.Tag[ContractBody]),
          ),
        },
      },
    },
    "security": [{ "Token": [] }],
  }
}

///|
priv struct ContractResponse(ContractBody)

///|
impl @tyroute.ToResponse for ContractResponse with fn to_response(self) {
  export_calls.val += 1
  Response(status=200, body=self.0.0)
}

///|
impl @tyroute.ToSchema for ContractResponse with fn to_schema(ctx) {
  {
    "200": ctx.ref(
      "#/components/responses/User",
      (@tyroute.Tag : @tyroute.Tag[ContractHttpResponse]),
    ),
    "404": { "description": "Missing" },
  }
}

///|
#warnings("-unused_async")
async fn contracted(_ctx : Unit, request : ContractRequest) -> ContractResponse {
  export_calls.val += 1
  ContractResponse(
    ContractBody(request.0.params().get("id").unwrap_or("").to_owned()),
  )
}

///|
test "inferred contracts collect shared components at export and HEAD preserves them" {
  contract_body_calls.val = 0
  export_calls.val = 0
  let router = @tyroute.Router()
    ..get("/users/:id", contracted, (), schema=@tyroute.inferred())
    ..head("/users/:id", contracted, (), schema=@tyroute.inferred())
    ..post("/users/:id", contracted, (), schema=@tyroute.inferred())
    ..put("/users/:id", contracted, (), schema=@tyroute.inferred())
    ..patch("/users/:id", contracted, (), schema=@tyroute.inferred())
    ..delete("/users/:id", contracted, (), schema=@tyroute.inferred())
  assert_eq(contract_body_calls.val, 0)
  let document = router.generate_openapi(title="Contracts", version="1")
  assert_eq(contract_body_calls.val, 1)
  assert_eq(export_calls.val, 0)
  let item = json_field(json_field(document, "paths"), "/users/{id}")
  let get = json_field(item, "get")
  for verb in ["post", "put", "patch", "delete"] {
    assert_eq(json_field(item, verb), get)
  }
  assert_eq(json_field(get, "summary"), "Update a user")
  assert_eq(json_field(get, "parameters"), [
    {
      "name": "id",
      "in": "path",
      "required": true,
      "schema": { "type": "integer" },
    },
    { "$ref": "#/components/parameters/Verbose" },
  ])
  assert_eq(json_field(get, "security"), [{ "Token": [] }])
  assert_eq(json_field(get, "requestBody"), {
    "required": true,
    "content": {
      "application/json": { "schema": { "$ref": "#/components/schemas/User" } },
    },
  })
  assert_eq(json_field(get, "responses"), {
    "200": { "$ref": "#/components/responses/User" },
    "404": { "description": "Missing" },
  })
  assert_eq(json_field(json_field(item, "head"), "responses"), {
    "200": {
      "description": "User",
      "headers": { "Retry-After": { "schema": { "type": "integer" } } },
    },
    "404": { "description": "Missing" },
  })
  let components = json_field(document, "components")
  assert_eq(json_field(json_field(components, "schemas"), "User"), {
    "type": "string",
  })
  assert_eq(json_field(json_field(components, "securitySchemes"), "Token"), {
    "type": "http",
    "scheme": "bearer",
  })
  assert_eq(
    json_field(
      json_field(json_field(components, "responses"), "User"),
      "content",
    ),
    {
      "application/json": { "schema": { "$ref": "#/components/schemas/User" } },
    },
  )
  assert_eq(contract_path_parameter, {
    "name": "id",
    "in": "path",
    "schema": { "type": "integer" },
  })
  assert_eq(router.generate_openapi(title="Contracts", version="1"), document)
  assert_eq(contract_body_calls.val, 2)
  assert_eq(export_calls.val, 0)
}

///|
let custom_request_schema : Ref[Json] = Ref({})

///|
let custom_response_schema : Ref[Json] = Ref({ "200": { "description": "OK" } })

///|
priv struct CustomContractRequest(@tyroute.Request)

///|
impl @tyroute.FromRequest for CustomContractRequest with fn from_request(
  request,
) {
  CustomContractRequest(request)
}

///|
impl @tyroute.ToSchema for CustomContractRequest with fn to_schema(_ctx) {
  custom_request_schema.val
}

///|
priv struct CustomContractResponse(String)

///|
impl @tyroute.ToResponse for CustomContractResponse with fn to_response(self) {
  Response(status=200, body=self.0)
}

///|
impl @tyroute.ToSchema for CustomContractResponse with fn to_schema(_ctx) {
  custom_response_schema.val
}

///|
#warnings("-unused_async")
async fn custom_contract(
  _ctx : Unit,
  request : CustomContractRequest,
) -> CustomContractResponse {
  CustomContractResponse(request.0.params().length().to_string())
}

///|
test "inferred contracts normalize declared captures and fill undeclared captures" {
  custom_request_schema.val = {
    "parameters": [
      { "name": "user", "in": "path", "schema": { "type": "string" } },
    ],
  }
  custom_response_schema.val = { "200": { "description": "OK" } }
  let router = @tyroute.Router()
    ..get("/users/:id", exported, ())
    ..add("/users/:user", Post, custom_contract, (), schema=@tyroute.inferred())
    ..add("/files/*user", Get, custom_contract, (), schema=@tyroute.inferred())
    ..add(
      "/users/:user/:scope",
      Get,
      custom_contract,
      (),
      schema=@tyroute.inferred(),
    )
  let paths = json_field(
    router.generate_openapi(title="Paths", version="1"),
    "paths",
  )
  assert_eq(
    json_field(
      json_field(json_field(paths, "/users/{id}"), "post"),
      "parameters",
    ),
    [
      {
        "name": "id",
        "in": "path",
        "required": true,
        "schema": { "type": "string" },
      },
    ],
  )
  assert_eq(
    json_field(
      json_field(json_field(paths, "/files/{user}"), "get"),
      "parameters",
    ),
    [
      {
        "name": "user",
        "in": "path",
        "required": true,
        "schema": { "type": "string" },
        "x-moonback-catch-all": true,
      },
    ],
  )
  assert_eq(
    json_field(
      json_field(json_field(paths, "/users/{user}/{scope}"), "get"),
      "parameters",
    ),
    [
      {
        "name": "user",
        "in": "path",
        "required": true,
        "schema": { "type": "string" },
      },
      { "name": "scope", "in": "path", "required": true, "schema": {} },
    ],
  )
  assert_eq(custom_request_schema.val, {
    "parameters": [
      { "name": "user", "in": "path", "schema": { "type": "string" } },
    ],
  })
}

///|
test "inferred contracts reject malformed operations parameters and responses" {
  let responses : Json = { "200": { "description": "OK" } }
  let cases : Array[(Json, Json)] = [
    (false, responses),
    ({ "responses": responses }, responses),
    ({ "parameters": false }, responses),
    ({ "parameters": [{ "name": "other", "in": "path" }] }, responses),
    (
      { "parameters": [{ "name": "id", "in": "path", "required": false }] },
      responses,
    ),
    (
      {
        "parameters": [
          { "name": "X-Token", "in": "header" },
          { "name": "x-token", "in": "header" },
        ],
      },
      responses,
    ),
    ({ "requestBody": false }, responses),
    ({}, false),
    ({}, {}),
    ({}, { "600": { "description": "Invalid status" } }),
    ({}, { "200": false }),
    ({}, { "200": {} }),
    ({}, { "x-only": true }),
    ({}, { "200": { "$ref": "#/components/responses/Missing" } }),
  ]
  for (request, response) in cases {
    custom_request_schema.val = request
    custom_response_schema.val = response
    let router = @tyroute.Router()..add(
      "/users/:id",
      Post,
      custom_contract,
      (),
      schema=@tyroute.inferred(),
    )
    try router.generate_openapi(title="Invalid", version="1") catch {
      InvalidSchema(_) => ()
      error => raise error
    } noraise {
      _ => fail("Expected an invalid contract")
    }
  }
}
