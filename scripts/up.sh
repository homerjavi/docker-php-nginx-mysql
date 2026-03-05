#!/bin/bash
# Construye e inicia los contenedores
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

docker compose --env-file .env_docker up -d --build

source .env_docker
echo "🚀 Contenedores iniciados."
echo "🌍 Web:   http://localhost:${NGINX_PORT:-80}"
echo "🎨 Vite:  http://localhost:${VITE_PORT:-5173}  (logs: docker compose logs php)"
echo "🗄️  MySQL: localhost:${MYSQL_PORT:-3306}"
