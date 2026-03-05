#!/bin/sh
set -e

ENV_DOCKER="/var/www/.env_docker"
ENV_LARAVEL="/var/www/.env"

# ---------------------------------------------------------------------------
# Leer INSTALL_LARAVEL y LARAVEL_VERSION directamente del fichero montado.
# Más fiable que depender de la interpolación de Docker Compose.
# ---------------------------------------------------------------------------
INSTALL_LARAVEL="false"
LARAVEL_VERSION=""

if [ -f "$ENV_DOCKER" ]; then
    _val=$(grep "^INSTALL_LARAVEL=" "$ENV_DOCKER" 2>/dev/null | cut -d'=' -f2 | sed 's/ *#.*//' | tr -d '"' | tr -d "'")
    [ -n "$_val" ] && INSTALL_LARAVEL="$_val"

    _val=$(grep "^LARAVEL_VERSION=" "$ENV_DOCKER" 2>/dev/null | cut -d'=' -f2- | sed 's/ *#.*//' | tr -d '"' | tr -d "'")
    LARAVEL_VERSION="$_val"
fi

echo "⚙️  INSTALL_LARAVEL=${INSTALL_LARAVEL}"
echo "⚙️  LARAVEL_VERSION=${LARAVEL_VERSION:-latest}"

# ---------------------------------------------------------------------------
# 1. Instalación de Laravel
# Se usa el fichero `artisan` como indicador de que Laravel ya está instalado.
# ---------------------------------------------------------------------------
IS_NEW_INSTALL="false"

if [ "$INSTALL_LARAVEL" = "true" ] && [ ! -f /var/www/artisan ]; then
    echo "🚀 Instalando Laravel en /var/www..."

    mkdir -p /tmp/laravel_temp

    if [ -z "$LARAVEL_VERSION" ]; then
        composer create-project laravel/laravel /tmp/laravel_temp
    else
        composer create-project laravel/laravel="${LARAVEL_VERSION}" /tmp/laravel_temp
    fi

    echo "📂 Moviendo archivos a /var/www..."
    if command -v rsync >/dev/null 2>&1; then
        rsync -a /tmp/laravel_temp/ /var/www/
    else
        cp -a /tmp/laravel_temp/. /var/www/
    fi
    rm -rf /tmp/laravel_temp

    echo "✅ Laravel instalado correctamente."
    IS_NEW_INSTALL="true"
else
    if [ "$INSTALL_LARAVEL" != "true" ]; then
        echo "🔹 INSTALL_LARAVEL=false. Omitiendo instalación."
    else
        echo "🔹 Laravel ya está instalado (artisan encontrado). Omitiendo instalación nueva."
    fi
fi

# ---------------------------------------------------------------------------
# Helper: variables de .env_docker exclusivas de Docker (no se copian al .env)
# ---------------------------------------------------------------------------
SKIP_VARS="UID GID PHP_VERSION NODE_VERSION XDEBUG_PORT INSTALL_LARAVEL LARAVEL_VERSION MYSQL_PORT DB_ROOT_PASSWORD"

is_skip_var() {
    for _s in $SKIP_VARS; do
        [ "$1" = "$_s" ] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------------
# Función: aplica las variables de .env_docker al .env de Laravel.
# Solo se llama UNA VEZ (ver sección 2).
# ---------------------------------------------------------------------------
apply_env_docker() {
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
        esac

        key="${line%%=*}"

        if [ -z "$key" ] || [ "$key" = "$line" ]; then
            continue
        fi

        value="${line#*=}"
        value=$(printf '%s' "$value" | sed 's/ *#.*//')

        case "$value" in
            '"'*'"') value="${value#\"}" ; value="${value%\"}" ;;
            "'"*"'") value="${value#\'}" ; value="${value%\'}" ;;
        esac

        if is_skip_var "$key"; then
            continue
        fi

        # NGINX_PORT → actualizar también APP_URL
        if [ "$key" = "NGINX_PORT" ]; then
            sed -i "s|^#\?\s*APP_URL=.*|APP_URL=http://localhost:${value}|" "$ENV_LARAVEL"
            if grep -q "^NGINX_PORT=" "$ENV_LARAVEL"; then
                sed -i "s|^NGINX_PORT=.*|NGINX_PORT=${value}|" "$ENV_LARAVEL"
            else
                printf '\nNGINX_PORT=%s\n' "$value" >> "$ENV_LARAVEL"
            fi
            continue
        fi

        # APP_NAME: añadir comillas si el valor tiene espacios
        if [ "$key" = "APP_NAME" ]; then
            case "$value" in
                *' '*) value="\"${value}\"" ;;
            esac
        fi

        if grep -q "^#\?\s*${key}=" "$ENV_LARAVEL"; then
            sed -i "s|^#\?\s*${key}=.*|${key}=${value}|" "$ENV_LARAVEL"
        else
            case "$key" in
                DB_*|APP_*|VITE_*|CACHE_*|QUEUE_*|SESSION_*|REDIS_*|MAIL_*)
                    printf '\n%s=%s\n' "$key" "$value" >> "$ENV_LARAVEL" ;;
            esac
        fi
    done < "$ENV_DOCKER"
}

# ---------------------------------------------------------------------------
# 2. Configuración del .env
#
# REGLA FUNDAMENTAL: el .env solo se toca la PRIMERA VEZ.
# Si ya existe, se respeta íntegramente y no se modifica nada.
#
# Casos:
#   A) Instalación nueva (IS_NEW_INSTALL=true): composer ya creó el .env,
#      lo personalizamos con los valores de .env_docker.
#   B) Proyecto clonado sin .env: lo creamos desde .env.example y aplicamos
#      los valores de .env_docker.
#   C) .env ya existe: no se toca bajo ningún concepto.
# ---------------------------------------------------------------------------
ENV_NEEDS_SETUP="false"

if [ "$IS_NEW_INSTALL" = "true" ]; then
    # Caso A: instalación nueva, .env recién creado por composer
    ENV_NEEDS_SETUP="true"
elif [ ! -f "$ENV_LARAVEL" ]; then
    # Caso B: proyecto clonado sin .env
    if [ -f "/var/www/.env.example" ]; then
        echo "📋 .env no encontrado. Creando desde .env.example..."
        cp /var/www/.env.example "$ENV_LARAVEL"
        ENV_NEEDS_SETUP="true"
    else
        echo "⚠️  No existe .env ni .env.example. Crea el .env manualmente antes de continuar."
    fi
else
    # Caso C: .env ya existe → no se modifica
    echo "🔹 .env existente detectado. No se modificará (edítalo directamente si necesitas cambios)."
fi

if [ "$ENV_NEEDS_SETUP" = "true" ] && [ -f "$ENV_LARAVEL" ] && [ -f "$ENV_DOCKER" ]; then
    echo "🔄 Aplicando configuración inicial de .env_docker → .env (solo esta vez)..."
    apply_env_docker

    # Valores fijos de Docker que deben sobreescribir los del .env.example
    sed -i "s|^#\?\s*DB_HOST=.*|DB_HOST=db|" "$ENV_LARAVEL"
    sed -i "s|^#\?\s*DB_PORT=.*|DB_PORT=3306|" "$ENV_LARAVEL"
    sed -i "s|^#\?\s*DB_CONNECTION=.*|DB_CONNECTION=mysql|" "$ENV_LARAVEL"

    echo "✅ .env configurado. A partir de ahora, edita .env directamente."

    # Generar APP_KEY si está vacía (necesario en proyectos clonados)
    if [ -f /var/www/artisan ] && [ -d /var/www/vendor ]; then
        if grep -q "^APP_KEY=$" "$ENV_LARAVEL" 2>/dev/null; then
            echo "🔑 Generando APP_KEY..."
            php artisan key:generate --no-interaction
        fi
    fi
fi

# ---------------------------------------------------------------------------
# 3. Pasos post-instalación (solo en instalaciones nuevas)
# ---------------------------------------------------------------------------
if [ "$IS_NEW_INSTALL" = "true" ]; then
    echo "🔧 Ejecutando pasos post-instalación..."

    # Esperar a que la BD esté disponible antes de migrar
    echo "⏳ Esperando a que la base de datos esté lista..."
    TRIES=0
    until php artisan db:show 2>/dev/null; do
        TRIES=$((TRIES + 1))
        if [ "$TRIES" -ge 15 ]; then
            echo "❌ La BD no respondió tras 15 intentos. Ejecuta 'php artisan migrate --seed' manualmente."
            break
        fi
        echo "   Reintentando en 5s... ($TRIES/15)"
        sleep 5
    done

    if php artisan migrate --seed; then
        echo "✅ Migraciones ejecutadas."
    fi

    # Instalar dependencias Node si no existen
    if [ ! -d "/var/www/node_modules" ]; then
        echo "📦 Instalando dependencias de Node.js..."
        npm install
    fi

    # Configurar vite.config.js para Docker si aún no tiene la configuración de host
    if [ -f "/var/www/vite.config.js" ] && ! grep -q "host: '0.0.0.0'" /var/www/vite.config.js; then
        echo "🔧 Configurando vite.config.js para Docker (HMR)..."

        cat > /var/www/vite.config.js << 'VITEEOF'
import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: true,
        }),
        tailwindcss(),
    ],
    server: {
        host: '0.0.0.0',
        port: parseInt(process.env.VITE_PORT || 5173),
        strictPort: true,
        watch: {
            usePolling: true,
            interval: 1000,
        },
        hmr: {
            host: 'localhost',
            clientPort: parseInt(process.env.VITE_PORT || 5173),
        },
    },
});
VITEEOF

        echo "✅ vite.config.js configurado."
    fi
fi

# ---------------------------------------------------------------------------
# 4. Iniciar Vite en background (solo en entornos no-producción)
#
# El proceso npm run dev queda como hijo de PID 1 (php-fpm tras el exec)
# y muere limpiamente cuando el contenedor se detiene.
# Los logs aparecen en: docker compose logs php
# ---------------------------------------------------------------------------
APP_ENV_VAL=$(grep "^APP_ENV=" "$ENV_LARAVEL" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" | sed 's/ *#.*//')
APP_ENV_VAL="${APP_ENV_VAL:-local}"

if [ "$APP_ENV_VAL" != "production" ] && [ -f "/var/www/package.json" ] && [ -d "/var/www/node_modules" ]; then
    echo "🎨 Iniciando servidor Vite en background (logs en: docker compose logs php)..."
    cd /var/www && npm run dev &
    cd /var/www
fi

exec "$@"
