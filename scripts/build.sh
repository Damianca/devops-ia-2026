#!/usr/bin/env bash
# Prepara el artefacto en dist/ con el commit y la fecha del build.
set -euo pipefail

VERSION="${1:-$(git rev-parse HEAD)}"
FECHA="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

echo "Preparando artefacto para la versión ${VERSION}"

rm -rf dist
mkdir -p dist
cp -r app/. dist/

if [ ! -f dist/index.html ]; then
  echo "ERROR: no existe app/index.html"
  exit 1
fi

sed -i "s|__COMMIT__|${VERSION}|g; s|__FECHA__|${FECHA}|g" dist/index.html

if grep -q "__COMMIT__\|__FECHA__" dist/index.html; then
  echo "ERROR: quedaron marcadores sin reemplazar"
  exit 1
fi

if ! grep -q "</html>" dist/index.html; then
  echo "ERROR: index.html parece incompleto"
  exit 1
fi

echo "${VERSION}" > dist/version.txt
echo "Artefacto listo:"
ls -l dist/
