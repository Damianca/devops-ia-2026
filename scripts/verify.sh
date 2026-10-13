#!/usr/bin/env bash
# Verifica por HTTP que la web publicada corresponde a la versión esperada.
# Uso: verify.sh <url> <version>
set -euo pipefail

URL="$1"
VERSION="$2"

echo "Verificando ${URL} (se espera la versión ${VERSION})"

for i in $(seq 1 20); do
  CONTENIDO=$(curl -fsS --max-time 10 "${URL}" || true)
  if grep -q "${VERSION}" <<< "${CONTENIDO}"; then
    echo "OK: la web muestra la versión ${VERSION}"
    exit 0
  fi
  echo "  Intento ${i}: todavía no responde con la versión esperada"
  sleep 10
done

echo "ERROR: la web no muestra la versión esperada"
exit 1
