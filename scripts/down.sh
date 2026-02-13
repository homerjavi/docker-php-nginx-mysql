#!/bin/bash
# Detiene los contenedores usando el archivo de entorno correcto
docker-compose --env-file .env_docker down
echo "🛑 Contenedores detenidos."
