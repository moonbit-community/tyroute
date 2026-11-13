///|
let schema_leaf_calls : Ref[Int32] = Ref(0)

///|
let schema_node_calls : Ref[Int32] = Ref(0)

///|
#warnings("-unused_constructor")
priv struct SchemaLeaf(String)

///|
impl ToSchema for SchemaLeaf with fn to_schema(_ctx) {
  schema_leaf_calls.val += 1
  { "type": "string" }
}

///|
#warnings("-unused_constructor")
priv struct SchemaNode(SchemaNode?, SchemaLeaf)

///|
impl ToSchema for SchemaNode with fn to_schema(ctx) {
  schema_node_calls.val += 1
  {
    "type": "object",
    "properties": {
      "next": {
        "anyOf": [
          ctx.ref("#/components/schemas/Node", (Tag : Tag[SchemaNode])),
          { "type": "null" },
        ],
      },
      "leaf": ctx.ref("#/components/schemas/Leaf", (Tag : Tag[SchemaLeaf])),
    },
    "required": ["next", "leaf"],
  }
}

///|
#warnings("-unused_constructor")
priv struct SchemaToken(String)

///|
impl ToSchema for SchemaToken with fn to_schema(_ctx) {
  { "type": "http", "scheme": "bearer" }
}

///|
test "component contexts collect recursive schemas and security definitions once" {
  schema_leaf_calls.val = 0
  schema_node_calls.val = 0
  let ctx = SchemaContext::new(None)
  let reference = ctx.ref("#/components/schemas/Node", (Tag : Tag[SchemaNode]))
  assert_eq(reference, { "$ref": "#/components/schemas/Node" })
  assert_eq(
    ctx.ref("#/components/schemas/Node", (Tag : Tag[SchemaNode])),
    reference,
  )
  let _ = ctx.ref(
    "#/components/securitySchemes/Token",
    (Tag : Tag[SchemaToken]),
  )
  assert_eq(schema_leaf_calls.val, 1)
  assert_eq(schema_node_calls.val, 1)
  let expected : Json = {
    "schemas": {
      "Node": {
        "type": "object",
        "properties": {
          "next": {
            "anyOf": [
              { "$ref": "#/components/schemas/Node" },
              { "type": "null" },
            ],
          },
          "leaf": { "$ref": "#/components/schemas/Leaf" },
        },
        "required": ["next", "leaf"],
      },
      "Leaf": { "type": "string" },
    },
    "securitySchemes": { "Token": { "type": "http", "scheme": "bearer" } },
  }
  assert_eq(ctx.finish(), Some(expected))
  assert_eq(SchemaContext::new(None).finish(), None)
}

///|
test "component contexts reuse existing definitions without mutating their input" {
  schema_leaf_calls.val = 0
  let supplied : Json = { "schemas": { "Leaf": { "type": "string" } } }
  let ctx = SchemaContext::new(Some(supplied))
  let _ = ctx.ref("#/components/schemas/Leaf", (Tag : Tag[SchemaLeaf]))
  assert_eq(schema_leaf_calls.val, 0)
  let _ = ctx.ref(
    "#/components/securitySchemes/Token",
    (Tag : Tag[SchemaToken]),
  )
  let _ = ctx.finish()
  assert_eq(supplied, { "schemas": { "Leaf": { "type": "string" } } })
}

///|
test "component reference resolution preserves overrides and rejects cycles" {
  let supplied : Json = {
    "responses": {
      "Base": { "description": "Base", "content": { "text/plain": {} } },
      "Alias": { "$ref": "#/components/responses/Base", "description": "Alias" },
      "Cycle": { "$ref": "#/components/responses/Cycle" },
    },
  }
  let ctx = SchemaContext::new(Some(supplied))
  assert_eq(
    ctx.resolve({
      "$ref": "#/components/responses/Alias",
      "description": "Override",
    }),
    { "description": "Override", "content": { "text/plain": {} } },
  )
  try ctx.resolve({ "$ref": "#/components/responses/Cycle" }) catch {
    InvalidSchema(_) => ()
    error => raise error
  } noraise {
    _ => fail("Expected a circular reference error")
  }
  assert_eq(ctx.finish(), Some(supplied))
}
