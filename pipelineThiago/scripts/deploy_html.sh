#!/usr/bin/env bash
# Publica el artefacto en la EC2 mediante SSM:
#   1. sube el archivo a un bucket S3 privado (releases/<release_id>/index.html)
#   2. espera a que la instancia esté online en SSM
#   3. ejecuta en la instancia un comando que lo copia a /var/www/html
#
# Uso: deploy_html.sh <archivo> <bucket> <instance_id> <release_id>
set -euo pipefail

FILE="${1:?Falta el archivo a publicar}"
BUCKET="${2:?Falta el bucket}"
INSTANCE_ID="${3:?Falta el instance id}"
RELEASE="${4:?Falta el release id}"
REGION="${AWS_REGION:-us-east-1}"
KEY="releases/${RELEASE}/index.html"

if [ ! -s "$FILE" ]; then
  echo "ERROR: '$FILE' no existe o está vacío" >&2
  exit 1
fi

echo "Subiendo artefacto a s3://${BUCKET}/${KEY}"
aws s3 cp "$FILE" "s3://${BUCKET}/${KEY}" --content-type text/html --region "$REGION"

# Si la instancia recién recibió su rol, el agente de SSM puede tardar unos minutos en registrarse
echo "Esperando que ${INSTANCE_ID} esté online en SSM..."
PING="desconocido"
for i in $(seq 1 40); do
  PING="$(aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=${INSTANCE_ID}" \
    --query 'InstanceInformationList[0].PingStatus' \
    --output text --region "$REGION" 2>/dev/null || echo "desconocido")"
  if [ "$PING" = "Online" ]; then
    break
  fi
  echo "  intento ${i}/40: estado SSM = ${PING}"
  sleep 15
done
if [ "$PING" != "Online" ]; then
  echo "ERROR: la instancia no quedó online en SSM" >&2
  exit 1
fi

# Script que se ejecuta dentro de la instancia (idempotente)
REMOTE="$(cat <<EOS
set -euo pipefail
export AWS_DEFAULT_REGION=${REGION}
export DEBIAN_FRONTEND=noninteractive
if ! command -v aws > /dev/null 2>&1; then
  apt-get update -y
  apt-get install -y awscli
fi
if ! command -v nginx > /dev/null 2>&1; then
  apt-get update -y
  apt-get install -y nginx
fi
systemctl enable --now nginx
# Limpieza del esquema anterior (cron que bajaba el HTML de S3)
rm -f /etc/cron.d/sync-web
aws s3 cp s3://${BUCKET}/${KEY} /var/www/html/index.html
chmod 644 /var/www/html/index.html
systemctl reload nginx
EOS
)"

PARAMS="$(jq -n --arg cmd "$REMOTE" '{commands: [$cmd]}')"

CMD_ID="$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name AWS-RunShellScript \
  --comment "Deploy index.html ${RELEASE}" \
  --parameters "$PARAMS" \
  --query 'Command.CommandId' --output text --region "$REGION")"
echo "Comando SSM enviado: ${CMD_ID}"

STATUS="Pending"
for i in $(seq 1 60); do
  sleep 5
  STATUS="$(aws ssm get-command-invocation \
    --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
    --query Status --output text --region "$REGION" 2>/dev/null || echo "Pending")"
  case "$STATUS" in
    Success | Failed | Cancelled | TimedOut) break ;;
    *) echo "  intento ${i}/60: estado del comando = ${STATUS}" ;;
  esac
done

echo "--- stdout ---"
aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
  --query StandardOutputContent --output text --region "$REGION" || true
echo "--- stderr ---"
aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
  --query StandardErrorContent --output text --region "$REGION" || true

if [ "$STATUS" != "Success" ]; then
  echo "ERROR: el comando SSM terminó con estado ${STATUS}" >&2
  exit 1
fi

echo "Artefacto ${RELEASE} publicado en ${INSTANCE_ID}"
