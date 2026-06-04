module main

import json
import net.http
import time
import users
import veetest
import vrpc

struct UsersHttpEnv {
mut:
	app        &vrpc.App
	base       string
	created_id string
}

fn users_http_setup() ! &UsersHttpEnv {
	repo := users.new_memory_repo()
	mut svc := users.new_service(repo)
	mut app := vrpc.new()
	users.mount_user_service(mut app, mut svc)!
	app.openapi('/openapi.json')!
	base := app.listen_background('127.0.0.1:0')!
	time.sleep(200 * time.millisecond)
	return &UsersHttpEnv{
		app:  app
		base: base
	}
}

fn users_http_teardown(st &UsersHttpEnv) ! {
	mut app := st.app
	app.shutdown() or {}
}

fn test_users_http() ! {
	mut st := users_http_setup()!
	defer {
		users_http_teardown(st) or {}
	}
	veetest.run(veetest.suite('users/http', [
		veetest.case('POST /users creates user', fn [mut st] () ! {
			res := http.fetch(
				url:    st.base + '/users'
				method: .post
				data:   '{"name":"Ada Lovelace","email":"ada@example.com"}'
				header: http.new_header(key: .content_type, value: 'application/json')
			)!
			veetest.eq_int('status', 200, res.status_code)!
			created := json.decode(users.CreateUserResponse, res.body)!
			veetest.check(created.id != '', 'expected non-empty id')!
			st.created_id = created.id
		}),
		veetest.case('GET /users/:id returns user', fn [mut st] () ! {
			res := http.fetch(
				url:    st.base + '/users/' + st.created_id
				method: .get
			)!
			veetest.eq_int('status', 200, res.status_code)!
		}),
		veetest.case('GET /users lists users', fn [mut st] () ! {
			http.fetch(
				url:    st.base + '/users'
				method: .post
				data:   '{"name":"Grace","email":"grace@example.com"}'
				header: http.new_header(key: .content_type, value: 'application/json')
			)!
			list_res := http.fetch(url: st.base + '/users?limit=10', method: .get)!
			veetest.eq_int('status', 200, list_res.status_code)!
			listed := json.decode(users.ListUsersResponse, list_res.body)!
			veetest.check(listed.users.len >= 1, 'expected at least one user')!
		}),
		veetest.case('GET /openapi.json', fn [mut st] () ! {
			res := http.fetch(url: st.base + '/openapi.json', method: .get)!
			veetest.eq_int('status', 200, res.status_code)!
			veetest.contains('body', res.body, '"openapi"')!
		}),
		veetest.case('POST /users validation error', fn [mut st] () ! {
			res := http.fetch(
				url:    st.base + '/users'
				method: .post
				data:   '{"name":"","email":"not-an-email"}'
				header: http.new_header(key: .content_type, value: 'application/json')
			)!
			veetest.eq_int('status', 400, res.status_code)!
			veetest.contains('body', res.body, 'validation_failed')!
		}),
		veetest.case('GET /users/:id not found', fn [mut st] () ! {
			res := http.fetch(url: st.base + '/users/does-not-exist', method: .get)!
			veetest.eq_int('status', 404, res.status_code)!
			veetest.contains('body', res.body, 'User not found')!
		}),
	]))!
}
