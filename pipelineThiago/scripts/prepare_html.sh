#!/usr/bin/env bash
# Prepara el HTML a publicar: valida el archivo, agrega metadata de build
# y deja el resultado (más su checksum) en el directorio de salida.
#
# Uso: prepare_html.sh <index.html> <dist_dir> <release_id>
set -euo pipefail

SRC="${1:?Falta el archivo HTML de origen}"
OUT_DIR="${2:?Falta el directorio de salida}"
RELEASE="${3:?Falta el release id (por ejemplo el SHA del commit)}"

if [ ! -s "$SRC" ]; then
  echo "ERROR: '$SRC' no existe o está vacío" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
cp "$SRC" "$OUT_DIR/index.html"

# Marca de build: la usa verify_http.sh para confirmar qué versión se está sirviendo
printf '\n<!-- build: %s | %s -->\n' "$RELEASE" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUT_DIR/index.html"

(cd "$OUT_DIR" && sha256sum index.html > index.html.sha256)

echo "HTML preparado en $OUT_DIR/index.html (release $RELEASE)"
