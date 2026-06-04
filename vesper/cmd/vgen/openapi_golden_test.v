module main

import os

fn test_openapi_emit_matches_golden() {
	root := os.dir(@FILE)
	contract := os.join_path(root, 'testdata/users/users.contract')
	golden := os.join_path(root, 'testdata/users/golden/openapi.json')
	service := parse_contract_file(contract) or { panic(err) }
	got := openapi_json(service)
	want := os.read_file(golden) or { panic(err) }
	assert got == want
}
