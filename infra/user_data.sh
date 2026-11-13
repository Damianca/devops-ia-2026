#!/bin/bash
# Prepara Nginx. El contenido del sitio lo publica el pipeline vía SSM.
set -euxo pipefail

dnf install -y nginx
cat > /usr/share/nginx/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="es"><head><meta charset="utf-8"><title>Esperando despliegue</title></head>
<body><p>Instancia lista. Esperando el primer despliegue del pipeline.</p></body></html>
EOF
systemctl enable --now nginx
