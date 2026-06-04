module vrpc

fn test_validation() ! {
	vtest_run(vtest_suite('validation', [
		vtest_case('email', fn () ! {
			errs := validate_field('email', 'not-an-email', [
				ValidatorDef{ rule: 'email', value: '' },
			])
			vtest_len_is('errors', errs, 1)!
			vtest_eq_str('rule', 'email', errs[0].rule)!
		}),
		vtest_case('required', fn () ! {
			errs := validate_field('name', '', [
				ValidatorDef{ rule: 'required', value: '' },
			])
			vtest_len_is('errors', errs, 1)!
		}),
		vtest_case('min_len', fn () ! {
			errs := validate_field('name', 'a', [
				ValidatorDef{ rule: 'min_len', value: '2' },
			])
			vtest_len_is('errors', errs, 1)!
		}),
		vtest_case('collect_errors', fn () ! {
			all := [
				ValidationError{ field: 'a', rule: 'required', message: 'a is required' },
				ValidationError{},
			]
			out := collect_errors(all)
			vtest_len_is('filtered', out, 1)!
		}),
	]))!
}
