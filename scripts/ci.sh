#!/usr/bin/env bash
# Run the same checks as GitHub Actions locally.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if ! command -v v >/dev/null 2>&1; then
  echo "V is not installed. Install from https://github.com/vlang/v or use: docker build -f Dockerfile.ci -t vrpc-ci . && docker run --rm vrpc-ci"
  exit 1
fi

echo "==> install dependencies"
(cd vrpc && v install)
(cd examples/users && v install)

echo "==> vrpc runtime + vgen"
(cd vrpc && v -cc gcc test .)

echo "==> examples/users e2e"
(cd examples/users && v -cc gcc test .)

echo "OK"
