// Core runner: suites, cases, setup/teardown. Built on V's `v test` entrypoints.
module veetest

pub type VeetestFn = fn () !

pub type VeetestSetupFn = fn () !

pub type VeetestTeardownFn = fn () !

pub struct VeetestCase {
pub:
	name string
	run  VeetestFn = unsafe { nil }
}

pub struct VeetestSuite {
pub:
	name     string
	setup    ?VeetestSetupFn
	teardown ?VeetestTeardownFn
	cases    []VeetestCase
}

pub fn case(name string, run VeetestFn) VeetestCase {
	return VeetestCase{
		name: name
		run:  run
	}
}

pub fn suite(name string, cases []VeetestCase) VeetestSuite {
	return VeetestSuite{
		name:  name
		cases: cases
	}
}

pub fn run(s VeetestSuite) ! {
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
