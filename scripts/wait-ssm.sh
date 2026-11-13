#!/usr/bin/env bash
# Espera a que la instancia esté registrada y Online en SSM.
# Uso: wait-ssm.sh <instance_id> [timeout_segundos]
set -euo pipefail

ID="${1:?instance id requerido}"
TIMEOUT="${2:-600}"
elapsed=0

echo "Esperando que $ID esté Online en SSM..."
while (( elapsed < TIMEOUT )); do
  status=$(aws ssm describe-instance-information \
    --filters "Key=InstanceIds,Values=${ID}" \
    --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || true)
  if [[ "$status" == "Online" ]]; then
    echo "SSM Online (${elapsed}s)"
    exit 0
  fi
  echo "  estado=${status:-desconocido} (${elapsed}s)"
  sleep 10
  elapsed=$((elapsed + 10))
done

echo "ERROR: la instancia no quedó Online en SSM tras ${TIMEOUT}s"
exit 1
