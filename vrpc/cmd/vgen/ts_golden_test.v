module main

import os

fn test_ts_emit_matches_golden() {
	root := os.dir(@FILE)
	contract := os.join_path(root, 'testdata/users/users.contract')
	golden_dir := os.join_path(root, 'testdata/users/golden')
	service := parse_contract_file(contract) or { panic(err) }
	files := emit_ts_client(service, TsEmitOptions{with_zod: false})
	assert files.len == 3
	for file in files {
		base := os.base(file.path)
		want := os.read_file(os.join_path(golden_dir, base)) or { panic(err) }
		assert file.content == want, 'golden mismatch for ${base}'
	}
}
