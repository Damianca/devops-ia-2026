#!/usr/bin/env bash
set -euo pipefail

URL="${1:?Uso: verify.sh http://IP [commit]}"
SHORT="${2:-}"

for i in {1..20}; do
  if curl -fs "$URL" -o /tmp/resp.html; then
    break
  fi
  echo "Intento $i: la web todavía no responde, espero 10s..."
  sleep 10
done

curl -fs "$URL" -o /tmp/resp.html
if [ -n "$SHORT" ]; then
  grep -q "$SHORT" /tmp/resp.html
fi
echo "Verificación OK: $URL"
