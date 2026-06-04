# vrpc / vesper

Contract-first HTTP service framework for [V](https://vlang.io), described in [brief.md](brief.md).

## Repository layout

| Path | Purpose |
|------|---------|
| [TASKS.md](TASKS.md) | Implementation checklist |
| [vesper/](vesper/) | Runtime library + `vesper` CLI |
| [examples/](examples/) | `hello`, `users` demos |

## Requirements

- V 0.5+ (`brew install vlang` on macOS)
- For tests/linking on macOS: `export LIBRARY_PATH="/opt/homebrew/lib:$LIBRARY_PATH"`

## Commands

```bash
cd vesper
v test .

cd ../examples/users
v test .    # e2e: create/get/list, openapi, validation, not_found

v run cmd/vgen generate ../examples/users   # from vesper/

cd ../examples/users
v run .
```
