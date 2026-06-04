module vrpc

pub struct RouteSegment {
pub:
	value    string
	is_param bool
}

pub struct Route {
pub:
	method  HttpMethod
	path    string
	segments []RouteSegment
	handler ProcedureHandler = unsafe { nil }
}

pub struct Router {
mut:
	routes []Route
}

pub fn new_router() Router {
	return Router{}
}

pub fn compile_path(path string) []RouteSegment {
	mut segments := []RouteSegment{}
	for part in path.split('/') {
		if part == '' {
			continue
		}
		if part.starts_with(':') {
			segments << RouteSegment{
				value:    part[1..]
				is_param: true
			}
		} else {
			segments << RouteSegment{
				value:    part
				is_param: false
			}
		}
	}
	return segments
}

pub fn (mut r Router) add_route(method HttpMethod, path string, handler ProcedureHandler) {
	r.routes << Route{
		method:   method
		path:     path
		segments: compile_path(path)
		handler:  handler
	}
}

pub struct MatchResult {
pub:
	handler ProcedureHandler = unsafe { nil }
	params  map[string]string
}

pub fn (r Router) match_route(method HttpMethod, path string) ?MatchResult {
	path_segments := compile_path(path)
	for route in r.routes {
		if route.method != method {
			continue
		}
		if route.segments.len != path_segments.len {
			continue
		}
		mut params := map[string]string{}
		mut ok := true
		for i, seg in route.segments {
			actual := path_segments[i]
			if seg.is_param {
				params[seg.value] = actual.value
			} else if seg.value != actual.value {
				ok = false
				break
			}
		}
		if ok {
			return MatchResult{
				handler: route.handler
				params:  params
			}
		}
	}
	return none
}
