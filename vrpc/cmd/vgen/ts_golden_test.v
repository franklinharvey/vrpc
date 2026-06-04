module main

import os
import vrpc

fn test_vgen_typescript() ! {
	vrpc.vtest_run(vrpc.vtest_suite('vgen/typescript', [
		vrpc.vtest_case('emit matches golden', fn () ! {
			root := os.dir(@FILE)
			contract := os.join_path(root, 'testdata/users/users.contract')
			golden_dir := os.join_path(root, 'testdata/users/golden')
			service := parse_contract_file(contract) or { return err }
			files := emit_ts_client(service, TsEmitOptions{with_zod: false})
			vrpc.vtest_eq_int('file count', 3, files.len)!
			for file in files {
				base := os.base(file.path)
				want := os.read_file(os.join_path(golden_dir, base)) or { return err }
				vrpc.vtest_eq_str('golden ${base}', want, file.content)!
			}
		}),
	]))!
}
