///|
pub suberror OpenApiError {
  InvalidPath(String)
  InvalidSchema(String)
  DuplicateOperation(String)
}

///|
priv struct OpenApiRoute {
  url : String
  title : String
  version : String
  components : @json.Json?
}

///|
/// Export the registered routes as an OpenAPI 3.2 document without invoking
/// handlers. Schemas may be objects or booleans; {} remains unconstrained.
/// Query constraints are preserved through an in: querystring parameter.
/// Aggregate header constraints are retained in a specification extension.
/// Status codes and media types are unknown to schema(), so responses use
/// default and content uses */*. Pass components when schemas use local $refs.
pub fn Router::generate_openapi(
  self : Router,
  title~ : String,
  version~ : String,
  components? : @json.Json,
) -> @json.Json raise OpenApiError {
  let paths : Map[String, @json.Json] = Map([])
  let templates : Map[String, (String, Array[String])] = Map([])
  for route in self.routes {
    for
      schema in [
        route.params_schema,
        route.query_schema,
        route.headers_schema,
        route.body_schema,
        route.response_schema,
      ] {
      guard schema is (Object(_) | True | False) else {
        raise InvalidSchema(route.path)
      }
    }
    let segments : Array[String] = []
    let shape : Array[String] = []
    let names : Array[String] = []
    let catch_all : Array[Bool] = []
    for segment in route.path.split("/").filter(s => !s.is_empty()) {
      let capture = if segment is [':', .. name] {
        Some((name.to_owned(), false))
      } else if segment is ['*', .. name] {
        Some((if name.is_empty() { "rest" } else { name.to_owned() }, true))
      } else {
        None
      }
      if capture is Some((name, rest)) {
        guard !name.is_empty() &&
          !name.contains("{") &&
          !name.contains("}") &&
          !names.contains(name) else {
          raise InvalidPath(route.path)
        }
        names.push(name)
        catch_all.push(rest)
        segments.push("{\{name}}")
        shape.push("{}")
        if rest {
          break
        }
      } else {
        guard !segment.contains("{") && !segment.contains("}") else {
          raise InvalidPath(route.path)
        }
        segments.push(segment.to_owned())
        shape.push(segment.to_owned())
      }
    }
    let shape = "/" + shape.join("/")
    // OpenAPI forbids separate paths that differ only in capture names.
    // Reuse the first spelling while keeping each operation's input schema.
    let (path, parameter_names) = if templates.get(shape) is Some(template) {
      template
    } else {
      let path = "/" + segments.join("/")
      templates[shape] = (path, names)
      (path, names)
    }
    let parameters : Array[@json.Json] = []
    for index, name in names {
      let schema = if route.params_schema is Object(fields) &&
        fields.get("properties") is Some(Object(properties)) {
        properties.get(name).unwrap_or(@json.Json::empty_object())
      } else if route.params_schema is Object(fields) &&
        fields.get("prefixItems") is Some(Array(items)) {
        items.get(index).unwrap_or(@json.Json::empty_object())
      } else if names.length() == 1 && !(route.params_schema is False) {
        route.params_schema
      } else {
        @json.Json::empty_object()
      }
      let parameter : Map[String, @json.Json] = {
        "name": @json.Json::string(parameter_names[index]),
        "in": "path",
        "required": true,
        "schema": schema,
      }
      if catch_all[index] {
        // Standard path templates cannot describe captures containing raw '/'.
        parameter["x-moonback-catch-all"] = true
      }
      parameters.push(@json.Json::object(parameter))
    }
    if !(route.query_schema is False) {
      parameters.push({
        "name": "query",
        "in": "querystring",
        "content": {
          "application/x-www-form-urlencoded": { "schema": route.query_schema },
        },
      })
    }
    if route.headers_schema is Object(fields) &&
      fields.get("properties") is Some(Object(properties)) {
      let required = if fields.get("required") is Some(Array(names)) {
        names
      } else {
        []
      }
      let seen : Map[String, Unit] = Map([])
      for name, schema in properties {
        let normalized = name.to_lower()
        guard !seen.contains(normalized) else {
          raise InvalidSchema("Duplicate header: \{name}")
        }
        seen[normalized] = ()
        parameters.push({
          "name": name,
          "in": "header",
          "required": required.contains(@json.Json::string(name)),
          "schema": schema,
        })
      }
    }
    let response : Map[String, @json.Json] = { "description": "Response" }
    if route.meth != Head && !(route.response_schema is False) {
      response["content"] = { "*/*": { "schema": route.response_schema } }
    }
    let operation : Map[String, @json.Json] = {
      "responses": { "default": @json.Json::object(response) },
    }
    if !parameters.is_empty() {
      operation["parameters"] = @json.Json::array(parameters)
    }
    if !(route.headers_schema is False) {
      operation["x-headers-schema"] = route.headers_schema
    }
    if !(route.body_schema is False) {
      operation["requestBody"] = {
        "required": true,
        "content": { "*/*": { "schema": route.body_schema } },
      }
    }
    let item = if paths.get(path) is Some(Object(item)) {
      item
    } else {
      Map([])
    }
    let verb = match route.meth {
      Get => "get"
      Head => "head"
      Post => "post"
      Put => "put"
      Delete => "delete"
      Options => "options"
      Trace => "trace"
      Patch => "patch"
      Connect => "CONNECT"
    }
    if route.meth == Connect {
      let additional = if item.get("additionalOperations")
        is Some(Object(items)) {
        items
      } else {
        Map([])
      }
      guard !additional.contains(verb) else {
        raise DuplicateOperation("\{verb} \{path}")
      }
      additional[verb] = @json.Json::object(operation)
      item["additionalOperations"] = @json.Json::object(additional)
    } else {
      guard !item.contains(verb) else {
        raise DuplicateOperation("\{verb} \{path}")
      }
      item[verb] = @json.Json::object(operation)
    }
    paths[path] = @json.Json::object(item)
  }
  let document : Map[String, @json.Json] = {
    "openapi": "3.2.1",
    "info": { "title": title, "version": version },
    "paths": @json.Json::object(paths),
  }
  if components is Some(components) {
    guard components is Object(_) else {
      raise InvalidSchema("components must be an object")
    }
    document["components"] = components
  }
  @json.Json::object(document)
}

///|
/// Configure an OpenAPI endpoint. MoonBack initialization generates the
/// document and registers a GET route serving it as application/json.
pub fn Router::openapi(
  self : Router,
  url : String,
  title~ : String,
  version~ : String,
  components? : @json.Json,
) -> Unit {
  self.openapi_routes.push({ url, title, version, components, })
}
