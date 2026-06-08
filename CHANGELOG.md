# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-06-08

### Added

- Contract-first HTTP service runtime for [V](https://vlang.io)
- `vgen` CLI: parse contracts, emit V server mounts, V clients, TypeScript clients, OpenAPI, and Zod schemas
- JSON body binding with path, query, and header field sources
- Struct validation (`required`, `min`, `max`, `min_len`, `max_len`, `email`, `uuid`)
- OpenAPI 3.0 generation with `/openapi.json` and minimal `/docs` Swagger UI
- Middleware support (logger, CORS)
- Examples: `hello` (minimal server), `users` (full contract stack), `htmx` (HTML partials)
- CI via GitHub Actions and `./scripts/ci.sh` (Docker option via `Dockerfile.ci`)

[0.1.0]: https://github.com/franklinharvey/vrpc/releases/tag/v0.1.0
