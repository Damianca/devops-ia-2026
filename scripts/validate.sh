#!/usr/bin/env bash
# Validaciones de CI que no son de Terraform: scripts y HTML.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HTML="$ROOT/app/index.html"
fail=0

echo "==> ShellCheck"
shellcheck "$ROOT"/scripts/*.sh "$ROOT"/infra/user_data.sh || fail=1

echo "==> Validación de HTML"
[[ -s "$HTML" ]] || { echo "ERROR: falta $HTML"; exit 1; }

check() { # check <regex> <mensaje>
  if ! grep -Eqi "$1" "$HTML"; then echo "ERROR: $2"; fail=1; fi
}
check '^<!DOCTYPE html>'   "falta <!DOCTYPE html> en la primera línea"
check '<html[^>]*lang='    "falta atributo lang en <html>"
check '<meta charset='     "falta <meta charset>"
check '<title>.+</title>'  "falta <title>"
check '__COMMIT_SHA__'     "falta el placeholder __COMMIT_SHA__ (la verificación HTTP lo necesita)"

# Etiquetas estructurales balanceadas
for tag in html head body main; do
  open=$(grep -Eoi "<${tag}[ >]" "$HTML" | wc -l)
  close=$(grep -Eoi "</${tag}>" "$HTML" | wc -l)
  if [[ "$open" -ne "$close" ]]; then
    echo "ERROR: <${tag}> abiertas=${open} cerradas=${close}"; fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "Validación FALLIDA"; exit 1
fi
echo "Validación OK"
