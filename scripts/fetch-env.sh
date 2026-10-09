#!/usr/bin/env bash
set -euo pipefail

# Uso: fetch-env.sh <ruta-ssm> <archivo-salida>
ssm_path="$1"
output_file="$2"
region="us-east-2"

log() { echo "[fetch-env] $*"; }

# Escribir en un temporal: si SSM falla, el .env actual queda intacto.
tmp=$(mktemp "${output_file}.XXXXXX")
trap 'rm -f "$tmp"' EXIT
chmod 600 "$tmp"

log "Inicio: leyendo variables de $ssm_path ($region)"
aws ssm get-parameters-by-path \
  --path "$ssm_path" \
  --with-decryption \
  --region "$region" \
  --query "Parameters[*].[Name,Value]" \
  --output text | while IFS=$'\t' read -r name value; do
  echo "$(basename "$name")=${value}" >> "$tmp"
done

# Una ruta vacía o mal escrita no es error para SSM: no pisar el .env con nada.
count=$(wc -l < "$tmp")
if [ "$count" -eq 0 ]; then
  log "ERROR: no hay parámetros bajo $ssm_path"
  exit 1
fi

# Conservar el dueño del directorio (el hook corre como root).
chown --reference="$(dirname "$output_file")" "$tmp"
mv "$tmp" "$output_file"
log "Fin: $count variables guardadas en $output_file"
