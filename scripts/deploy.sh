#!/usr/bin/env bash
# Publica el artefacto de dist/ en la EC2 usando S3 y SSM.
# Uso: deploy.sh <bucket> <instance_id> <version>
set -euo pipefail

BUCKET="$1"
INSTANCE_ID="$2"
VERSION="$3"
DESTINO="s3://${BUCKET}/releases/${VERSION}/"

echo "Subiendo artefacto a ${DESTINO}"
aws s3 cp dist/ "${DESTINO}" --recursive

echo "Esperando que la instancia ${INSTANCE_ID} esté conectada a SSM..."
ESTADO=""
for i in $(seq 1 30); do
  ESTADO=$(aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=${INSTANCE_ID}" \
    --query "InstanceInformationList[0].PingStatus" \
    --output text)
  if [ "${ESTADO}" = "Online" ]; then
    break
  fi
  echo "  Intento ${i}: estado=${ESTADO}"
  sleep 10
done

if [ "${ESTADO}" != "Online" ]; then
  echo "ERROR: la instancia no se conectó a SSM a tiempo"
  exit 1
fi

# Comandos que se ejecutarán dentro de la EC2
PARAMETROS=$(jq -n --arg origen "${DESTINO}" '{
  commands: [
    "set -e",
    "cloud-init status --wait || true",
    "aws s3 cp \($origen) /usr/share/nginx/html/ --recursive --region us-east-1",
    "systemctl reload nginx"
  ]
}')

echo "Enviando comando de despliegue por SSM..."
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "${INSTANCE_ID}" \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy ${VERSION}" \
  --parameters "${PARAMETROS}" \
  --query "Command.CommandId" \
  --output text)

echo "Comando enviado: ${COMMAND_ID}"

RESULTADO=""
for i in $(seq 1 40); do
  sleep 10
  RESULTADO=$(aws ssm get-command-invocation \
    --command-id "${COMMAND_ID}" \
    --instance-id "${INSTANCE_ID}" \
    --query "Status" \
    --output text 2>/dev/null || echo "Pending")
  echo "  Intento ${i}: estado=${RESULTADO}"
  case "${RESULTADO}" in
    Success) break ;;
    Failed|Cancelled|TimedOut)
      echo "ERROR: el despliegue falló en la instancia"
      aws ssm get-command-invocation \
        --command-id "${COMMAND_ID}" \
        --instance-id "${INSTANCE_ID}" \
        --query "StandardErrorContent" \
        --output text
      exit 1
      ;;
  esac
done

if [ "${RESULTADO}" != "Success" ]; then
  echo "ERROR: el despliegue no terminó a tiempo"
  exit 1
fi

echo "Despliegue completado"
