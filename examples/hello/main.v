module main

import vesper

fn hello_handler(mut ctx vesper.Context) !vesper.Response {
	return vesper.json_response({
		message: 'hello from vesper'
	})
}

fn main() {
	mut app := vesper.new()
	app.add_route(.get, '/hello', hello_handler)
	app.listen(':3001')!
}
