#!/usr/bin/env bash
# Verifica por HTTP que la web responde 200 y sirve el release esperado.
#
# Uso: verify_http.sh <ip> <release_id>
set -euo pipefail

IP="${1:?Falta la IP}"
RELEASE="${2:?Falta el release id}"
URL="http://${IP}/"
BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT

for i in $(seq 1 20); do
  CODE="$(curl -s -o "$BODY" -w '%{http_code}' --max-time 10 -H 'Cache-Control: no-cache' "$URL" || echo "000")"
  if [ "$CODE" = "200" ] && grep -q "build: ${RELEASE}" "$BODY"; then
    echo "OK: ${URL} responde 200 y sirve el release ${RELEASE}"
    exit 0
  fi
  echo "  intento ${i}/20: HTTP ${CODE}, todavía no sirve el release esperado"
  sleep 6
done

echo "ERROR: ${URL} no sirve el release ${RELEASE}" >&2
echo "Última respuesta:" >&2
cat "$BODY" >&2 || true
exit 1
