module vrpc

import veetest

fn test_openapi() ! {
	veetest.run(veetest.suite('openapi', [
		veetest.case('builds paths from service', fn () ! {
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
			veetest.eq_str('operation_id', 'create_user', doc.paths['/users'].operations['post'].operation_id)!
		}),
	]))!
}
