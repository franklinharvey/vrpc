module main

import os
import vrpc

fn test_vgen_openapi() ! {
	vrpc.vtest_run(vrpc.vtest_suite('vgen/openapi', [
		vrpc.vtest_case('emit matches golden', fn () ! {
			root := os.dir(@FILE)
			contract := os.join_path(root, 'testdata/users/users.contract')
			golden := os.join_path(root, 'testdata/users/golden/openapi.json')
			service := parse_contract_file(contract) or { return err }
			file := emit_openapi(service)
			want := os.read_file(golden) or { return err }
			vrpc.vtest_eq_str('openapi.json', want, file.content)!
		}),
	]))!
}
