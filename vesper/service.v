module vesper

pub struct ServiceDef {
pub:
	name       string
	prefix     string
	procedures []ProcedureDef
}

pub struct ServiceOptions {
pub:
	middleware []Middleware
}

pub fn (mut app App) register_service(service ServiceDef) ! {
	app.services << service
	for proc in service.procedures {
		full_path := normalize_service_path(service.prefix, proc.transport.path)
		app.router.add_route(proc.transport.method, full_path, proc.handler)
	}
}

fn trim_slashes(s string) string {
	mut r := s
	for r.starts_with('/') {
		r = r[1..]
	}
	for r.ends_with('/') {
		r = r[..r.len - 1]
	}
	return r
}

pub fn normalize_service_path(prefix string, path string) string {
	p := trim_slashes(prefix)
	sub := trim_slashes(path)
	if p == '' {
		if sub == '' {
			return '/'
		}
		return '/${sub}'
	}
	if sub == '' {
		return '/${p}'
	}
	return '/${p}/${sub}'
}
