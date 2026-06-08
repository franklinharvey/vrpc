# vrpc

Contract-first HTTP service framework for [V](https://vlang.io), described in [brief.md](brief.md).

## Repository layout

| Path | Purpose |
|------|---------|
| [TASKS.md](TASKS.md) | Implementation checklist |
| [vrpc/](vrpc/) | Runtime library + `vgen` codegen CLI |
| [examples/](examples/) | `hello`, `users`, `htmx` demos |

## Requirements

- V 0.5+ (`brew install vlang` on macOS, or [install from source](https://github.com/vlang/v))
- On macOS only, tests may need: `export LIBRARY_PATH="/opt/homebrew/lib:$LIBRARY_PATH"`

## CI locally

Same checks as GitHub Actions:

```bash
./scripts/ci.sh
```

Or in Docker (Ubuntu + V 0.5.1 + gcc, no local V install needed):

```bash
docker build --platform linux/amd64 -f Dockerfile.ci -t vrpc-ci .
docker run --rm --platform linux/amd64 vrpc-ci
```

## Commands

```bash
cd vrpc
v test .

cd ../examples/users
v test .    # e2e: create/get/list, openapi, validation, not_found

v run cmd/vgen generate ../examples/users   # from vrpc/

cd ../examples/users
v run .

cd ../examples/htmx
v run .    # open http://127.0.0.1:3002
```
