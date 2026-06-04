module vesper

struct HelloResp {
	ok bool
}

struct IdResp {
	id string
}

fn test_route_match_static() {
	mut r := new_router()
	r.add_route(.get, '/hello', fn (mut ctx Context) !Response {
		return json_response(HelloResp{ ok: true })
	})
	m := r.match_route(.get, '/hello') or { panic('no match') }
	assert m.params.len == 0
}

fn test_route_match_param() {
	mut r := new_router()
	r.add_route(.get, '/users/:id', fn (mut ctx Context) !Response {
		return json_response(IdResp{ id: ctx.param('id') })
	})
	m := r.match_route(.get, '/users/u1') or { panic('no match') }
	assert m.params['id'] == 'u1'
}

fn test_normalize_service_path() {
	assert normalize_service_path('/users', '/') == '/users'
	assert normalize_service_path('/users', '/:id') == '/users/:id'
}
