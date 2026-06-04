module vrpc

fn test_openapi_builds_paths() {
	service := ServiceDef{
		name:   'UserService'
		prefix: '/users'
		procedures: [
			ProcedureDef{
				name: 'create_user'
				input_schema: object_schema('CreateUserRequest', [
					SchemaField{
						name:     'name'
						typ:      'string'
						source:   .body
						required: true
					},
				])
				output_schema: object_schema('CreateUserResponse', [])
				transport: TransportBinding{
					method: .post
					path:   '/'
				}
				handler: unsafe { nil }
			},
		]
	}
	doc := build_openapi_document([service])
	assert doc.paths['/users'].operations['post'].operation_id == 'create_user'
}
