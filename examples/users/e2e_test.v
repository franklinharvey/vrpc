module main

import json
import net.http
import time
import users
import vrpc

struct UsersHttpEnv {
mut:
	app        &vrpc.App
	base       string
	created_id string
}

fn users_http_setup(mut st &UsersHttpEnv) ! {
	repo := users.new_memory_repo()
	mut svc := users.new_service(repo)
	mut app := vrpc.new()
	users.mount_user_service(mut app, mut svc)!
	app.openapi('/openapi.json')!
	base := app.listen_background('127.0.0.1:0')!
	st.app = app
	st.base = base
	time.sleep(200 * time.millisecond)
}

fn users_http_teardown(st &UsersHttpEnv) ! {
	st.app.shutdown() or {}
}

fn test_users_http() ! {
	mut st := UsersHttpEnv{
		app: unsafe { nil }
	}
	users_http_setup(mut st)!
	defer {
		users_http_teardown(st) or {}
	}
	vrpc.vtest_run(vrpc.vtest_suite('users/http', [
		vrpc.vtest_case('POST /users creates user', fn [mut st] () ! {
			res := http.fetch(
				url:    st.base + '/users'
				method: .post
				data:   '{"name":"Ada Lovelace","email":"ada@example.com"}'
				header: http.new_header(key: .content_type, value: 'application/json')
			)!
			vrpc.vtest_eq_int('status', 200, res.status_code)!
			created := json.decode(users.CreateUserResponse, res.body)!
			vrpc.vtest_check(created.id != '', 'expected non-empty id')!
			st.created_id = created.id
		}),
		vrpc.vtest_case('GET /users/:id returns user', fn [mut st] () ! {
			res := http.fetch(
				url:    st.base + '/users/' + st.created_id
				method: .get
			)!
			vrpc.vtest_eq_int('status', 200, res.status_code)!
		}),
		vrpc.vtest_case('GET /users lists users', fn [mut st] () ! {
			http.fetch(
				url:    st.base + '/users'
				method: .post
				data:   '{"name":"Grace","email":"grace@example.com"}'
				header: http.new_header(key: .content_type, value: 'application/json')
			)!
			list_res := http.fetch(url: st.base + '/users?limit=10', method: .get)!
			vrpc.vtest_eq_int('status', 200, list_res.status_code)!
			listed := json.decode(users.ListUsersResponse, list_res.body)!
			vrpc.vtest_check(listed.users.len >= 1, 'expected at least one user')!
		}),
		vrpc.vtest_case('GET /openapi.json', fn [mut st] () ! {
			res := http.fetch(url: st.base + '/openapi.json', method: .get)!
			vrpc.vtest_eq_int('status', 200, res.status_code)!
			vrpc.vtest_contains('body', res.body, '"openapi"')!
		}),
		vrpc.vtest_case('POST /users validation error', fn [mut st] () ! {
			res := http.fetch(
				url:    st.base + '/users'
				method: .post
				data:   '{"name":"","email":"not-an-email"}'
				header: http.new_header(key: .content_type, value: 'application/json')
			)!
			vrpc.vtest_eq_int('status', 400, res.status_code)!
			vrpc.vtest_contains('body', res.body, 'validation_failed')!
		}),
		vrpc.vtest_case('GET /users/:id not found', fn [mut st] () ! {
			res := http.fetch(url: st.base + '/users/does-not-exist', method: .get)!
			vrpc.vtest_eq_int('status', 404, res.status_code)!
			vrpc.vtest_contains('body', res.body, 'User not found')!
		}),
	]))!
}
