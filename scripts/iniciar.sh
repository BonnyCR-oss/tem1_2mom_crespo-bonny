#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if ! docker info >/dev/null 2>&1; then
  echo 'Docker no está disponible. Revisa el daemon y el acceso de tu usuario.' >&2
  exit 1
fi
mkdir -p .runtime resultados
# Construye la imagen con las dependencias y levanta este proyecto.
docker compose up -d --build
printf 'Esperando a HiveServer2; consulta el avance en .runtime/inicio.log\n'
for ((attempt=1; attempt<=60; attempt++)); do
  if timeout 20s docker compose exec -T master beeline \
      -u jdbc:hive2://localhost:10000 -n root \
      --silent=true --showHeader=false --outputformat=tsv2 \
      -e "SELECT 'ENTORNO_OK';" > .runtime/inicio.log 2>&1 &&
      grep -qx 'ENTORNO_OK' .runtime/inicio.log; then
    printf 'Hive responde. Ejecuta: ./scripts/ejecutar.sh sql/00_verificar_entorno.hql\n'
    exit 0
  fi
  if (( attempt % 6 == 0 )); then
    printf 'Intento %s/60. Detalle: .runtime/inicio.log\n' "$attempt"
  fi
  sleep 5
done
printf 'Hive no respondió a tiempo. Revisa .runtime/inicio.log y docker compose logs --tail=100 master hivemetastore\n' >&2
exit 1
