# users

Full contract-first demo: `users.contract` defines the service and payloads; `vgen` emits server mounts and clients; the app serves JSON, OpenAPI, and Swagger UI.

## Run

```bash
v install
v run .
```

Server listens on **http://127.0.0.1:3000**.

## Endpoints

| URL | Description |
|-----|-------------|
| `GET /docs` | Swagger UI (from generated OpenAPI) |
| `GET /openapi.json` | OpenAPI 3.0 document |
| `POST /users` | Create user (`name`, `email` JSON body) |
| `GET /users/:id` | Get user by ID |
| `GET /users` | List users |

## Try it

```bash
curl -s -X POST http://127.0.0.1:3000/users \
  -H 'Content-Type: application/json' \
  -d '{"name":"Ada","email":"ada@example.com"}'

curl -s http://127.0.0.1:3000/users
```

## Tests

```bash
v test .    # e2e: create/get/list, validation, not_found, openapi
```

## Generated artifacts

- `generated.v`, `client.generated.v` — V server mount and client
- `user/*.ts` — TypeScript types and `fetch` client
- `openapi.json` — OpenAPI spec

Regenerate from repo root:

```bash
cd ../../vrpc
v run cmd/vgen generate ../examples/users --target v,v_client,ts,openapi --zod
```
