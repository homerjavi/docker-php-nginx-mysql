#!/bin/bash
# Ejecuta comandos de artisan dentro del contenedor
# Uso: ./scripts/artisan.sh migrate
docker exec testdocker-php-1 php artisan "$@"
