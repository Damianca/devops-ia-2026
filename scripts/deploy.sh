#!/usr/bin/env bash
set -euo pipefail   # corta ante cualquier error
INSTANCE_ID="$1"; BUCKET="$2"; SHA="$3"
KEY="artifacts/${SHA}/site.tar.gz"

# 1) Sube el MISMO artefacto de CI a S3 (la EC2 lo baja de ahí)
aws s3 cp site.tar.gz "s3://${BUCKET}/${KEY}"

# 2) Espera a que el agente SSM de la EC2 esté online (tarda ~1-2 min tras crearla)
status="None"
for _ in $(seq 1 30); do
  status=$(aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=${INSTANCE_ID}" \
    --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || true)
  [ "$status" = "Online" ] && break
  sleep 10
done
[ "$status" = "Online" ] || { echo "SSM no quedó Online"; exit 1; }

# 3) Comandos que corren DENTRO de la EC2 (jq arma el JSON sin problemas de comillas)
PARAMS=$(jq -n --arg b "$BUCKET" --arg k "$KEY" '{commands: [
  "cloud-init status --wait || true",
  "aws s3 cp s3://\($b)/\($k) /tmp/site.tar.gz --region us-east-1",
  "rm -rf /usr/share/nginx/html/*",
  "tar xzf /tmp/site.tar.gz -C /usr/share/nginx/html",
  "systemctl reload nginx"
]}')

CMD_ID=$(aws ssm send-command --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" --parameters "$PARAMS" \
  --query 'Command.CommandId' --output text)

# 4) Espera a que termine; si el comando falla, el job falla
aws ssm wait command-executed --command-id "$CMD_ID" --instance-id "$INSTANCE_ID"
echo "Publicado ${SHA:0:7}"
