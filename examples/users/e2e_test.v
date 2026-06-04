module main

import json
import net.http
import time
import vrpc
import users

// Single test fn: V runs test fns in parallel within a module.
fn test_users_e2e() {
	repo := users.new_memory_repo()
	mut svc := users.new_service(repo)
	mut app := vrpc.new()
	users.mount_user_service(mut app, mut svc)!
	app.openapi('/openapi.json')!

	base := app.listen_background('127.0.0.1:0')!
	defer {
		app.shutdown() or {}
	}
	time.sleep(200 * time.millisecond)

	create_res := http.fetch(
		url:    base + '/users'
		method: .post
		data:   '{"name":"Ada Lovelace","email":"ada@example.com"}'
		header: http.new_header(key: .content_type, value: 'application/json')
	)!
	assert create_res.status_code == 200
	created := json.decode(users.CreateUserResponse, create_res.body)!
	assert created.id != ''
	get_res := http.fetch(url: base + '/users/' + created.id, method: .get)!
	assert get_res.status_code == 200

	grace_res := http.fetch(
		url:    base + '/users'
		method: .post
		data:   '{"name":"Grace","email":"grace@example.com"}'
		header: http.new_header(key: .content_type, value: 'application/json')
	)!
	assert grace_res.status_code == 200
	list_res := http.fetch(url: base + '/users?limit=10', method: .get)!
	assert list_res.status_code == 200
	listed := json.decode(users.ListUsersResponse, list_res.body)!
	assert listed.users.len >= 1

	oapi_res := http.fetch(url: base + '/openapi.json', method: .get)!
	assert oapi_res.status_code == 200
	assert oapi_res.body.contains('"openapi"')

	bad_res := http.fetch(
		url:    base + '/users'
		method: .post
		data:   '{"name":"","email":"not-an-email"}'
		header: http.new_header(key: .content_type, value: 'application/json')
	)!
	assert bad_res.status_code == 400
	assert bad_res.body.contains('validation_failed')

	miss_res := http.fetch(url: base + '/users/does-not-exist', method: .get)!
	assert miss_res.status_code == 404
	assert miss_res.body.contains('User not found')
}
