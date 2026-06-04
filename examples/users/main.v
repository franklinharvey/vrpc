module main

import vrpc
import users

fn main() {
	repo := users.new_memory_repo()
	mut svc := users.new_service(repo)
	mut app := vrpc.new()
	app.use(vrpc.logger())
	app.use(vrpc.cors())
	users.mount_user_service(mut app, mut svc)!
	app.openapi('/openapi.json')!
	app.docs('/docs')!
	app.listen(':3000')!
}
