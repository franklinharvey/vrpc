module main

import os
import veetest

fn test_vgen_openapi() ! {
	veetest.run(veetest.suite('vgen/openapi', [
		veetest.case('emit matches golden', fn () ! {
			root := os.dir(@FILE)
			contract := os.join_path(root, 'testdata/users/users.contract')
			golden := os.join_path(root, 'testdata/users/golden/openapi.json')
			service := parse_contract_file(contract) or { return err }
			file := emit_openapi(service)
			want := os.read_file(golden) or { return err }
			veetest.eq_str('openapi.json', want, file.content)!
		}),
	]))!
}
