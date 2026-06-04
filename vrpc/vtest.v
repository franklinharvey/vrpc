// Named suites and cases for vrpc tests (used from *_test.v via `v test`).
module vrpc

pub type VtestFn = fn () !

pub type VtestSetupFn = fn () !

pub type VtestTeardownFn = fn () !

pub struct VtestCase {
pub:
	name string
	run  VtestFn = unsafe { nil }
}

pub struct VtestSuite {
pub:
	name     string
	setup    ?VtestSetupFn
	teardown ?VtestTeardownFn
	cases    []VtestCase
}

pub fn vtest_case(name string, run VtestFn) VtestCase {
	return VtestCase{
		name: name
		run:  run
	}
}

pub fn vtest_suite(name string, cases []VtestCase) VtestSuite {
	return VtestSuite{
		name:  name
		cases: cases
	}
}

pub fn vtest_run(s VtestSuite) ! {
	if setup := s.setup {
		setup() or {
			return error('suite "${s.name}" setup: ${err.msg()}')
		}
	}
	mut teardown_err := ''
	if td := s.teardown {
		defer {
			td() or {
				teardown_err = err.msg()
			}
		}
	}
	mut failures := []string{}
	println('Suite: ${s.name}')
	for c in s.cases {
		print('  ${c.name} ... ')
		c.run() or {
			println('FAIL')
			eprintln('    ${err.msg()}')
			failures << '${s.name} / ${c.name}: ${err.msg()}'
			continue
		}
		println('ok')
	}
	if teardown_err != '' {
		return error('suite "${s.name}" teardown: ${teardown_err}')
	}
	if failures.len > 0 {
		return error('${failures.len} case(s) failed:\n${failures.join('\n')}')
	}
}

pub fn vtest_check(ok bool, msg string) ! {
	if !ok {
		return error(msg)
	}
}

pub fn vtest_eq_str(label string, want string, got string) ! {
	if want != got {
		return error('${label}: want "${want}", got "${got}"')
	}
}

pub fn vtest_eq_int(label string, want int, got int) ! {
	if want != got {
		return error('${label}: want ${want}, got ${got}')
	}
}

pub fn vtest_contains(label string, haystack string, needle string) ! {
	if !haystack.contains(needle) {
		return error('${label}: expected to contain "${needle}"')
	}
}

pub fn vtest_len_is[T](label string, got []T, want int) ! {
	if got.len != want {
		return error('${label}: want len ${want}, got ${got.len}')
	}
}
