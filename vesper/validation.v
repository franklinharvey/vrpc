module vesper

pub fn validate_field(name string, value string, validators []ValidatorDef) []ValidationError {
	mut errs := []ValidationError{}
	for v in validators {
		match v.rule {
			'required' {
				if value.trim_space() == '' {
					errs << ValidationError{
						field:   name
						rule:    'required'
						message: '${name} is required'
					}
				}
			}
			'min_len' {
				min := v.value.int()
				if value.len < min {
					errs << ValidationError{
						field:   name
						rule:    'min_len'
						message: '${name} must be at least ${min} characters'
					}
				}
			}
			'max_len' {
				max := v.value.int()
				if value.len > max {
					errs << ValidationError{
						field:   name
						rule:    'max_len'
						message: '${name} must be at most ${max} characters'
					}
				}
			}
			'email' {
				if value != '' && !is_email(value) {
					errs << ValidationError{
						field:   name
						rule:    'email'
						message: '${name} must be a valid email address'
					}
				}
			}
			'uuid' {
				if value != '' && !is_uuid(value) {
					errs << ValidationError{
						field:   name
						rule:    'uuid'
						message: '${name} must be a valid UUID'
					}
				}
			}
			else {}
		}
	}
	return errs
}

pub fn validate_int_field(name string, value int, validators []ValidatorDef) []ValidationError {
	mut errs := []ValidationError{}
	for v in validators {
		match v.rule {
			'min' {
				min := v.value.int()
				if value < min {
					errs << ValidationError{
						field:   name
						rule:    'min'
						message: '${name} must be at least ${min}'
					}
				}
			}
			'max' {
				max := v.value.int()
				if value > max {
					errs << ValidationError{
						field:   name
						rule:    'max'
						message: '${name} must be at most ${max}'
					}
				}
			}
			else {}
		}
	}
	return errs
}

pub fn validate_schema_strings(fields map[string]string, schema Schema) []ValidationError {
	mut all := []ValidationError{}
	for sf in schema.fields {
		val := fields[sf.name] or { '' }
		all << validate_field(sf.name, val, sf.validators)
	}
	return all
}

fn is_email(s string) bool {
	at := s.index('@') or { return false }
	if at < 1 {
		return false
	}
	parts := s.split('@')
	return parts.len == 2 && parts[0].len > 0 && parts[1].contains('.')
}

fn is_uuid(s string) bool {
	if s.len != 36 {
		return false
	}
	for i, c in s {
		if i == 8 || i == 13 || i == 18 || i == 23 {
			if c != `-` {
				return false
			}
		} else {
			if !c.is_letter() && !c.is_digit() {
				return false
			}
		}
	}
	return true
}

// validate_from_schema runs validators for all fields in a schema against string/int maps.
pub fn validate_from_schema(schema Schema, strings map[string]string, ints map[string]int) []ValidationError {
	mut all := []ValidationError{}
	for sf in schema.fields {
		match sf.typ {
			'int', 'i32', 'i64' {
				val := ints[sf.name] or { 0 }
				if sf.required && sf.name !in ints {
					all << ValidationError{
						field:   sf.name
						rule:    'required'
						message: '${sf.name} is required'
					}
				}
				all << validate_int_field(sf.name, val, sf.validators)
			}
			else {
				val := strings[sf.name] or { '' }
				if sf.required && val.trim_space() == '' {
					all << ValidationError{
						field:   sf.name
						rule:    'required'
						message: '${sf.name} is required'
					}
				}
				all << validate_field(sf.name, val, sf.validators)
			}
		}
	}
	return all
}

pub fn validation_errors_or_ok(errs []ValidationError) ! {
	for e in errs {
		if e.message != '' {
			return error('validation_failed')
		}
	}
}

pub fn merge_errors(mut all []ValidationError, part []ValidationError) []ValidationError {
	all << part
	return all
}

pub fn collect_errors(errs []ValidationError) []ValidationError {
	mut out := []ValidationError{}
	for e in errs {
		if e.message != '' {
			out << e
		}
	}
	return out
}
