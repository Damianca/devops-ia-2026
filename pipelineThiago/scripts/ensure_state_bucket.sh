#!/usr/bin/env bash
# Crea (solo si no existe) el bucket S3 que guarda el state de Terraform
# e imprime su nombre por stdout.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
BUCKET="tfstate-${ACCOUNT_ID}-${REGION}"

if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Creando bucket de state: $BUCKET" >&2
  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" > /dev/null
  aws s3api put-bucket-versioning --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled > /dev/null
  aws s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true > /dev/null
fi

echo "$BUCKET"
