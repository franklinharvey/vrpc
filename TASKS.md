# Vesper — implementation tasks

Tracked against [brief.md](brief.md). Status: `todo` | `in_progress` | `done`.

## Milestone 1: runtime skeleton

| Task | Status |
|------|--------|
| `App`, `AppConfig`, `new()` | done |
| `Router` with linear route matching | done |
| `Context`, `Request`, path params | done |
| `Response`, `json()` | done |
| Error response mapping (HTTP status) | done |
| `listen()` via `net.http` | done |
| Unit tests: route matching, path params | done |

**Success:** A manually registered handler serves JSON.

## Milestone 2: service metadata

| Task | Status |
|------|--------|
| `ServiceDef`, `ProcedureDef`, `TransportBinding` | done |
| `Schema`, `SchemaField`, `FieldSource` | done |
| `register_service()` wires routes from procedures | done |
| Unit test: one service → one HTTP route | done |

**Success:** A service with one procedure registers one HTTP route.

## Milestone 3: restricted generator

| Task | Status |
|------|--------|
| Line-oriented contract parser (`@[service]`, interface, `@[post]` methods) | done |
| `vesper generate` CLI command | done |
| Emit `mount_*_service` + schema helpers | done |
| Generator snapshot test (users contract) | done |

**Success:** Generate a mount function for one service.

## Milestone 4: JSON body binding

| Task | Status |
|------|--------|
| Generated `bind_*_request` for body structs | done |
| POST JSON → typed struct | done |
| Example `examples/users` POST flow | done |

**Success:** POST JSON body becomes typed request struct.

## Milestone 5: path / query / header binding

| Task | Status |
|------|--------|
| `@[path]`, `@[query]`, `@[header]` in contract parser | done |
| Generated binders overlay path/query/header on body decode | done |
| Unit tests: query, header binding | done |

**Success:** One request struct combines path, query, header, and body.

## Milestone 6: validation

| Task | Status |
|------|--------|
| `required`, `min`, `max`, `min_len`, `max_len`, `email`, `uuid` | done |
| Generated `validate_*_request` | done |
| Structured 400 `validation_failed` response | done |
| Unit tests for validation rules | done |

**Success:** Invalid requests return structured 400.

## Milestone 7: OpenAPI

| Task | Status |
|------|--------|
| OpenAPI 3.0 JSON from `ServiceDef` graph | done |
| `app.openapi(path)` endpoint | done |
| `app.docs(path)` minimal Swagger UI page | done |
| Unit test: schema generation | done |

**Success:** `GET /openapi.json` returns valid OpenAPI 3.0 JSON.

## Milestone 8: V client generation

| Task | Status |
|------|--------|
| `client.post_json` / `get_json` runtime helpers | done |
| Generate `*_client` module per service | done |
| Example client usage | done |

**Success:** Generated client calls example server with typed structs.

## Examples & docs

| Task | Status |
|------|--------|
| `examples/hello` | done |
| `examples/users` (contract + service + generated) | done |
| `examples/validation` | todo |
| `examples/errors` | todo |
| E2E tests (`examples/users/e2e_test.v`) | done |
| `vesper/README.md` | done |

## Milestone 9: multi-target codegen (IR pipeline)

| Task | Status |
|------|--------|
| Contract → IR (`cmd/vgen/ir.v`, `parser.v`) | done |
| TypeScript emitter (`emit_ts.v`) | done |
| `vgen generate --target ts` → `<pkg>/types.ts`, `client.ts`, `index.ts` | done |
| Golden test (`cmd/vgen/ts_golden_test.v`) | done |
| OpenAPI JSON from IR (`emit_openapi.v`, `--target openapi`) | done |
| Zod schemas (`emit_zod.v`, `--zod` or `--target zod`) | done |
| TS client skips empty query params (`buildQuery`) | done |
| Second language emitter | todo |

**Success:** `v run cmd/vgen generate examples/users --target ts,openapi --zod` emits fetch client, `openapi.json`, and `schemas.zod.ts`.

## Future (post-MVP)

- Trie router, compiler AST parser (option B)
- Service-level middleware from attributes
