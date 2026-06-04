module main

import strings as strutil

pub fn emit_openapi(service Service) GeneratedFile {
	return GeneratedFile{
		path:    'openapi.json'
		content: openapi_json(service)
	}
}

pub fn openapi_json(service Service) string {
	return build_oapi_json(service)
}

fn build_oapi_json(service Service) string {
	mut b := strutil.Builder{}
	b.writeln('{')
	b.writeln('  "openapi": "3.0.3",')
	title := if service.name != '' { service.name } else { 'Vesper API' }
	b.writeln('  "info": { "title": "${json_escape(title)}", "version": "0.1.0" },')
	b.writeln('  "paths": ${oapi_paths_json(service)},')
	b.writeln('  "components": { "schemas": ${oapi_schemas_json(service)} }')
	b.writeln('}')
	return b.str().trim_space()
}

fn oapi_paths_json(service Service) string {
	mut path_map := map[string][]string{}
	for proc in service.procedures {
		full := join_http_path(service.prefix, proc.path)
		oapi_path := path_to_openapi_path(full)
		input := service.types[proc.input_type] or { TypeDef{ name: proc.input_type } }
		path_map[oapi_path] << oapi_operation_json(proc, input)
	}
	mut keys := path_map.keys()
	keys.sort()
	mut parts := []string{}
	for key in keys {
		ops := path_map[key]
		parts << '    "${json_escape(key)}": { ${ops.join(', ')} }'
	}
	return '{\n${parts.join(',\n')}\n  }'
}

fn oapi_operation_json(proc Procedure, input TypeDef) string {
	params := oapi_parameters_json(input)
	has_body := has_oapi_body(input)
	mut lines := []string{}
	lines << '"operation_id": "${json_escape(proc.name)}"'
	lines << '"has_body": ${has_body}'
	lines << '"request_name": "${json_escape(proc.input_type)}"'
	lines << '"parameters": ${params}'
	lines << '"responses": { "200": { "description": "Success" }, "400": { "description": "Validation error" }, "500": { "description": "Internal error" } }'
	return '"${proc.method.str()}": { ${lines.join(', ')} }'
}

fn oapi_parameters_json(st TypeDef) string {
	mut parts := []string{}
	for f in st.fields {
		if f.source == .path {
			parts << '{ "name": "${json_escape(f.name)}", "in": "path", "required": ${f.required}, "schema": { "type": "string" } }'
		} else if f.source == .query {
			parts << '{ "name": "${json_escape(f.name)}", "in": "query", "required": ${f.required}, "schema": { "type": "${kind_to_oapi(f.kind)}" } }'
		}
	}
	return '[${parts.join(', ')}]'
}

fn oapi_schemas_json(service Service) string {
	mut names := service.types.keys()
	names.sort()
	mut parts := []string{}
	for name in names {
		st := service.types[name]
		parts << '    "${json_escape(name)}": ${oapi_type_json(st, service.types)}'
	}
	return '{\n${parts.join(',\n')}\n  }'
}

fn oapi_type_json(st TypeDef, all map[string]TypeDef) string {
	mut prop_parts := []string{}
	mut required := []string{}
	for f in st.fields {
		prop_parts << '"${json_escape(f.name)}": ${oapi_field_json(f, all)}'
		if f.required {
			required << '"${json_escape(f.name)}"'
		}
	}
	mut lines := []string{}
	lines << '"type": "object"'
	lines << '"properties": { ${prop_parts.join(', ')} }'
	if required.len > 0 {
		lines << '"required": [${required.join(', ')}]'
	}
	return '{ ${lines.join(', ')} }'
}

fn oapi_field_json(f Field, all map[string]TypeDef) string {
	if f.kind == .array {
		return '{ "type": "array", "items": ${oapi_named_type_json(f.array_elem, all)} }'
	}
	return '{ "type": "${kind_to_oapi(f.kind)}" }'
}

fn oapi_named_type_json(name string, all map[string]TypeDef) string {
	if st := all[name] {
		return oapi_type_json(st, all)
	}
	return '{ "type": "string" }'
}

fn path_to_openapi_path(path string) string {
	mut out := ''
	for part in path.split('/') {
		if part == '' {
			continue
		}
		if part.starts_with(':') {
			out += '/{${part[1..]}}'
		} else {
			out += '/${part}'
		}
	}
	if out == '' {
		return '/'
	}
	return out
}

fn kind_to_oapi(k TypeKind) string {
	return match k {
		.int { 'integer' }
		.f64 { 'number' }
		.bool { 'boolean' }
		else { 'string' }
	}
}

fn has_oapi_body(st TypeDef) bool {
	for f in st.fields {
		if f.source == .body {
			return true
		}
	}
	return false
}

fn json_escape(s string) string {
	return s.replace('\\', '\\\\').replace('"', '\\"')
}
