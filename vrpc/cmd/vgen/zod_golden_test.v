module main

import os

fn test_zod_emit_matches_golden() {
	root := os.dir(@FILE)
	contract := os.join_path(root, 'testdata/users/users.contract')
	golden := os.join_path(root, 'testdata/users/golden/schemas.zod.ts')
	service := parse_contract_file(contract) or { panic(err) }
	got := emit_ts_zod(service).content
	want := os.read_file(golden) or { panic(err) }
	assert got == want
}
