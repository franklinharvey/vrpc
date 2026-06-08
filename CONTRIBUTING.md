# Contributing

Thanks for your interest in vrpc. This project is early-stage; focused contributions that match the [design brief](brief.md) are especially welcome.

## Before you open a PR

1. Read [brief.md](brief.md) for the product thesis (contract-first, not route-first).
2. Run the full CI suite locally:

   ```bash
   ./scripts/ci.sh
   ```

   Without a local V install, use Docker:

   ```bash
   docker build --platform linux/amd64 -f Dockerfile.ci -t vrpc-ci .
   docker run --rm --platform linux/amd64 vrpc-ci
   ```

3. Add or update tests when changing runtime behavior or codegen output. Golden tests live under `vrpc/cmd/vgen/`.

## Project layout

| Path | Purpose |
|------|---------|
| `vrpc/` | Runtime library and `vgen` CLI |
| `examples/` | Runnable demos and e2e tests |
| `brief.md` | Design document |
| `scripts/ci.sh` | Local CI entrypoint (mirrors GitHub Actions) |

## Pull requests

- Keep changes scoped to one concern when possible.
- Describe what changed and how you tested it (the PR template prompts for this).
- Prefer explicit codegen and small runtime over reflection-heavy magic.

## Reporting issues

Use [GitHub Issues](https://github.com/franklinharvey/vrpc/issues) with the bug or feature templates. For security concerns, see [SECURITY.md](SECURITY.md).

## Code style

Match surrounding V code: clear names, minimal comments, tests for non-obvious behavior. Run `v test` in the package you changed before submitting.
