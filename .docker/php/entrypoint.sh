#!/bin/sh
set -e

# Variables para la base de datos
DB_CONNECTION=${DB_CONNECTION:-mysql}
DB_HOST=${DB_HOST:-db}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-laravel}
DB_USERNAME=${DB_USERNAME:-user}
DB_PASSWORD=${DB_PASSWORD:-123456}

# Si Laravel no está instalado, lo instala sin configurar SQLite
if [ "$INSTALL_LARAVEL" = "true" ] && [ ! -f /var/www/app/composer.json ]; then
    echo "🚀 Laravel no encontrado en /var/www/app. Instalando Laravel..."

    if [ -z "$LARAVEL_VERSION" ]; then
        composer create-project laravel/laravel /var/www/app
    else
        composer create-project laravel/laravel="${LARAVEL_VERSION}" /var/www/app
    fi

    echo "✅ Laravel instalado en /var/www/app"

    # Copiar el .env de ejemplo, pero sin configurar SQLite
    cp /var/www/app/.env.example /var/www/app/.env

    # Configurar la base de datos en el .env automáticamente 
    sed -i "s|^#\?\s*DB_CONNECTION=.*|DB_CONNECTION=$DB_CONNECTION|" /var/www/app/.env
    sed -i "s|^#\?\s*DB_HOST=.*|DB_HOST=$DB_HOST|" /var/www/app/.env
    sed -i "s|^#\?\s*DB_PORT=.*|DB_PORT=$DB_PORT|" /var/www/app/.env
    sed -i "s|^#\?\s*DB_DATABASE=.*|DB_DATABASE=$DB_DATABASE|" /var/www/app/.env
    sed -i "s|^#\?\s*DB_USERNAME=.*|DB_USERNAME=$DB_USERNAME|" /var/www/app/.env
    sed -i "s|^#\?\s*DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" /var/www/app/.env

    echo "🔧 Configuración de base de datos establecida en .env"

    php artisan migrate --seed

    # 📦 Instalar dependencias de Node.js solo si no están instaladas
    if [ ! -d "/var/www/app/node_modules" ]; then
        echo "📦 Instalando dependencias de Node.js..."
        cd /var/www/app && npm i
    fi

    # 🛠 Modificar vite.config.js si no tiene la sección `server`
    if ! grep -q "server: {" /var/www/app/vite.config.js; then
        echo "🔧 Añadiendo configuración de servidor en vite.config.js..."
        sed -i '/export default defineConfig({/a \
        server: { \
            host: "0.0.0.0", \
            port: 5173, \
            strictPort: true, \
            hmr: { \
                host: "localhost", \
                port: 5173 \
            }, \
            cors: true \
        },' /var/www/app/vite.config.js
    fi
else
    echo "🔹 Laravel ya está instalado. Omitiendo instalación."
fi

exec "$@"