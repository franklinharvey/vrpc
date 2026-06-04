module main

import vesper
import users

fn main() {
	repo := users.new_memory_repo()
	mut app := vesper.new()
	app.use(vesper.logger())
	app.use(vesper.cors())
	users.mount_user_service(mut app, users.new_service(repo))!
	app.openapi('/openapi.json')!
	app.docs('/docs')!
	app.listen(':3000')!
}
