module vrpc

import net.http
import json

pub fn client_get(url string) !string {
	req := http.new_request(.get, url, '')
	res := req.do() or { return err }
	if res.status_code < 200 || res.status_code >= 300 {
		return error('HTTP ${res.status_code}: ${res.body}')
	}
	return res.body
}

pub fn client_post_json[T](url string, body T) !string {
	data := json.encode(body)
	mut req := http.new_request(.post, url, data)
	req.header.set(.content_type, 'application/json')
	res := req.do() or { return err }
	if res.status_code < 200 || res.status_code >= 300 {
		return error('HTTP ${res.status_code}: ${res.body}')
	}
	return res.body
}

pub fn decode_response[T](body string) !T {
	return json.decode(T, body)!
}
