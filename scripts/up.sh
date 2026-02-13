#!/bin/bash
# Levanta los contenedores usando el archivo de entorno correcto para los puertos
docker-compose --env-file .env_docker up -d --build
source .env_docker
echo "🚀 Contenedores iniciados."
echo "🌍 Web: http://localhost:${NGINX_PORT:-8004}"
echo "🗄️  MySQL Externo: localhost:${MYSQL_PORT:-3004}"
echo "-----------------------------------------------------"
echo "⚠️  Nota: Si usas DBeaver, asegúrate de usar el puerto ${MYSQL_PORT:-3004}"
