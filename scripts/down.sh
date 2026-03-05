#!/bin/bash
# Detiene y elimina los contenedores
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

docker compose --env-file .env_docker down
echo "🛑 Contenedores detenidos."
