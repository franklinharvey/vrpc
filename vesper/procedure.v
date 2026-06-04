module vesper

pub enum HttpMethod {
	get
	post
	put
	patch
	delete
}

pub fn http_method_from_str(s string) ?HttpMethod {
	match s.to_lower() {
		'get' { return .get }
		'post' { return .post }
		'put' { return .put }
		'patch' { return .patch }
		'delete' { return .delete }
		else { return none }
	}
}

pub fn (m HttpMethod) str() string {
	return match m {
		.get { 'GET' }
		.post { 'POST' }
		.put { 'PUT' }
		.patch { 'PATCH' }
		.delete { 'DELETE' }
	}
}

pub struct TransportBinding {
pub:
	method HttpMethod
	path   string
}

pub type ProcedureHandler = fn (mut Context) !Response

pub struct ProcedureDef {
pub:
	name          string
	input_schema  Schema
	output_schema Schema
	errors        []ErrorDef
	transport     TransportBinding
	handler       ProcedureHandler = unsafe { nil }
}

pub struct ErrorDef {
pub:
	code string
}
