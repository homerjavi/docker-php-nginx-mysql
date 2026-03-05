#!/bin/bash
# Borra todos los datos de MySQL para que se regenere con las credenciales actuales.
# Usa un contenedor alpine temporal para evitar problemas de permisos.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "⚠️  ADVERTENCIA: Esto borrará PERMANENTEMENTE todos los datos de la base de datos."
read -p "¿Estás seguro? (s/N) " confirm
if [[ $confirm == [sS] || $confirm == [sS][iI] ]]; then
    docker compose --env-file .env_docker down
    docker run --rm -v "$(pwd)/.docker/db/data:/data" alpine sh -c "rm -rf /data/*"
    echo "✅ Base de datos reseteada. Ejecuta ahora ./scripts/up.sh"
else
    echo "❌ Operación cancelada."
fi
