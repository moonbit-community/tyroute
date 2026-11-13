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
}

///|
/// Export routes and their optional contracts without invoking converters or
/// handlers. Routes without a contract use an undocumented default response.
pub fn Router::generate_openapi(
  self : Router,
  title~ : String,
  version~ : String,
) -> @json.Json raise OpenApiError {
  let ctx = SchemaContext::new(None)
  let paths : Map[String, @json.Json] = Map([])
  let templates : Map[String, (String, Array[String])] = Map([])
  for route in self.routes {
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
    // Reuse the first spelling for all operations on the same path shape.
    let (path, parameter_names) = if templates.get(shape) is Some(template) {
      template
    } else {
      let path = "/" + segments.join("/")
      templates[shape] = (path, names)
      (path, names)
    }
    let operation = route.openapi_operation(
      ctx, names, parameter_names, catch_all,
    )
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
  if ctx.finish() is Some(components) {
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
) -> Unit {
  self.openapi_routes.push({ url, title, version, })
}

///|
fn Route::openapi_operation(
  self : Route,
  ctx : SchemaContext,
  names : Array[String],
  parameter_names : Array[String],
  catch_all : Array[Bool],
) -> Map[String, Json] raise OpenApiError {
  let (request, responses) = if self.schema is Some(schema) {
    schema(ctx)
  } else {
    ({}, { "default": { "description": "Response (schema not provided)" } })
  }
  guard request is Object(fields) && !fields.contains("responses") else {
    raise InvalidSchema(
      "Request schema must be an operation object without responses: \{self.path}",
    )
  }
  let operation = fields.copy()
  let parameters : Array[Json] = []
  let seen : Map[(String, String), Unit] = Map([])
  if operation.get("parameters") is Some(value) {
    guard value is Array(declared) else {
      raise InvalidSchema("parameters must be an array: \{self.path}")
    }
    for parameter in declared {
      guard ctx.resolve(parameter) is Object(fields) &&
        fields.get("name") is Some(String(name)) &&
        fields.get("in") is Some(String(location)) &&
        !name.is_empty() else {
        raise InvalidSchema("Expected a parameter object: \{self.path}")
      }
      let key = (
        location,
        if location == "header" {
          name.to_lower()
        } else {
          name
        },
      )
      guard !seen.contains(key) else {
        raise InvalidSchema("Duplicate parameter: \{location} \{name}")
      }
      seen[key] = ()
      if location == "path" {
        guard names.search(name) is Some(index) else {
          raise InvalidSchema("Unknown path parameter: \{name}")
        }
        guard !(fields.get("required") is Some(False)) else {
          raise InvalidSchema("Path parameter must be required: \{name}")
        }
        let fields = fields.copy()
        fields["name"] = @json.Json::string(parameter_names[index])
        fields["required"] = true
        if catch_all[index] {
          fields["x-moonback-catch-all"] = true
        }
        parameters.push(@json.Json::object(fields))
      } else {
        parameters.push(parameter)
      }
    }
  }
  for index, name in names {
    if seen.contains(("path", name)) {
      continue
    }
    let parameter : Map[String, Json] = {
      "name": @json.Json::string(parameter_names[index]),
      "in": "path",
      "required": true,
      "schema": {},
    }
    if catch_all[index] {
      parameter["x-moonback-catch-all"] = true
    }
    parameters.push(@json.Json::object(parameter))
  }
  if !parameters.is_empty() {
    operation["parameters"] = @json.Json::array(parameters)
  }
  if operation.get("requestBody") is Some(body) && !(body is Object(_)) {
    raise InvalidSchema("requestBody must be an object: \{self.path}")
  }
  operation["responses"] = self.openapi_responses(ctx, responses)
  operation
}

///|
fn Route::openapi_responses(
  self : Route,
  ctx : SchemaContext,
  schema : Json,
) -> Json raise OpenApiError {
  guard schema is Object(declared) && !declared.is_empty() else {
    raise InvalidSchema(
      "Response schema must be a nonempty responses object: \{self.path}",
    )
  }
  let responses : Map[String, Json] = Map([])
  let mut has_response = false
  for status, response in declared {
    if status.has_prefix("x-") {
      responses[status] = response
      continue
    }
    guard status == "default" ||
      status is (['1'..<='5', '0'..<='9', '0'..<='9'] | ['1'..<='5', 'X', 'X']) else {
      raise InvalidSchema("Invalid response status: \{status}")
    }
    guard ctx.resolve(response) is Object(fields) &&
      fields.get("description") is Some(String(_)) else {
      raise InvalidSchema(
        "Expected a response object with a description: \{status}",
      )
    }
    has_response = true
    if self.meth == Head {
      let fields = fields.copy()
      fields.remove("content")
      responses[status] = @json.Json::object(fields)
    } else {
      responses[status] = response
    }
  }
  guard has_response else {
    raise InvalidSchema(
      "Response schema must declare at least one response: \{self.path}",
    )
  }
  @json.Json::object(responses)
}
