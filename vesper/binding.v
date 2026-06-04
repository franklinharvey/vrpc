module vesper

import json

// Runtime helpers used by generated binders.

pub fn bind_path_param(ctx Context, name string) string {
	return ctx.param(name)
}

pub fn bind_query_param(ctx Context, name string) string {
	return ctx.query_param(name)
}

pub fn bind_header(ctx Context, name string) string {
	return ctx.header(name)
}

pub fn bind_body[T](ctx Context) !T {
	return json.decode(T, ctx.request.body)!
}

pub fn query_int(ctx Context, name string, default_val int) int {
	s := ctx.query_param(name)
	if s == '' {
		return default_val
	}
	return s.int()
}
