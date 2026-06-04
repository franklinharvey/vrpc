module main

import json
import net.http
import vrpc
import users

// OS-assigned port — required because V runs test fns in parallel on CI.
const test_addr = '127.0.0.1:0'

fn new_test_app() !&vrpc.App {
	repo := users.new_memory_repo()
	mut app := vrpc.new()
	users.mount_user_service(mut app, users.new_service(repo))!
	app.openapi('/openapi.json')!
	return app
}

fn test_e2e_create_and_get_user() {
	mut app := new_test_app()!
	base := app.listen_background(test_addr)!
	defer {
		app.shutdown() or {}
	}
	create_res := http.fetch(
		url:    base + '/users'
		method: .post
		data:   '{"name":"Ada Lovelace","email":"ada@example.com"}'
		header: http.new_header(key: .content_type, value: 'application/json')
	)!
	assert create_res.status_code == 200
	created := json.decode(users.CreateUserResponse, create_res.body)!
	assert created.name == 'Ada Lovelace'
	assert created.email == 'ada@example.com'
	assert created.id != ''
	get_res := http.fetch(url: base + '/users/' + created.id, method: .get)!
	assert get_res.status_code == 200
	fetched := json.decode(users.GetUserResponse, get_res.body)!
	assert fetched.id == created.id
	assert fetched.name == 'Ada Lovelace'
	assert fetched.email == 'ada@example.com'
}

fn test_e2e_list_users() {
	mut app := new_test_app()!
	base := app.listen_background(test_addr)!
	defer {
		app.shutdown() or {}
	}
	create_res := http.fetch(
		url:    base + '/users'
		method: .post
		data:   '{"name":"Grace","email":"grace@example.com"}'
		header: http.new_header(key: .content_type, value: 'application/json')
	)!
	assert create_res.status_code == 200
	list_res := http.fetch(url: base + '/users?limit=10', method: .get)!
	assert list_res.status_code == 200
	listed := json.decode(users.ListUsersResponse, list_res.body)!
	assert listed.users.len >= 1
}

fn test_e2e_openapi() {
	mut app := new_test_app()!
	base := app.listen_background(test_addr)!
	defer {
		app.shutdown() or {}
	}
	res := http.fetch(url: base + '/openapi.json', method: .get)!
	assert res.status_code == 200
	assert res.body.contains('"openapi"')
	assert res.body.contains('"paths"')
	assert res.body.contains('create_user')
}

fn test_e2e_validation_error() {
	mut app := new_test_app()!
	base := app.listen_background(test_addr)!
	defer {
		app.shutdown() or {}
	}
	res := http.fetch(
		url:    base + '/users'
		method: .post
		data:   '{"name":"","email":"not-an-email"}'
		header: http.new_header(key: .content_type, value: 'application/json')
	)!
	assert res.status_code == 400
	assert res.body.contains('validation_failed')
}

fn test_e2e_not_found() {
	mut app := new_test_app()!
	base := app.listen_background(test_addr)!
	defer {
		app.shutdown() or {}
	}
	res := http.fetch(url: base + '/users/does-not-exist', method: .get)!
	assert res.status_code == 404
	assert res.body.contains('User not found')
}
