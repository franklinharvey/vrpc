module vrpc

pub enum SchemaKind {
	object
	string
	integer
	number
	boolean
	array
}

pub enum FieldSource {
	body
	path
	query
	header
}

pub struct ValidatorDef {
pub:
	rule  string
	value string
}

pub struct SchemaField {
pub:
	name       string
	typ        string
	source     FieldSource
	required   bool
	validators []ValidatorDef
	header_key string
}

pub struct Schema {
pub:
	name   string
	kind   SchemaKind
	fields []SchemaField
}

pub fn object_schema(name string, fields []SchemaField) Schema {
	return Schema{
		name:   name
		kind:   .object
		fields: fields
	}
}
