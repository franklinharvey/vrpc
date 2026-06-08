# htmx

Server-rendered HTML with [HTMX](https://htmx.org/) partial updates — no JSON API, no contracts. Shows that vrpc works for traditional web handlers alongside the contract-first path.

## Run

```bash
v run .
```

Open **http://127.0.0.1:3002** in a browser.

## What to try

- Click **+1** on the counter — HTMX swaps the `#counter` partial via `POST /counter/increment`
- Submit the greet form — `GET /greet?name=...` replaces `#greeting` with an HTML snippet

For OpenAPI and typed clients, see [../users/README.md](../users/README.md).
