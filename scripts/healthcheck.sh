#!/usr/bin/env bash
set -euo pipefail

# /api/health responde 200 sólo si la app llega a la base de datos y a Redis.
url="http://localhost:3000/api/health"
attempts=7
interval=5

log() { echo "[healthcheck] $*"; }

log "Inicio: esperando $url (hasta $((attempts * interval))s)"
for ((i = 1; i <= attempts; i++)); do
  if curl --fail --silent --show-error --max-time 5 --output /dev/null "$url" 2>/dev/null; then
    log "Fin: servicio saludable en el intento $i/$attempts"
    exit 0
  fi
  log "Intento $i/$attempts sin respuesta, reintentando en ${interval}s"
  sleep "$interval"
done

log "ERROR: el servicio no respondió; últimos logs del contenedor:"
cd /home/ec2-user/docmost
docker compose logs --tail 50 docmost >&2 || true
exit 1
