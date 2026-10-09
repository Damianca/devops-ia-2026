#!/usr/bin/env bash
set -euo pipefail
dnf install -y nginx
systemctl enable --now amazon-ssm-agent
systemctl enable --now nginx
printf '%s\n' 'Esperando el primer deploy' \
  > /usr/share/nginx/html/index.html

