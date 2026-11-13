#!/usr/bin/env bash
# Publica en Nginx el artefacto ya subido a S3, ejecutando comandos vía SSM.
# Uso: deploy-ssm.sh <instance_id> <bucket> <s3_key>
set -euo pipefail

ID="${1:?instance id requerido}"
BUCKET="${2:?bucket requerido}"
KEY="${3:?s3 key requerida}"

# Comandos que corren DENTRO de la EC2 (como root, vía AWS-RunShellScript)
read -r -d '' REMOTE <<EOF || true
set -eu
cloud-init status --wait >/dev/null || true
command -v nginx >/dev/null || dnf install -y nginx
TMP=\$(mktemp -d)
aws s3 cp "s3://${BUCKET}/${KEY}" "\$TMP/site.tar.gz" --region us-east-1
mkdir -p "\$TMP/site"
tar -xzf "\$TMP/site.tar.gz" -C "\$TMP/site"
rm -rf /usr/share/nginx/html.new
cp -R "\$TMP/site" /usr/share/nginx/html.new
rm -rf /usr/share/nginx/html.old
mv /usr/share/nginx/html /usr/share/nginx/html.old
mv /usr/share/nginx/html.new /usr/share/nginx/html
systemctl enable --now nginx
systemctl reload nginx
rm -rf "\$TMP"
echo "Desplegado: \$(cat /usr/share/nginx/html/version.txt)"
EOF

PARAMS=$(jq -n --arg c "$REMOTE" '{commands: ($c | split("\n")), executionTimeout: ["600"]}')

CMD_ID=$(aws ssm send-command \
  --instance-ids "$ID" \
  --document-name "AWS-RunShellScript" \
  --comment "deploy ${KEY}" \
  --parameters "$PARAMS" \
  --query 'Command.CommandId' --output text)

echo "SSM CommandId: $CMD_ID"

# Polling propio: el waiter de la CLI corta a los ~100 s y en el primer deploy
# 'cloud-init status --wait' (dnf install nginx) puede tardar más.
STATUS=Pending
for _ in $(seq 1 60); do
  STATUS=$(aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$ID" \
    --query 'Status' --output text 2>/dev/null || echo Pending)
  case "$STATUS" in
    Success | Failed | Cancelled | TimedOut) break ;;
  esac
  sleep 10
done
echo "Estado SSM: $STATUS"
echo "---- stdout ----"
aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$ID" \
  --query 'StandardOutputContent' --output text
echo "---- stderr ----"
aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$ID" \
  --query 'StandardErrorContent' --output text

if [[ "$STATUS" != "Success" ]]; then
  echo "ERROR: el comando SSM terminó con estado $STATUS"
  exit 1
fi
echo "Deploy por SSM OK"
