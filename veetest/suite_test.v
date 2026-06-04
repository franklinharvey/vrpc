module veetest

struct MetaState {
mut:
	ran_setup    bool
	ran_teardown bool
}

fn test_runner() ! {
	mut st := &MetaState{}
	run(VeetestSuite{
		name: 'meta'
		setup: fn [mut st] () ! {
			st.ran_setup = true
		}
		teardown: fn [mut st] () ! {
			st.ran_teardown = true
		}
		cases: [
			case('passes', fn () ! {
				check(true, 'ok')!
			}),
			case('eq', fn () ! {
				eq_int('n', 2, 1 + 1)!
			}),
		],
	})!
	check(st.ran_setup, 'setup should run')!
	check(st.ran_teardown, 'teardown should run')!
}

fn test_runner_reports_failures() ! {
	run(suite('fail', [
		case('bad', fn () ! {
			return error('on purpose')
		}),
	])) or {
		contains('err', err.msg(), 'fail / bad')!
		return
	}
	return error('expected suite to fail')
}
