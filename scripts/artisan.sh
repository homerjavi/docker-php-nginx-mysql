#!/bin/bash
# Ejecuta comandos de artisan dentro del contenedor PHP
# Uso: ./scripts/artisan.sh migrate
#      ./scripts/artisan.sh make:controller UserController
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

docker compose --env-file .env_docker exec php php artisan "$@"
