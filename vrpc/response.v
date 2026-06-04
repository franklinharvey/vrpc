module vrpc

import json
import net.http

pub struct Response {
pub:
	status int    = 200
	body   string
pub mut:
	headers map[string]string
}

pub fn json_response[T](data T) Response {
	return Response{
		status: 200
		body:   json.encode(data)
		headers: {
			'Content-Type': 'application/json'
		}
	}
}

pub fn text(body string, status int) Response {
	return Response{
		status: status
		body:   body
		headers: {
			'Content-Type': 'text/plain'
		}
	}
}

pub fn html(body string, status int) Response {
	return Response{
		status: status
		body:   body
		headers: {
			'Content-Type': 'text/html'
		}
	}
}

pub fn (mut r Response) add_cors() {
	if r.headers.len == 0 {
		r.headers = map[string]string{}
	}
	r.headers['Access-Control-Allow-Origin'] = '*'
	r.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
	r.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
}

pub fn (r Response) to_http() http.Response {
	mut resp := http.Response{
		body:        r.body
		status_code: r.status
	}
	for key, value in r.headers {
		resp.header.add_custom(key, value) or {}
	}
	return resp
}

// json_response is used by generated handlers; json_encode alias avoided (conflicts with import).
pub fn json_encode_response[T](data T) Response {
	return json_response(data)
}
