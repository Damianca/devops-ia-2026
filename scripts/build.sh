#!/usr/bin/env bash
set -euo pipefail

COMMIT="${1:-local}"
SHORT="${COMMIT:0:7}"

rm -rf dist
mkdir -p dist
sed "s/__COMMIT__/${SHORT}/g" web/index.html > dist/index.html

echo "Build listo. Commit: ${SHORT}"
