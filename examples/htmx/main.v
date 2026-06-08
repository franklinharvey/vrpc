module main

import vrpc

@[heap]
struct AppState {
mut:
	counter int
}

fn counter_fragment(count int) string {
	return '<div id="counter" class="stat">
  <span class="value">${count}</span>
  <button hx-post="/counter/increment" hx-target="#counter" hx-swap="outerHTML">+1</button>
</div>'
}

fn page_html(counter int) string {
	return '<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>vrpc + HTMX</title>
  <script src="https://unpkg.com/htmx.org@2.0.4"></script>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 32rem; margin: 2rem auto; padding: 0 1rem; }
    .stat { display: flex; align-items: center; gap: 1rem; margin: 1.5rem 0; }
    .value { font-size: 2rem; font-weight: 600; }
    button { cursor: pointer; padding: 0.4rem 0.8rem; }
    form { display: flex; gap: 0.5rem; align-items: center; margin-top: 1.5rem; }
    input { padding: 0.35rem 0.5rem; }
  </style>
</head>
<body>
  <h1>vrpc + HTMX</h1>
  <p>Server-rendered HTML partials from a V HTTP service.</p>
  ${counter_fragment(counter)}
  <form hx-get="/greet" hx-target="#greeting" hx-swap="innerHTML">
    <label>Name <input type="text" name="name" required></label>
    <button type="submit">Greet</button>
  </form>
  <div id="greeting"></div>
</body>
</html>'
}

fn main() {
	mut state := &AppState{}
	mut app := vrpc.new()
	app.add_route(.get, '/', fn [state] (mut ctx vrpc.Context) !vrpc.Response {
		return vrpc.html(page_html(state.counter), 200)
	})
	app.add_route(.post, '/counter/increment', fn [mut state] (mut ctx vrpc.Context) !vrpc.Response {
		state.counter++
		return vrpc.html(counter_fragment(state.counter), 200)
	})
	app.add_route(.get, '/greet', fn (mut ctx vrpc.Context) !vrpc.Response {
		name := ctx.query_param('name')
		if name == '' {
			return vrpc.html('<p>Enter a name.</p>', 200)
		}
		return vrpc.html('<p>Hello, <strong>${name}</strong>!</p>', 200)
	})
	app.listen(':3002')!
}
