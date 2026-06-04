module vrpc

import veetest

fn test_validation() ! {
	veetest.run(veetest.suite('validation', [
		veetest.case('email', fn () ! {
			errs := validate_field('email', 'not-an-email', [
				ValidatorDef{ rule: 'email', value: '' },
			])
			veetest.len_is('errors', errs, 1)!
			veetest.eq_str('rule', 'email', errs[0].rule)!
		}),
		veetest.case('required', fn () ! {
			errs := validate_field('name', '', [
				ValidatorDef{ rule: 'required', value: '' },
			])
			veetest.len_is('errors', errs, 1)!
		}),
		veetest.case('min_len', fn () ! {
			errs := validate_field('name', 'a', [
				ValidatorDef{ rule: 'min_len', value: '2' },
			])
			veetest.len_is('errors', errs, 1)!
		}),
		veetest.case('collect_errors', fn () ! {
			all := [
				ValidationError{ field: 'a', rule: 'required', message: 'a is required' },
				ValidationError{},
			]
			out := collect_errors(all)
			veetest.len_is('filtered', out, 1)!
		}),
	]))!
}
