#!/bin/sh
set -e

# Variables para la base de datos
DB_CONNECTION=${DB_CONNECTION:-mysql}
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-laravel}
DB_USERNAME=${DB_USERNAME:-user}
DB_PASSWORD=${DB_PASSWORD:-123456}

# Check if we need to install Laravel
if [ "$INSTALL_LARAVEL" = "true" ] && [ ! -f /var/www/composer.json ]; then
    IS_NEW_INSTALL="true"
else
    IS_NEW_INSTALL="false"
fi

# 1. Instalación de Laravel (si corresponde)
if [ "$IS_NEW_INSTALL" = "true" ]; then
    echo "🚀 Laravel no encontrado en /var/www. Instalando Laravel..."

    # Crear directorio temporal para la instalación
    mkdir -p /tmp/laravel_temp

    if [ -z "$LARAVEL_VERSION" ]; then
        composer create-project laravel/laravel /tmp/laravel_temp
    else
        composer create-project laravel/laravel="${LARAVEL_VERSION}" /tmp/laravel_temp
    fi

    echo "✅ Laravel descargado en directorio temporal."

    # Mover archivos al directorio raíz (incluyendo ocultos)
    # Usamos rsync para mayor robustez, o cp como fallback
    echo "📂 Moviendo archivos a /var/www..."
    if command -v rsync >/dev/null 2>&1; then
        rsync -a /tmp/laravel_temp/ /var/www/
    else
        cp -a /tmp/laravel_temp/. /var/www/
    fi
    rm -rf /tmp/laravel_temp

    echo "✅ Archivos movidos correctamente."
fi

# 2.# Configurar la base de datos en el .env automáticamente (SE EJECUTA SIEMPRE el reemplazo si existe archivo)
if [ -f /var/www/.env ]; then
    echo "🔄 Sincronizando variables de entorno..."
    
    # Base de Datos
    sed -i "s|^#\?\s*DB_CONNECTION=.*|DB_CONNECTION=$DB_CONNECTION|" /var/www/.env
    sed -i "s|^#\?\s*DB_HOST=.*|DB_HOST=$DB_HOST|" /var/www/.env
    sed -i "s|^#\?\s*DB_PORT=.*|DB_PORT=$DB_PORT|" /var/www/.env
    sed -i "s|^#\?\s*DB_DATABASE=.*|DB_DATABASE=$DB_DATABASE|" /var/www/.env
    sed -i "s|^#\?\s*DB_USERNAME=.*|DB_USERNAME=$DB_USERNAME|" /var/www/.env
    sed -i "s|^#\?\s*DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" /var/www/.env
    
    # App General
    sed -i "s|^#\?\s*APP_NAME=.*|APP_NAME=\"$APP_NAME\"|" /var/www/.env
    sed -i "s|^#\?\s*APP_URL=.*|APP_URL=http://localhost:${NGINX_PORT:-80}|" /var/www/.env

    # Configuración de Puertos y Vite (Si no existen, se agregan al final)
    # VITE_PORT
    if grep -q "VITE_PORT=" /var/www/.env; then
        sed -i "s|^#\?\s*VITE_PORT=.*|VITE_PORT=${VITE_PORT:-5173}|" /var/www/.env
    else
        echo "VITE_PORT=${VITE_PORT:-5173}" >> /var/www/.env
    fi

    # NGINX_PORT
    if grep -q "NGINX_PORT=" /var/www/.env; then
        sed -i "s|^#\?\s*NGINX_PORT=.*|NGINX_PORT=${NGINX_PORT:-80}|" /var/www/.env
    else
        echo "NGINX_PORT=${NGINX_PORT:-80}" >> /var/www/.env
    fi
fi

# 3. Pasos Post-Instalación (solo si acabamos de instalar)
if [ "$IS_NEW_INSTALL" = "true" ]; then
    echo "🔧 Configuración inicial completada."

    echo "🔧 Configuración de base de datos establecida en .env"

    php artisan migrate --seed

    # 📦 Instalar dependencias de Node.js solo si no están instaladas
    if [ ! -d "/var/www/node_modules" ]; then
        echo "📦 Instalando dependencias de Node.js..."
        npm install
    fi

    # 🛠 Modificar vite.config.js si no tiene la sección `server`
    if [ -f "/var/www/vite.config.js" ] && ! grep -q "server: {" /var/www/vite.config.js; then
        echo "🔧 Añadiendo configuración de servidor en vite.config.js..."
        # Insertar configuración del servidor Vite para Docker
        # Usamos variables de entorno para puerto de cliente si están definidas
        VITE_PORT=${VITE_PORT:-5173}
        sed -i "/export default defineConfig({/a \    server: {\n        host: '0.0.0.0',\n        port: 5173,\n        hmr: {\n            host: 'localhost',\n            clientPort: ${VITE_PORT}\n        }\n    }," /var/www/vite.config.js
    fi

else
    echo "🔹 Laravel ya está instalado (o INSTALL_LARAVEL=false). Omitiendo instalación nueva."
fi

exec "$@"