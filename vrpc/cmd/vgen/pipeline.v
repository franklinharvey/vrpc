module main

import os

pub struct GenerateOptions {
pub:
	targets []string
	with_zod bool
}

pub fn default_targets() []string {
	return ['v', 'v_client']
}

pub fn parse_targets(args []string) []string {
	if args.len == 0 {
		return default_targets()
	}
	return args
}

pub fn generate_service(service Service, contract_dir string, opts GenerateOptions) ! {
	mut written := map[string]bool{}
	for target in opts.targets {
		files := files_for_target(service, target, opts)
		for file in files {
			if file.path in written {
				continue
			}
			written[file.path] = true
			out := os.join_path(contract_dir, file.path)
			parent := os.dir(out)
			if parent != '' && parent != '.' {
				os.mkdir_all(parent) or {}
			}
			os.write_file(out, file.content)!
			println('generated ${out}')
		}
	}
}

fn files_for_target(service Service, target string, opts GenerateOptions) []GeneratedFile {
	// if/else avoids a V 0.5 C codegen bug with match + struct literals on Linux/gcc.
	if target == 'v' || target == 'server' {
		return emit_v_server(service)
	}
	if target == 'v_client' {
		return emit_v_client(service)
	}
	if target == 'ts' || target == 'typescript' {
		ts_opts := TsEmitOptions{with_zod: opts.with_zod}
		return emit_ts_client(service, ts_opts)
	}
	if target == 'zod' {
		zod_file := emit_ts_zod(service)
		return [zod_file]
	}
	if target == 'openapi' {
		oapi_file := emit_openapi(service)
		return [oapi_file]
	}
	return []GeneratedFile{}
}

pub fn generate_dir(dir string, opts GenerateOptions) ! {
	files := find_contract_files(dir)!
	if files.len == 0 {
		return error('no contract files found under ${dir}')
	}
	for path in files {
		service := parse_contract_file(path)!
		base := os.dir(path)
		generate_service(service, base, opts)!
	}
}

