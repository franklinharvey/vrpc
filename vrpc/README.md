# vrpc

Contract-first service framework for V. Define payloads and service interfaces; generate HTTP routing, binding, validation, OpenAPI, and typed clients.

See [../brief.md](../brief.md) for the full design brief. Implementation progress is tracked in [../TASKS.md](../TASKS.md).

## Quick start

```bash
# From repo root (requires V: https://vlang.io)
cd vrpc
v test .

# Generate V server + client from contracts
v run cmd/vgen generate ../examples/users --target v,v_client

# TypeScript fetch client (writes examples/users/user/*.ts)
v run cmd/vgen generate ../examples/users --target ts

# OpenAPI JSON + optional Zod runtime schemas
v run cmd/vgen generate ../examples/users --target openapi
v run cmd/vgen generate ../examples/users --target ts --zod
v run cmd/vgen openapi ../examples/users   # print OpenAPI to stdout

# Run the users example
v run ../examples/users
```

## Layout

```txt
vrpc/          — runtime library (module vrpc)
cmd/vgen/        — CLI: generate, inspect, openapi; IR + emitters (V, TS)
examples/        — hello, users
```

## Contract → generated

```v
@[service; prefix: '/users']
pub interface UserService {
    @[post: '/']
    create_user(CreateUserRequest) !CreateUserResponse
}
```

```sh
v run cmd/vgen generate ../examples/users
# writes generated.v, client.generated.v (V) and/or user/*.ts (TS)
```
