module main

import vrpc

fn hello_handler(mut ctx vrpc.Context) !vrpc.Response {
	return vrpc.json_response({
		message: 'hello from vrpc'
	})
}

fn main() {
	mut app := vrpc.new()
	app.add_route(.get, '/hello', hello_handler)
	app.listen(':3001')!
}
