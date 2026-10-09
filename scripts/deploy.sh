#!/usr/bin/env bash
set -euo pipefail

ssm_path="/production/docmost/"

log() { echo "[deploy] $*"; }
trap 'log "ERROR: falló en la línea $LINENO"' ERR

# Instalación y repo copiado por CodeDeploy (appspec.yml) viven en el mismo directorio.
cd /home/ec2-user/docmost
log "Inicio: deployment ${DEPLOYMENT_ID:-manual} en $PWD"

# Regenerar el .env desde SSM; Compose recrea el contenedor si cambió alguna variable.
log "1/2 Variables de entorno desde $ssm_path"
scripts/fetch-env.sh "$ssm_path" .env

# Por ahora no se construye imagen: se usa la definida en docker-compose.yml.
log "2/2 Levantando servicio docmost"
docker-compose up --detach --no-deps docmost

log "Fin: servicio levantado con imagen $(docker-compose images --quiet docmost)"
