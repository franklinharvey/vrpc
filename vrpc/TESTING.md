# Testing in vrpc

V ships a built-in test runner (`v test`); there is no widely adopted third-party framework with nested suites. vrpc adds a thin **vtest** layer in `vtest.v` (same `vrpc` module) for **named suites and cases**.

## Shape

- **Suite** — group name printed as `Suite: validation`
- **Case** — indented name printed as `  email ... ok`
- **Entrypoint** — still a `test_*` function in a `*_test.v` file so `v test` discovers it

## Example (in-module test)

```v
module vrpc

fn test_validation() ! {
	vtest_run(vtest_suite('validation', [
		vtest_case('email', fn () ! {
			errs := validate_field('email', 'bad', [
				ValidatorDef{ rule: 'email', value: '' },
			])
			vtest_len_is('errors', errs, 1)!
		}),
	]))!
}
```

## Example (external / e2e)

```v
import vrpc

fn test_users_http() ! {
	vrpc.vtest_run(vrpc.vtest_suite('users/http', [
		vrpc.vtest_case('POST /users', fn () ! { ... }),
	]))!
}
```

## Setup / teardown

```v
vrpc.vtest_run(vrpc.VtestSuite{
	name: 'users/http'
	setup: start_server
	teardown: stop_server
	cases: [ ... ],
})!
```

## Helpers

`vtest_check`, `vtest_eq_str`, `vtest_eq_int`, `vtest_contains`, `vtest_len_is` — return `!` errors with labels instead of bare asserts.

## Commands

```bash
cd vrpc && v -cc gcc test .
v -cc gcc test validation_test.v
cd ../examples/users && v -cc gcc test .
```

V also supports `testsuite_begin` / `testsuite_end` per `_test.v` file for file-level hooks.
