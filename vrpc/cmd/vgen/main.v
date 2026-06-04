module main

import os

fn main() {
	args := os.args[1..]
	if args.len == 0 {
		print_usage()
		return
	}
	match args[0] {
		'generate' {
			mut dir := '.'
			mut targets := []string{}
			mut zod := false
			for i := 1; i < args.len; i++ {
				if args[i] == '--target' && i + 1 < args.len {
					targets = args[i + 1].split(',')
					i++
				} else if args[i] == '--zod' {
					zod = true
				} else if !args[i].starts_with('-') {
					dir = args[i]
				}
			}
			generate_in_dir(dir, targets, zod) or {
				eprintln('generate failed: ${err}')
				exit(1)
			}
		}
		'inspect' {
			dir := if args.len > 1 { args[1] } else { '.' }
			inspect_dir(dir) or {
				eprintln('inspect failed: ${err}')
				exit(1)
			}
		}
		'openapi' {
			dir := if args.len > 1 { args[1] } else { '.' }
			print_openapi(dir) or {
				eprintln('openapi failed: ${err}')
				exit(1)
			}
		}
		else {
			print_usage()
			exit(1)
		}
	}
}

fn print_usage() {
	println('vrpc — contract-first service framework')
	println('')
	println('Usage:')
	println('  v run cmd/vgen generate [dir] [--target v,ts,openapi] [--zod]')
	println('  v run cmd/vgen inspect [dir]')
	println('  v run cmd/vgen openapi [dir]')
	println('')
	println('Targets: v (server), v_client, ts (TypeScript), openapi (openapi.json)')
	println('Flags: --zod emits schemas.zod.ts alongside ts')
}
