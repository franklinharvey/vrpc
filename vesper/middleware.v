module vesper

pub type Middleware = fn (mut Context, fn (mut Context) !Response) !Response

fn dispatch_middleware(idx int, mut ctx Context, middlewares []Middleware, final_handler fn (mut Context) !Response) !Response {
	if idx >= middlewares.len {
		return final_handler(mut ctx)!
	}
	continue_fn := fn [idx, middlewares, final_handler] (mut c Context) !Response {
		return dispatch_middleware(idx + 1, mut c, middlewares, final_handler)!
	}
	return middlewares[idx](mut ctx, continue_fn)!
}

pub fn run_middleware_stack(mut ctx Context, middlewares []Middleware, final_handler fn (mut Context) !Response) !Response {
	return dispatch_middleware(0, mut ctx, middlewares, final_handler)!
}

pub fn logger() Middleware {
	return fn (mut ctx Context, continue_fn fn (mut Context) !Response) !Response {
		println('[vesper] ${ctx.request.method} ${ctx.request.path}')
		return continue_fn(mut ctx)!
	}
}

pub fn cors() Middleware {
	return fn (mut ctx Context, continue_fn fn (mut Context) !Response) !Response {
		mut res := continue_fn(mut ctx)!
		res.add_cors()
		return res
	}
}
