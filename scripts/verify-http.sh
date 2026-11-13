#!/usr/bin/env bash
# Verifica por HTTP que la web sirve la versión (commit) esperada.
# Uso: verify-http.sh <url> <commit_sha> [intentos]
set -euo pipefail

URL="${1:?url requerida}"
SHA="${2:?commit sha requerido}"
TRIES="${3:-30}"

for i in $(seq 1 "$TRIES"); do
  served=$(curl -fsS --max-time 5 "${URL%/}/version.txt" 2>/dev/null || true)
  if [[ "$served" == "$SHA" ]] && curl -fsS --max-time 5 "$URL" | grep -q "$SHA"; then
    echo "OK: $URL sirve el commit $SHA (intento $i)"
    exit 0
  fi
  echo "  intento $i/$TRIES: servido='${served:-sin respuesta}' esperado='$SHA'"
  sleep 10
done

echo "ERROR: $URL no sirve el commit $SHA"
exit 1
