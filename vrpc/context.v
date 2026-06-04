module vrpc

import net.http

pub struct Request {
pub:
	method  string
	path    string
	body    string
	headers map[string]string
	query   map[string]string
mut:
	params map[string]string
}

@[heap]
pub struct Context {
mut:
	request  Request
	response Response
	state    map[string]string
}

pub fn (ctx Context) header(name string) string {
	return ctx.request.headers[name.to_lower()] or { '' }
}

pub fn (ctx Context) param(name string) string {
	return ctx.request.params[name] or { '' }
}

pub fn (ctx Context) query_param(name string) string {
	return ctx.request.query[name] or { '' }
}

pub fn request_from_http(req http.Request) Request {
	mut headers := map[string]string{}
	for key in req.header.keys() {
		if val := req.header.get_custom(key) {
			headers[key.to_lower()] = val
		}
	}
	mut path := req.url
	mut query := map[string]string{}
	if q := path.index('?') {
		path = path[..q]
		qs := req.url[q + 1..]
		for pair in qs.split('&') {
			if pair == '' {
				continue
			}
			parts := pair.split_nth('=', 2)
			if parts.len == 2 {
				query[parts[0]] = parts[1].replace('+', ' ')
			} else if parts.len == 1 {
				query[parts[0]] = ''
			}
		}
	}
	return Request{
		method:  req.method.str()
		path:    path
		body:    req.data
		headers: headers
		params:  map[string]string{}
		query:   query
	}
}

pub fn (mut ctx Context) set_param(name string, value string) {
	ctx.request.params[name] = value
}
