#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if [[ $# -ne 1 || "$1" != sql/*.hql || ! -f "$1" ]]; then
  echo 'Uso: ./scripts/ejecutar.sh sql/archivo.hql' >&2
  exit 1
fi
script_path=$(realpath -- "$1")
if [[ "$script_path" != "$(pwd)/sql/"* ]]; then
  echo 'El archivo debe estar dentro de sql/.' >&2
  exit 1
fi
relative_path=${script_path#"$(pwd)/sql/"}
exec docker compose exec -T master beeline \
  -u jdbc:hive2://localhost:10000 -n root \
  --silent=true --showHeader=true --outputformat=table --maxWidth=240 --maxColumnWidth=40 \
  -f "/data/sql/$relative_path"
