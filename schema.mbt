///|
/// Describe a reusable component or route contract and collect its references.
pub(open) trait ToSchema {
  fn to_schema(SchemaContext) -> @json.Json
}

///|
/// An empty request contract.
pub impl ToSchema for Unit with fn to_schema(_ctx) {
  {}
}

///|
/// A type witness selecting the ToSchema implementation.
#warnings("-unused_type_variable")
pub(all) enum Tag[T] {
  Tag
}

///|
/// Components collected while exporting one OpenAPI document.
struct SchemaContext {
  components : Map[String, @json.Json]
  references : Map[String, @json.Json?]
}

///|
fn SchemaContext::new(
  components : @json.Json?,
) -> SchemaContext raise OpenApiError {
  let components = if components is Some(Object(fields)) {
    fields.copy()
  } else if components is None {
    Map([])
  } else {
    raise InvalidSchema("components must be an object")
  }
  { components, references: Map([]), }
}

///|
/// Return a local component reference, generating its definition only once.
/// The tag selects the ToSchema implementation used for generation.
/// Mark the reference before generation so recursive components terminate.
pub fn[T : ToSchema] SchemaContext::ref(
  self : SchemaContext,
  name : String,
  _tag : Tag[T],
) -> @json.Json {
  let path = name
  if !self.references.contains(path) {
    let existing = if path.split("/").to_array()
      is ["#", "components", section, name] &&
      self.components.get(section.to_owned()) is Some(Object(definitions)) {
      definitions.get(name.to_owned())
    } else {
      None
    }
    if existing is Some(existing) {
      self.references[path] = Some(existing)
    } else {
      self.references[path] = None
      self.references[path] = Some(T::to_schema(self))
    }
  }
  { "$ref": path }
}

///|
/// Resolve registered references for path normalization and HEAD responses.
fn SchemaContext::resolve(
  self : SchemaContext,
  schema : Json,
) -> Json raise OpenApiError {
  let seen : Map[String, Unit] = Map([])
  let siblings : Map[String, Json] = Map([])
  let mut current = schema
  while current is Object(fields) && fields.get("$ref") is Some(reference) {
    guard reference is String(path) else {
      raise InvalidSchema("Component reference must be a string")
    }
    guard !seen.contains(path) else {
      raise InvalidSchema("Circular component reference: \{path}")
    }
    seen[path] = ()
    for name, value in fields {
      if name != "$ref" && !siblings.contains(name) {
        siblings[name] = value
      }
    }
    current = if self.references.get(path) is Some(Some(definition)) {
      definition
    } else if path.split("/").to_array() is ["#", "components", section, name] &&
      self.components.get(section.to_owned()) is Some(Object(definitions)) &&
      definitions.get(name.to_owned()) is Some(definition) {
      definition
    } else {
      raise InvalidSchema("Unresolved component reference: \{path}")
    }
  }
  if siblings.is_empty() {
    current
  } else {
    guard current is Object(fields) else {
      raise InvalidSchema("Referenced component must be an object")
    }
    let fields = fields.copy()
    for name, value in siblings {
      fields[name] = value
    }
    @json.Json::object(fields)
  }
}

///|
fn SchemaContext::finish(
  self : SchemaContext,
) -> @json.Json? raise OpenApiError {
  for path, schema in self.references {
    guard path.split("/").to_array() is ["#", "components", section, name] &&
      section
      is ("schemas"
      | "responses"
      | "parameters"
      | "examples"
      | "requestBodies"
      | "headers"
      | "securitySchemes"
      | "links"
      | "callbacks"
      | "pathItems"
      | "mediaTypes") &&
      !name.is_empty() &&
      name
      .iter()
      .all(c => c is ('a'..<='z' | 'A'..<='Z' | '0'..<='9' | '.' | '-' | '_')) else {
      raise InvalidSchema("Expected a local component reference: \{path}")
    }
    guard schema is Some(schema) else {
      raise InvalidSchema("Unfinished component: \{path}")
    }
    let section = section.to_owned()
    let name = name.to_owned()
    let definitions = if self.components.get(section) is Some(Object(fields)) {
      fields.copy()
    } else if !self.components.contains(section) {
      Map([])
    } else {
      raise InvalidSchema("components.\{section} must be an object")
    }
    definitions[name] = schema
    self.components[section] = @json.Json::object(definitions)
  }
  if self.components.is_empty() {
    None
  } else {
    Some(@json.Json::object(self.components))
  }
}
