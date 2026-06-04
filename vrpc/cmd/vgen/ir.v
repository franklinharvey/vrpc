module main

pub enum HttpMethod {
	get
	post
	put
	patch
	delete
}

pub enum FieldSource {
	body
	path
	query
	header
}

pub enum TypeKind {
	string
	int
	bool
	f64
	array
	object
}

pub struct Validator {
pub:
	rule  string
	value string
}

pub struct Field {
pub:
	name       string
	kind       TypeKind
	array_elem string
	source     FieldSource
	required   bool
	header_key string
	validators []Validator
}

pub struct TypeDef {
pub:
	name   string
	fields []Field
}

pub struct Procedure {
pub:
	name        string
	method      HttpMethod
	path        string
	input_type  string
	output_type string
}

pub struct Service {
pub mut:
	name       string
	prefix     string
	module     string
	procedures []Procedure
	types      map[string]TypeDef
}

pub struct GeneratedFile {
pub:
	path    string
	content string
}

pub struct EmitOptions {
pub:
	out_dir       string
	ts_out_subdir string = 'generated/ts'
}

pub fn http_method_from_str(s string) ?HttpMethod {
	return match s.to_lower() {
		'get' { .get }
		'post' { .post }
		'put' { .put }
		'patch' { .patch }
		'delete' { .delete }
		else { none }
	}
}

pub fn (m HttpMethod) str() string {
	return match m {
		.get { 'get' }
		.post { 'post' }
		.put { 'put' }
		.patch { 'patch' }
		.delete { 'delete' }
	}
}

pub fn (m HttpMethod) upper() string {
	return m.str().to_upper()
}

pub fn field_source_from_str(s string) FieldSource {
	return match s {
		'path' { .path }
		'query' { .query }
		'header' { .header }
		else { .body }
	}
}

pub fn type_kind_from_v(typ string) TypeKind {
	if typ.starts_with('[]') {
		return .array
	}
	return match typ {
		'int', 'i32', 'i64' { .int }
		'bool' { .bool }
		'f32', 'f64' { .f64 }
		else { .string }
	}
}

pub fn array_element_type(typ string) string {
	if typ.starts_with('[]') {
		return typ[2..]
	}
	return ''
}

pub fn join_http_path(prefix string, sub string) string {
	mut p := prefix
	if !p.starts_with('/') {
		p = '/${p}'
	}
	sub_trim := sub.trim_space()
	if sub_trim == '' || sub_trim == '/' {
		return p
	}
	if sub_trim.starts_with('/') {
		return p + sub_trim
	}
	return '${p}/${sub_trim}'
}

pub fn path_to_template(prefix string, sub string) string {
	full := join_http_path(prefix, sub)
	mut out := ''
	for part in full.split('/') {
		if part == '' {
			continue
		}
		if part.starts_with(':') {
			out += '/$' + '{' + part[1..] + '}'
		} else {
			out += '/${part}'
		}
	}
	if out == '' {
		return '/'
	}
	return out
}

pub fn service_base_name(service_name string) string {
	return service_name.replace('Service', '')
}

pub fn snake_case(s string) string {
	if s.contains('_') {
		return s.to_lower()
	}
	mut out := ''
	for i, c in s {
		is_upper := c >= `A` && c <= `Z`
		if is_upper && i > 0 {
			out += '_'
		}
		out += if is_upper { c.ascii_str().to_lower() } else { c.ascii_str() }
	}
	return out
}

pub fn camel_case(s string) string {
	parts := s.split('_')
	if parts.len == 0 {
		return s
	}
	mut out := parts[0]
	for i := 1; i < parts.len; i++ {
		p := parts[i]
		if p.len > 0 {
			out += p[0].ascii_str().to_upper() + p[1..]
		}
	}
	return out
}
