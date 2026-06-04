module main

import vrpc
import users

fn main() {
	repo := users.new_memory_repo()
	mut app := vrpc.new()
	app.use(vrpc.logger())
	app.use(vrpc.cors())
	users.mount_user_service(mut app, users.new_service(repo))!
	app.openapi('/openapi.json')!
	app.docs('/docs')!
	app.listen(':3000')!
}
