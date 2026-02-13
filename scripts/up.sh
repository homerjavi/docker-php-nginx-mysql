#!/bin/bash
# Levanta los contenedores usando el archivo de entorno correcto para los puertos
docker-compose --env-file .env_docker up -d --build
echo "🚀 Contenedores iniciados."
echo "🌍 Web: http://localhost:8001"
echo "🗄️  MySQL Externo: localhost:3001"
