///|
pub(all) struct ViaJson[T](T)

///|
pub impl[A : FromJson] FromParam for ViaJson[A] with fn from_param(arr) {
  let map = Map([])
  for (k, v) in arr {
    map[k.to_owned()] = @json.Json::string(v.to_owned())
  }
  (@json.from_json(@json.Json::object(map)) : A) catch {
    e => raise ParamMismatch(e.to_string())
  }
}

///|
pub impl[A : FromJson] FromQueries for ViaJson[A] with fn from_queries(query) {
  let map = Map([])
  for (name, value) in query.iter() {
    map[name] = @json.Json::string(value)
  }
  let value : A = @json.from_json(@json.Json::object(map)) catch {
    error => raise QueryMismatch(error.to_string())
  }
  ViaJson(value)
}
