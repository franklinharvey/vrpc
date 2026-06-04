module main

import os
import veetest

fn test_vgen_zod() ! {
	veetest.run(veetest.suite('vgen/zod', [
		veetest.case('emit matches golden', fn () ! {
			root := os.dir(@FILE)
			contract := os.join_path(root, 'testdata/users/users.contract')
			golden := os.join_path(root, 'testdata/users/golden/schemas.zod.ts')
			service := parse_contract_file(contract) or { return err }
			file := emit_ts_zod(service)
			want := os.read_file(golden) or { return err }
			veetest.eq_str('schemas.zod.ts', want, file.content)!
		}),
	]))!
}
