module vrpc

struct HelloResp {
	ok bool
}

struct IdResp {
	id string
}

fn test_router() ! {
	vtest_run(vtest_suite('router', [
		vtest_case('match static route', fn () ! {
			mut r := new_router()
			r.add_route(.get, '/hello', fn (mut ctx Context) !Response {
				return json_response(HelloResp{ ok: true })
			})
			m := r.match_route(.get, '/hello') or { return error('no match') }
			vtest_eq_int('params.len', 0, m.params.len)!
		}),
		vtest_case('match path param', fn () ! {
			mut r := new_router()
			r.add_route(.get, '/users/:id', fn (mut ctx Context) !Response {
				return json_response(IdResp{ id: ctx.param('id') })
			})
			m := r.match_route(.get, '/users/u1') or { return error('no match') }
			vtest_eq_str('id', 'u1', m.params['id'])!
		}),
		vtest_case('normalize_service_path', fn () ! {
			vtest_eq_str('prefix only', '/users', normalize_service_path('/users', '/'))!
			vtest_eq_str('with param', '/users/:id', normalize_service_path('/users', '/:id'))!
		}),
	]))!
}
