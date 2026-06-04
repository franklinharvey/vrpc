# V Service Framework Implementation Brief

## Working name

`vrpc`

A contract-first service framework for V.

The goal is not to build an Express/FastAPI-style route registration framework. The goal is to build a V-native, service-oriented framework where developers define payload structs and service contracts, implement those services, and let the framework generate HTTP routing, JSON binding, validation, OpenAPI, and typed clients.

## Product thesis

Most web frameworks center the route:

```v
app.post('/users', create_user)
```

This framework centers the service procedure:

```v
interface UserService {
    create_user(CreateUserRequest) !CreateUserResponse
    get_user(GetUserRequest) !GetUserResponse
}
```

The transport is derived from the contract. HTTP is only one transport binding.

The developer should think in terms of:

```txt
Service -> Procedure -> Input payload -> Output payload -> Errors -> Transport binding
```

not:

```txt
HTTP method -> Path -> Handler
```

## Core goals

1. Define request and response payloads as normal V structs.
2. Define service contracts as V interfaces or service specs.
3. Implement service methods as ordinary V methods.
4. Generate HTTP routes from service metadata.
5. Decode JSON request bodies into typed V structs.
6. Bind path, query, header, and body fields into one request struct.
7. Validate input structs using field attributes.
8. Return typed responses as JSON.
9. Generate OpenAPI from the service graph.
10. Generate typed V clients from the same service graph.
11. Make TypeScript client generation possible later.
12. Avoid runtime reflection-heavy magic.
13. Favor code generation and explicit metadata.
14. Keep the runtime small and understandable.
15. Support single-binary deployment.

## Non-goals for the first version

Do not build a full NestJS clone.

Do not build decorators, modules, guards, interceptors, ORM integrations, job queues, GraphQL, websockets, streaming RPC, gRPC, protobuf, or a complex dependency injection container in the MVP.

Do not require users to hand-register every route.

Do not use a route-first API as the primary framework interface.

## Intended developer experience

### Contract file

```v
module users

import vrpc

@[service; prefix: '/users']
pub interface UserService {
    @[post: '/']
    create_user(CreateUserRequest) !CreateUserResponse

    @[get: '/:id']
    get_user(GetUserRequest) !GetUserResponse

    @[get: '/']
    list_users(ListUsersRequest) !ListUsersResponse
}

pub struct CreateUserRequest {
pub:
    name  string @[body; required; min_len: 1]
    email string @[body; required; email]
}

pub struct CreateUserResponse {
pub:
    id    string
    name  string
    email string
}

pub struct GetUserRequest {
pub:
    id string @[path; required]
}

pub struct GetUserResponse {
pub:
    id    string
    name  string
    email string
}

pub struct ListUsersRequest {
pub:
    limit  int    @[query; min: 1; max: 100]
    cursor string @[query]
}

pub struct ListUsersResponse {
pub:
    users       []UserSummary
    next_cursor string
}

pub struct UserSummary {
pub:
    id    string
    name  string
    email string
}
```

### Implementation file

```v
module users

pub struct UserServiceImpl {
    repo UserRepo
}

pub fn new_service(repo UserRepo) UserServiceImpl {
    return UserServiceImpl{
        repo: repo
    }
}

pub fn (s UserServiceImpl) create_user(req CreateUserRequest) !CreateUserResponse {
    user := s.repo.create(req.name, req.email)!
    return CreateUserResponse{
        id: user.id
        name: user.name
        email: user.email
    }
}

pub fn (s UserServiceImpl) get_user(req GetUserRequest) !GetUserResponse {
    user := s.repo.find_by_id(req.id)!
    return GetUserResponse{
        id: user.id
        name: user.name
        email: user.email
    }
}

pub fn (s UserServiceImpl) list_users(req ListUsersRequest) !ListUsersResponse {
    page := s.repo.list(req.limit, req.cursor)!
    return ListUsersResponse{
        users: page.users.map(UserSummary{
            id: it.id
            name: it.name
            email: it.email
        })
        next_cursor: page.next_cursor
    }
}
```

### Server file

```v
module main

import vrpc
import users

fn main() {
    repo := users.new_repo()

    mut app := vrpc.new()

    users.mount_user_service(mut app, users.new_service(repo))!

    app.openapi('/openapi.json')!
    app.docs('/docs')!

    app.listen(':3000')!
}
```

### Generated V client

```v
module main

import users_client

fn main() {
    client := users_client.new(
        base_url: 'http://localhost:3000'
    )

    res := client.create_user(users_client.CreateUserRequest{
        name: 'Ada Lovelace'
        email: 'ada@example.com'
    })!

    println(res.id)
}
```

## Syntax philosophy

The public user-facing API should be contract-first.

Preferred:

```v
users.mount_user_service(mut app, impl)!
```

Acceptable:

```v
server.mount_service(users.service_def(), impl)!
```

Avoid as the main API:

```v
app.post('/users', create_user)
```

Route registration can exist internally, but it should not be the primary developer experience.

## Framework architecture

The system has two parts:

1. Runtime library
2. Code generator

The runtime executes requests, routing, binding, validation, response encoding, error mapping, and OpenAPI serving.

The generator reads service contracts and emits mount functions, service definitions, schema definitions, clients, and OpenAPI metadata.

## Directory structure

Expected package layout:

```txt
vrpc/
  README.md
  v.mod
  src/
    vrpc/
      app.v
      context.v
      router.v
      service.v
      procedure.v
      schema.v
      validation.v
      binding.v
      response.v
      errors.v
      openapi.v
      client.v
      middleware.v
  cmd/
    vgen/
      main.v
      generate.v
      inspect.v
      openapi.v
  examples/
    hello/
    users/
    validation/
    errors/
```

Example user project:

```txt
my_api/
  v.mod
  main.v
  users/
    contract.v
    service.v
    generated.v
  billing/
    contract.v
    service.v
    generated.v
```

## Core runtime types

### App

```v
module vrpc

pub struct App {
mut:
    router Router
    services []ServiceDef
    middleware []Middleware
    config AppConfig
}

pub struct AppConfig {
pub:
    name string
    version string
}

pub fn new() App {
    return App{}
}

pub fn (mut app App) listen(addr string) ! {
    // Start HTTP server.
}

pub fn (mut app App) register_service(service ServiceDef) ! {
    // Store service metadata and register all HTTP transport bindings.
}

pub fn (mut app App) openapi(path string) ! {
    // Register endpoint that returns OpenAPI JSON.
}

pub fn (mut app App) docs(path string) ! {
    // Register endpoint that serves Swagger UI or a minimal docs page.
}
```

### ServiceDef

```v
module vrpc

pub struct ServiceDef {
pub:
    name string
    prefix string
    procedures []ProcedureDef
}
```

### ProcedureDef

```v
module vrpc

pub struct ProcedureDef {
pub:
    name string
    input_schema Schema
    output_schema Schema
    errors []ErrorDef
    transport TransportBinding
    handler ProcedureHandler
}
```

### TransportBinding

```v
module vrpc

pub enum HttpMethod {
    get
    post
    put
    patch
    delete
}

pub struct TransportBinding {
pub:
    method HttpMethod
    path string
}
```

### Schema

```v
module vrpc

pub enum SchemaKind {
    object
    string
    integer
    number
    boolean
    array
}

pub struct Schema {
pub:
    name string
    kind SchemaKind
    fields []SchemaField
}

pub struct SchemaField {
pub:
    name string
    typ string
    source FieldSource
    required bool
    validators []ValidatorDef
}

pub enum FieldSource {
    body
    path
    query
    header
}
```

### Context

```v
module vrpc

pub struct Context {
pub:
    request Request
mut:
    response Response
    state map[string]string
}

pub fn (ctx Context) header(name string) string {
    return ctx.request.headers[name] or { '' }
}
```

## Handler model

The generator should wrap typed service methods into generic runtime handlers.

User implementation:

```v
pub fn (s UserServiceImpl) create_user(req CreateUserRequest) !CreateUserResponse
```

Generated wrapper:

```v
fn create_user_handler(mut ctx vrpc.Context, impl UserServiceImpl) !vrpc.Response {
    req := vrpc.bind[CreateUserRequest](ctx)!
    vrpc.validate(req)!
    res := impl.create_user(req)!
    return vrpc.json(res)
}
```

The runtime sees only:

```v
pub type ProcedureHandler = fn (mut Context) !Response
```

If V function type constraints make this difficult, use generated concrete functions rather than a fully generic handler type.

## Request binding

A single request struct can pull from multiple locations.

Example:

```v
pub struct UpdateUserRequest {
pub:
    id    string @[path; required]
    token string @[header: 'x-api-token'; required]
    name  string @[body; min_len: 1]
    email string @[body; email]
}
```

For an HTTP request:

```txt
PATCH /users/123
x-api-token: secret

{
  "name": "Ada",
  "email": "ada@example.com"
}
```

The binder should produce:

```v
UpdateUserRequest{
    id: '123'
    token: 'secret'
    name: 'Ada'
    email: 'ada@example.com'
}
```

### Binding sources

Supported in MVP:

```txt
@[path]
@[query]
@[header]
@[body]
```

Default source rules:

1. For GET requests, fields default to query unless explicitly marked.
2. For POST, PUT, PATCH requests, fields default to body unless explicitly marked.
3. Path fields must be explicitly marked with `@[path]`.
4. Header fields must be explicitly marked with `@[header]`.
5. If uncertain, require explicit annotation.

## Validation

Validation is based on struct field attributes.

MVP validators:

```txt
@[required]
@[min: N]
@[max: N]
@[min_len: N]
@[max_len: N]
@[email]
@[uuid]
```

Example:

```v
pub struct CreateUserRequest {
pub:
    name  string @[body; required; min_len: 1; max_len: 100]
    email string @[body; required; email]
    age   int    @[body; min: 13]
}
```

Validation errors should be structured:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "rule": "email",
        "message": "email must be a valid email address"
      }
    ]
  }
}
```

Runtime type:

```v
pub struct ValidationError {
pub:
    field string
    rule string
    message string
}

pub struct ValidationErrorResponse {
pub:
    error ApiError
}

pub struct ApiError {
pub:
    code string
    message string
    details []ValidationError
}
```

## Error model

Business logic should return V errors. The framework should map known framework errors to HTTP status codes.

MVP built-in errors:

```v
module vrpc

pub fn bad_request(message string) IError
pub fn unauthorized(message string) IError
pub fn forbidden(message string) IError
pub fn not_found(message string) IError
pub fn conflict(message string) IError
pub fn internal(message string) IError
```

Status mapping:

```txt
validation_failed -> 400
bad_request       -> 400
unauthorized      -> 401
forbidden         -> 403
not_found         -> 404
conflict          -> 409
internal          -> 500
```

User code:

```v
pub fn (s UserServiceImpl) get_user(req GetUserRequest) !GetUserResponse {
    user := s.repo.find_by_id(req.id) or {
        return vrpc.not_found('User not found')
    }

    return GetUserResponse{
        id: user.id
        name: user.name
        email: user.email
    }
}
```

HTTP response:

```json
{
  "error": {
    "code": "not_found",
    "message": "User not found"
  }
}
```

## Middleware

Middleware should be service/procedure-aware, not only HTTP-aware.

MVP middleware type:

```v
pub type Middleware = fn (mut Context, next Next) !Response
pub type Next = fn (mut Context) !Response
```

Global middleware:

```v
app.use(vrpc.logger())
app.use(vrpc.cors())
```

Service-level middleware in generated metadata:

```v
@[service; prefix: '/users'; middleware: ['auth']]
pub interface UserService {
    create_user(CreateUserRequest) !CreateUserResponse
}
```

If attribute parsing for middleware is too hard in MVP, support explicit service options:

```v
users.mount_user_service_with_options(mut app, impl, vrpc.ServiceOptions{
    middleware: [auth_middleware]
})!
```

## OpenAPI generation

OpenAPI should be generated from `ServiceDef`, `ProcedureDef`, and `Schema`.

For each procedure:

```v
@[post: '/']
create_user(CreateUserRequest) !CreateUserResponse
```

Generate:

```txt
POST /users/
requestBody: CreateUserRequest
responses:
  200: CreateUserResponse
  400: validation error
  500: internal error
```

For:

```v
@[get: '/:id']
get_user(GetUserRequest) !GetUserResponse
```

Generate:

```txt
GET /users/{id}
parameters:
  id: path string required
responses:
  200: GetUserResponse
  404: not found
```

MVP OpenAPI endpoint:

```v
app.openapi('/openapi.json')!
```

Optional docs endpoint:

```v
app.docs('/docs')!
```

Docs can initially be a static HTML page that loads `/openapi.json`.

## Code generation

The generator should run as:

```sh
v run cmd/vrpc generate .
```

or, if packaged as a CLI:

```sh
vrpc generate .
```

It should scan for contract files and generate:

```txt
users/generated.v
users/openapi.generated.v
users/client.generated.v
```

### Input

Files containing:

```v
@[service; prefix: '/users']
pub interface UserService {
    @[post: '/']
    create_user(CreateUserRequest) !CreateUserResponse
}
```

### Output

Generated mount function:

```v
module users

import vrpc

pub fn mount_user_service(mut app vrpc.App, impl UserServiceImpl) ! {
    service := vrpc.ServiceDef{
        name: 'UserService'
        prefix: '/users'
        procedures: [
            vrpc.ProcedureDef{
                name: 'create_user'
                input_schema: schema_create_user_request()
                output_schema: schema_create_user_response()
                transport: vrpc.TransportBinding{
                    method: .post
                    path: '/'
                }
                handler: fn [impl] (mut ctx vrpc.Context) !vrpc.Response {
                    req := vrpc.bind_create_user_request(mut ctx)!
                    vrpc.validate_create_user_request(req)!
                    res := impl.create_user(req)!
                    return vrpc.json(res)
                }
            },
        ]
    }

    app.register_service(service)!
}
```

If V does not support closure capture in the required form, generate a small wrapper struct:

```v
struct UserServiceRuntime {
    impl UserServiceImpl
}

fn (r UserServiceRuntime) create_user_handler(mut ctx vrpc.Context) !vrpc.Response {
    req := vrpc.bind_create_user_request(mut ctx)!
    vrpc.validate_create_user_request(req)!
    res := r.impl.create_user(req)!
    return vrpc.json(res)
}
```

Then register method references.

## Generator implementation strategy

Start simple.

Do not write a full V parser in MVP.

Use one of these approaches:

### Option A: restricted contract parser

Require contract files to follow a predictable subset:

```v
@[service; prefix: '/users']
pub interface UserService {
    @[post: '/']
    create_user(CreateUserRequest) !CreateUserResponse
}
```

Parse with line-oriented scanning and regular expressions.

This is acceptable for MVP.

### Option B: use V compiler AST if accessible

If practical, integrate with V compiler internals to parse `.v` files. This may be more robust but risks coupling the framework to unstable compiler internals.

For the first build, prefer Option A.

## Attribute grammar

Service attribute:

```v
@[service; prefix: '/users']
```

Procedure transport attributes:

```v
@[get: '/:id']
@[post: '/']
@[put: '/:id']
@[patch: '/:id']
@[delete: '/:id']
```

Field source attributes:

```v
@[path]
@[query]
@[body]
@[header]
@[header: 'x-api-token']
```

Validation attributes:

```v
@[required]
@[min: 1]
@[max: 100]
@[min_len: 1]
@[max_len: 255]
@[email]
@[uuid]
```

## HTTP routing

The runtime router should support:

```txt
/users
/users/:id
/users/:id/posts
```

Path params should bind into context:

```v
ctx.params['id']
```

Route matching should compile route patterns into segments:

```v
struct Route {
    method HttpMethod
    path string
    segments []RouteSegment
    handler ProcedureHandler
}

struct RouteSegment {
    value string
    is_param bool
}
```

MVP can use simple linear matching. Optimize later with a trie.

## JSON encoding and decoding

Use V’s JSON support.

Generated binder for body structs can call JSON decode, then overlay path/query/header fields.

Pseudo-code:

```v
pub fn bind_create_user_request(mut ctx vrpc.Context) !CreateUserRequest {
    mut req := json.decode(CreateUserRequest, ctx.body)!

    return CreateUserRequest{
        ...req
        id: ctx.param('id')
    }
}
```

If V does not support spread syntax for structs in the desired way, generate explicit field assignment.

## Client generation

Generate a V client for each service.

Input:

```v
interface UserService {
    create_user(CreateUserRequest) !CreateUserResponse
}
```

Output:

```v
module users_client

pub struct Client {
pub:
    base_url string
}

pub fn new(config ClientConfig) Client {
    return Client{
        base_url: config.base_url
    }
}

pub struct ClientConfig {
pub:
    base_url string
}

pub fn (c Client) create_user(req CreateUserRequest) !CreateUserResponse {
    http_res := vrpc.client.post_json(
        c.base_url + '/users/',
        req
    )!

    return json.decode(CreateUserResponse, http_res.body)!
}
```

For GET requests, encode query/path fields appropriately.

## Testing strategy

Create tests at three levels.

### Unit tests

1. Route matching
2. Path param extraction
3. Query binding
4. Header binding
5. Body binding
6. Validation rules
7. Error mapping
8. OpenAPI schema generation

### Generator snapshot tests

Given:

```v
@[service; prefix: '/users']
interface UserService {
    @[post: '/']
    create_user(CreateUserRequest) !CreateUserResponse
}
```

Assert generated code matches expected output.

### End-to-end tests

Spin up example app and test:

```txt
POST /users
GET /users/:id
GET /openapi.json
```

Validate response bodies and status codes.

## MVP milestone plan

### Milestone 1: runtime skeleton

Implement:

```txt
App
Router
Context
Response
json()
error response mapping
listen()
```

Success criterion:

A manually registered generated-looking handler can serve JSON.

### Milestone 2: service metadata

Implement:

```txt
ServiceDef
ProcedureDef
TransportBinding
register_service()
```

Success criterion:

A service with one procedure registers one HTTP route.

### Milestone 3: restricted generator

Implement parser for:

```txt
@[service; prefix: '/x']
interface XService
@[post: '/x']
method(Input) !Output
```

Success criterion:

Generate a mount function for one service.

### Milestone 4: JSON body binding

Implement generated binders for simple body structs.

Success criterion:

POST JSON body becomes typed request struct.

### Milestone 5: path/query/header binding

Implement:

```txt
@[path]
@[query]
@[header]
```

Success criterion:

One request struct can combine path, query, header, and body fields.

### Milestone 6: validation

Implement:

```txt
required
min
max
min_len
max_len
email
uuid
```

Success criterion:

Invalid requests return a structured 400 response.

### Milestone 7: OpenAPI

Generate OpenAPI JSON from the service graph.

Success criterion:

`GET /openapi.json` returns valid OpenAPI 3.0 JSON.

### Milestone 8: V client generation

Generate typed V client.

Success criterion:

Client can call example server with typed request/response structs.

## Example final usage target

```v
module main

import vrpc
import users

fn main() {
    mut app := vrpc.new()

    app.use(vrpc.logger())
    app.use(vrpc.cors())

    users.mount_user_service(mut app, users.UserServiceImpl{
        repo: users.new_memory_repo()
    })!

    app.openapi('/openapi.json')!
    app.docs('/docs')!

    app.listen(':3000')!
}
```

With contract:

```v
module users

@[service; prefix: '/users']
pub interface UserService {
    @[post: '/']
    create_user(CreateUserRequest) !CreateUserResponse

    @[get: '/:id']
    get_user(GetUserRequest) !GetUserResponse
}

pub struct CreateUserRequest {
pub:
    name  string @[body; required; min_len: 1]
    email string @[body; required; email]
}

pub struct CreateUserResponse {
pub:
    id    string
    name  string
    email string
}

pub struct GetUserRequest {
pub:
    id string @[path; required]
}

pub struct GetUserResponse {
pub:
    id    string
    name  string
    email string
}
```

With implementation:

```v
module users

pub struct UserServiceImpl {
pub:
    repo UserRepo
}

pub fn (s UserServiceImpl) create_user(req CreateUserRequest) !CreateUserResponse {
    user := s.repo.create(req.name, req.email)!
    return CreateUserResponse{
        id: user.id
        name: user.name
        email: user.email
    }
}

pub fn (s UserServiceImpl) get_user(req GetUserRequest) !GetUserResponse {
    user := s.repo.find_by_id(req.id)!
    return GetUserResponse{
        id: user.id
        name: user.name
        email: user.email
    }
}
```

## Implementation constraints

Prefer explicit generated code over clever runtime abstractions.

Avoid depending on unstable compiler internals unless absolutely necessary.

Make generated code readable and check it into source control.

Do not require runtime reflection.

Design the runtime so the generator can be replaced later.

Keep the service graph as the central abstraction.

## Future features

After MVP:

1. TypeScript client generation.
2. Protobuf schema generation.
3. Connect-style RPC transport.
4. gRPC transport.
5. Streaming procedures.
6. WebSocket procedure transport.
7. Auth middleware with typed user context.
8. Service-level lifecycle hooks.
9. Better dependency injection.
10. Mock server generation.
11. Test client generation.
12. Contract diffing.
13. Backward compatibility checks.
14. Versioned services.
15. CLI scaffolding.

## Design principle

The framework should feel like this:

```txt
Define contracts.
Implement services.
Generate transports.
Ship one binary.
```

Not this:

```txt
Manually wire routes.
Parse requests by hand.
Duplicate schemas across server, docs, and clients.
```

The framework is successful if a developer can add a new API procedure by writing:

```v
pub struct MyRequest {}
pub struct MyResponse {}

@[post: '/thing']
do_thing(MyRequest) !MyResponse
```

then implementing:

```v
pub fn (s MyServiceImpl) do_thing(req MyRequest) !MyResponse
```

and everything else is generated.
