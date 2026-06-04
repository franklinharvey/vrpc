module vrpc

fn test_validate_email() {
	errs := validate_field('email', 'not-an-email', [
		ValidatorDef{ rule: 'email', value: '' },
	])
	assert errs.len == 1
	assert errs[0].rule == 'email'
}

fn test_validate_required() {
	errs := validate_field('name', '', [
		ValidatorDef{ rule: 'required', value: '' },
	])
	assert errs.len == 1
}

fn test_validate_min_len() {
	errs := validate_field('name', 'a', [
		ValidatorDef{ rule: 'min_len', value: '2' },
	])
	assert errs.len == 1
}

fn test_collect_errors() {
	all := [
		ValidationError{ field: 'a', rule: 'required', message: 'a is required' },
		ValidationError{},
	]
	out := collect_errors(all)
	assert out.len == 1
}
