#!/bin/bash
# Abre una terminal bash en el contenedor PHP (como usuario laravel)
# Para acceder como root: docker compose exec --user root php bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "Accediendo al contenedor PHP..."
docker compose --env-file .env_docker exec php bash
