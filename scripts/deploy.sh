#!/usr/bin/env bash
set -euo pipefail
: "${STATE_BUCKET:?}"
: "${AWS_REGION:?}"
: "${GITHUB_SHA:?}"
export INSTANCE_ID
INSTANCE_ID=$(terraform -chdir=infra output -raw instance_id)
export APP_URI="s3://${STATE_BUCKET}/artifacts/${GITHUB_SHA}/index.html"
aws s3 cp dist/index.html "$APP_URI" --region "$AWS_REGION"

# EC2 running no implica que SSM ya este disponible.
ready=false
for attempt in $(seq 1 60); do
  status=$(aws ssm describe-instance-information \
     --filters "Key=InstanceIds,Values=$INSTANCE_ID" \
     --query 'InstanceInformationList[0].PingStatus' \
     --output text)
  if [ "$status" = "Online" ]; then
     ready=true
     break
  fi
  sleep 10
done
[ "$ready" = true ] || { echo 'SSM no disponible'; exit 1; }

# JSON correcto; no concatenar el HTML en un comando remoto.
python3 - <<'PYCODE'
import json, os, shlex
uri = shlex.quote(os.environ["APP_URI"])
region = shlex.quote(os.environ["AWS_REGION"])
commands = [
    "set -eu",
    "cloud-init status --wait",
    f"aws s3 cp {uri} /tmp/lab-index.html --region {region}",
    "install -m 0644 /tmp/lab-index.html /usr/share/nginx/html/index.html",
    "nginx -t",
    "systemctl reload nginx",
    "curl --fail --silent http://localhost/ > /dev/null"
]
with open("params.json", "w") as out:
    json.dump({"commands": commands, "executionTimeout": ["900"]}, out)
PYCODE
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name AWS-RunShellScript \
  --parameters file://params.json \
  --timeout-seconds 600 \
  --query 'Command.CommandId' --output text)

# El waiter por defecto puede terminar antes que cloud-init.
status=Pending
for attempt in $(seq 1 120); do
  status=$(aws ssm get-command-invocation \
     --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" \
     --query Status --output text 2>/dev/null || echo Pending)
  case "$status" in
     Success|Failed|Cancelled|TimedOut) break ;;
  esac
  sleep 10
done
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" \
  --query '{Status:Status,Out:StandardOutputContent,Err:StandardErrorContent}'
[ "$status" = Success ] || { echo 'Deploy fallido'; exit 1; }

URL=$(terraform -chdir=infra output -raw web_url)
curl --fail --silent --show-error --retry 12 \
  --retry-all-errors --retry-delay 5 --connect-timeout 5 \
  --max-time 15 "$URL/" -o response.html
grep -Fq "$GITHUB_SHA" response.html
printf 'App verificada: %s\n' "$URL"
printf '### Aplicacion desplegada\n%s\nCommit: %s\n' \
  "$URL" "$GITHUB_SHA" >> "$GITHUB_STEP_SUMMARY"

