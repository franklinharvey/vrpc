module vesper

import json

pub struct OpenAPIDocument {
pub:
	openapi    string                 = '3.0.3'
	info       OpenAPIInfo
	paths      map[string]OpenAPIPathItem
	components OpenAPIComponents
}

pub struct OpenAPIInfo {
pub:
	title   string
	version string
}

pub struct OpenAPIComponents {
pub:
	schemas map[string]OpenAPISchema
}

pub struct OpenAPIPathItem {
pub mut:
	operations map[string]OpenAPIOperation
}

pub struct OpenAPIOperation {
pub:
	operation_id  string
	has_body      bool
	request_name  string
	parameters    []OpenAPIParameter
	responses     map[string]OpenAPIResponse
}

pub struct OpenAPIParameter {
pub:
	name     string
	in_      string
	required bool
	schema   OpenAPISchema
}

pub struct OpenAPIResponse {
pub:
	description string
}

pub struct OpenAPISchema {
pub:
	type_      string
	properties map[string]OpenAPISchema
	required   []string
}

pub fn build_openapi_document(services []ServiceDef) OpenAPIDocument {
	mut paths := map[string]OpenAPIPathItem{}
	mut schemas := map[string]OpenAPISchema{}
	for service in services {
		for proc in service.procedures {
			full := normalize_service_path(service.prefix, proc.transport.path)
			oapi_path := path_to_openapi(full)
			schemas[proc.input_schema.name] = schema_to_openapi(proc.input_schema)
			schemas[proc.output_schema.name] = schema_to_openapi(proc.output_schema)
			mut op := OpenAPIOperation{
				operation_id: proc.name
				has_body:     has_body_fields(proc.input_schema)
				request_name: proc.input_schema.name
				parameters:   path_params_from_schema(proc.input_schema)
				responses: {
					'200': OpenAPIResponse{ description: 'Success' }
					'400': OpenAPIResponse{ description: 'Validation error' }
					'500': OpenAPIResponse{ description: 'Internal error' }
				}
			}
			mut item := paths[oapi_path] or { OpenAPIPathItem{ operations: map[string]OpenAPIOperation{} } }
			item.operations[proc.transport.method.str().to_lower()] = op
			paths[oapi_path] = item
		}
	}
	return OpenAPIDocument{
		info: OpenAPIInfo{
			title:   'Vesper API'
			version: '0.1.0'
		}
		paths:      paths
		components: OpenAPIComponents{ schemas: schemas }
	}
}

pub fn openapi_json(services []ServiceDef) string {
	return json.encode(build_openapi_document(services))
}

fn path_to_openapi(path string) string {
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

fn schema_to_openapi(schema Schema) OpenAPISchema {
	mut props := map[string]OpenAPISchema{}
	mut required := []string{}
	for f in schema.fields {
		props[f.name] = OpenAPISchema{ type_: v_type_to_openapi(f.typ) }
		if f.required {
			required << f.name
		}
	}
	return OpenAPISchema{
		type_:      'object'
		properties: props
		required:   required
	}
}

fn v_type_to_openapi(typ string) string {
	return match typ {
		'int', 'i32', 'i64' { 'integer' }
		'f32', 'f64' { 'number' }
		'bool' { 'boolean' }
		else { 'string' }
	}
}

fn has_body_fields(schema Schema) bool {
	for f in schema.fields {
		if f.source == .body {
			return true
		}
	}
	return false
}

fn path_params_from_schema(schema Schema) []OpenAPIParameter {
	mut params := []OpenAPIParameter{}
	for f in schema.fields {
		if f.source == .path {
			params << OpenAPIParameter{
				name:     f.name
				in_:      'path'
				required: f.required
				schema:   OpenAPISchema{ type_: 'string' }
			}
		} else if f.source == .query {
			params << OpenAPIParameter{
				name:     f.name
				in_:      'query'
				required: f.required
				schema:   OpenAPISchema{ type_: v_type_to_openapi(f.typ) }
			}
		}
	}
	return params
}
