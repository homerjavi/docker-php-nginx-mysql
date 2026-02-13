#!/bin/bash
# Borra todos los datos de la base de datos MySQL para que se regenere con las credenciales nuevas
# Usa un contenedor alpine temporal para evitar problemas de permisos de sudo/root
echo "⚠️  ADVERTENCIA: Esto borrará PERMANENTEMENTE todos los datos de la base de datos."
read -p "¿Estás seguro? (s/N) " confirm
if [[ $confirm == [sS] || $confirm == [sS][iI] ]]; then
    docker-compose down
    docker run --rm -v $(pwd)/.docker/db/data:/data alpine sh -c "rm -rf /data/*"
    echo "✅ Base de datos reseteada. Ejecuta ahora ./scripts/up.sh"
else
    echo "❌ Operación cancelada."
fi
