module main

pub fn generate_in_dir(dir string, targets []string, zod bool) ! {
	opts := GenerateOptions{
		targets: parse_targets(targets)
		zod:     zod
	}
	generate_dir(dir, opts)!
}

pub fn inspect_dir(dir string) ! {
	inspect_dir_impl(dir)!
}

pub fn print_openapi(dir string) ! {
	files := find_contract_files(dir)!
	if files.len == 0 {
		return error('no contract files found under ${dir}')
	}
	for path in files {
		service := parse_contract_file(path)!
		println(openapi_json(service))
	}
}

fn inspect_dir_impl(dir string) ! {
	files := find_contract_files(dir)!
	for path in files {
		service := parse_contract_file(path)!
		println('${path}: ${service.name} prefix=${service.prefix} procedures=${service.procedures.len} types=${service.types.len}')
		for proc in service.procedures {
			println('  ${proc.method.str()} ${proc.path} ${proc.name}(${proc.input_type}) !${proc.output_type}')
		}
	}
}
