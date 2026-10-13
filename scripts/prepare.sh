#!/usr/bin/env bash
set -euo pipefail   # corta ante cualquier error

rm -rf dist && mkdir dist          # carpeta limpia de salida
cp web/index.html dist/index.html  # copia el HTML tal cual
tar czf site.tar.gz -C dist .      # el artefacto: un .tar.gz con el sitio
