module vrpc

import net
import net.http
import time

@[heap]
pub struct AppConfig {
pub:
	name    string
	version string
}

@[heap]
pub struct App {
mut:
	router         Router
	services       []ServiceDef
	middleware     []Middleware
	config         AppConfig
	openapi_path   string
	docs_path      string
	http_server    http.Server
	server_thread  ?thread
}

pub struct VrpcHandler {
	app &App
}

pub fn new() &App {
	return &App{}
}

pub fn (mut app App) use(mw Middleware) {
	app.middleware << mw
}

pub fn (mut app App) add_route(method HttpMethod, path string, handler ProcedureHandler) {
	app.router.add_route(method, path, handler)
}

pub fn (mut app App) openapi(path string) ! {
	app.openapi_path = path
	app.router.add_route(.get, path, fn [app] (mut ctx Context) !Response {
		doc := build_openapi_document(app.services)
		return json_response(doc)
	})
}

pub fn (mut app App) docs(path string) ! {
	app.docs_path = path
	app.router.add_route(.get, path, fn [app] (mut ctx Context) !Response {
		return html(swagger_ui_html(app.openapi_path), 200)
	})
}

pub fn (mut app App) listen(addr string) ! {
	app.start_server(addr)!
	app.http_server.listen_and_serve()
}

// listen_background starts the server on a background thread (for tests).
// Returns the base URL, e.g. http://127.0.0.1:54321
pub fn (mut app App) listen_background(addr string) !string {
	listener := net.listen_tcp(.ip, addr)!
	app.start_server_with_listener(listener)!
	app.http_server.show_startup_message = false
	mut server := &app.http_server
	app.server_thread = spawn server.listen_and_serve()
	app.http_server.wait_till_running()!
	bound := listener.addr() or { return error('could not resolve bound address') }
	return base_url_from_addr(bound.str())
}

fn base_url_from_addr(addr string) string {
	if addr.starts_with(':') {
		return 'http://127.0.0.1${addr}'
	}
	return 'http://${addr}'
}

pub fn (mut app App) shutdown() ! {
	app.http_server.close()
	if t := app.server_thread {
		t.wait()
		app.server_thread = none
	}
}

fn (mut app App) start_server(addr string) ! {
	listener := net.listen_tcp(.ip, addr)!
	app.start_server_with_listener(listener)!
}

fn (mut app App) start_server_with_listener(listener net.TcpListener) ! {
	handler := VrpcHandler{
		app: app
	}
	bound := listener.addr()!
	app.http_server = http.Server{
		addr:           bound.str()
		handler:        handler
		listener:       listener
		accept_timeout: 2 * time.second
	}
}

pub fn (h VrpcHandler) handle(req http.Request) http.Response {
	mut app := h.app
	method := http_method_from_str(req.method.str()) or {
		mut resp := http.Response{}
		resp.status_code = 405
		return resp
	}
	mut path := req.url
	if q := path.index('?') {
		path = path[..q]
	}
	match_result := app.router.match_route(method, path) or {
		body := '{"error":{"code":"not_found","message":"Not found"}}'
		mut resp := http.Response{
			body:        body
			status_code: 404
		}
		resp.header.add_custom('Content-Type', 'application/json') or {}
		return resp
	}
	mut ctx := Context{
		request: request_from_http(req)
	}
	for k, v in match_result.params {
		ctx.set_param(k, v)
	}
	handler_fn := match_result.handler
	final_handler := fn [handler_fn] (mut c Context) !Response {
		return handler_fn(mut c)!
	}
	result := run_middleware_stack(mut ctx, app.middleware, final_handler) or {
		return error_to_response(err).to_http()
	}
	return result.to_http()
}

fn swagger_ui_html(openapi_path string) string {
	return '<!DOCTYPE html><html><head><title>Vrpc API Docs</title></head><body>
<h1>Vrpc API</h1>
<p><a href="${openapi_path}">OpenAPI JSON</a></p>
</body></html>'
}
