module main

import os
import veetest

fn test_vgen_typescript() ! {
	veetest.run(veetest.suite('vgen/typescript', [
		veetest.case('emit matches golden', fn () ! {
			root := os.dir(@FILE)
			contract := os.join_path(root, 'testdata/users/users.contract')
			golden_dir := os.join_path(root, 'testdata/users/golden')
			service := parse_contract_file(contract) or { return err }
			files := emit_ts_client(service, TsEmitOptions{with_zod: false})
			veetest.eq_int('file count', 3, files.len)!
			for file in files {
				base := os.base(file.path)
				want := os.read_file(os.join_path(golden_dir, base)) or { return err }
				veetest.eq_str('golden ${base}', want, file.content)!
			}
		}),
	]))!
}
