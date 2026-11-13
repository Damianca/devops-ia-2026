#!/usr/bin/env bash
# Prepara el artefacto web: copia app/ a dist/ e inyecta metadatos del build.
# Uso: build.sh <commit_sha> <branch> <run_number>
set -euo pipefail

SHA="${1:?commit sha requerido}"
BRANCH="${2:-local}"
RUN="${3:-0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

rm -rf "$DIST"
mkdir -p "$DIST"
cp -R "$ROOT/app/." "$DIST/"

sed -i \
  -e "s|__COMMIT_SHA__|${SHA}|g" \
  -e "s|__BRANCH__|${BRANCH}|g" \
  -e "s|__RUN_NUMBER__|${RUN}|g" \
  -e "s|__BUILD_DATE__|${DATE}|g" \
  "$DIST/index.html"

# Endpoint simple para verificar la versión desplegada
printf '%s\n' "$SHA" > "$DIST/version.txt"

if grep -q '__[A-Z_]*__' "$DIST/index.html"; then
  echo "ERROR: quedaron placeholders sin reemplazar"; exit 1
fi

echo "Artefacto listo en $DIST:"
ls -la "$DIST"
