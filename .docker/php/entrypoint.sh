#!/bin/sh
set -e

ENV_DOCKER="/var/www/.env_docker"
ENV_LARAVEL="/var/www/.env"

# ---------------------------------------------------------------------------
# Read INSTALL_LARAVEL and LARAVEL_VERSION directly from the mounted
# .env_docker file. This is more reliable than depending on Docker Compose
# env var interpolation, which can have issues with inline comments or
# quoted empty values (e.g. LARAVEL_VERSION="").
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
# Se usa el fichero `artisan` como indicador de que Laravel ya está instalado,
# ya que es específico de Laravel y siempre está presente tras la instalación.
# ---------------------------------------------------------------------------
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
    IS_NEW_INSTALL="false"
fi

# ---------------------------------------------------------------------------
# Helper: decide si una variable del .env_docker es exclusiva de Docker
# y no debe copiarse al .env de Laravel.
# ---------------------------------------------------------------------------
SKIP_VARS="UID GID PHP_VERSION NODE_VERSION XDEBUG_PORT INSTALL_LARAVEL LARAVEL_VERSION MYSQL_PORT DB_ROOT_PASSWORD"

is_skip_var() {
    for _s in $SKIP_VARS; do
        [ "$1" = "$_s" ] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------------
# 2. Sincronizar variables desde .env_docker al .env de Laravel.
# Se lee directamente el fichero montado para que .env_docker sea la única
# fuente de verdad: puertos, credenciales de BD, nombre de la app, etc.
# ---------------------------------------------------------------------------
if [ -f "$ENV_LARAVEL" ] && [ -f "$ENV_DOCKER" ]; then
    echo "🔄 Sincronizando variables desde .env_docker..."

    while IFS= read -r line || [ -n "$line" ]; do
        # Ignorar líneas vacías y comentarios
        case "$line" in
            ''|'#'*) continue ;;
        esac

        # Extraer clave (todo antes del primer '=')
        key="${line%%=*}"

        # Ignorar líneas sin '=' o con clave vacía
        if [ -z "$key" ] || [ "$key" = "$line" ]; then
            continue
        fi

        # Extraer valor (todo después del primer '=')
        value="${line#*=}"

        # Eliminar comentarios inline del valor
        value=$(printf '%s' "$value" | sed 's/ *#.*//')

        # Eliminar comillas envolventes del valor
        case "$value" in
            '"'*'"') value="${value#\"}" ; value="${value%\"}" ;;
            "'"*"'") value="${value#\'}" ; value="${value%\'}" ;;
        esac

        # Saltarse variables exclusivas de Docker
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

        # Actualizar si la clave ya existe en el .env (comentada o no),
        # o añadir al final si es una variable conocida de Laravel.
        if grep -q "^#\?\s*${key}=" "$ENV_LARAVEL"; then
            sed -i "s|^#\?\s*${key}=.*|${key}=${value}|" "$ENV_LARAVEL"
        else
            case "$key" in
                DB_*|APP_*|VITE_*|CACHE_*|QUEUE_*|SESSION_*|REDIS_*|MAIL_*)
                    printf '\n%s=%s\n' "$key" "$value" >> "$ENV_LARAVEL" ;;
            esac
        fi
    done < "$ENV_DOCKER"

    echo "✅ Variables de entorno sincronizadas."
fi

# ---------------------------------------------------------------------------
# 3. Pasos post-instalación (solo en instalaciones nuevas)
# ---------------------------------------------------------------------------
if [ "$IS_NEW_INSTALL" = "true" ]; then
    echo "🔧 Ejecutando pasos post-instalación..."

    php artisan migrate --seed

    if [ ! -d "/var/www/node_modules" ]; then
        echo "📦 Instalando dependencias de Node.js..."
        npm install
    fi

    if [ -f "/var/www/vite.config.js" ] && ! grep -q "server: {" /var/www/vite.config.js; then
        echo "🔧 Configurando vite.config.js para Docker..."
        VITE_PORT_VAL=$(grep "^VITE_PORT=" "$ENV_DOCKER" 2>/dev/null | cut -d'=' -f2 | sed 's/ *#.*//' | tr -d '"' | tr -d "'")
        VITE_PORT_VAL="${VITE_PORT_VAL:-5173}"
        sed -i "/export default defineConfig({/a \    server: {\n        host: '0.0.0.0',\n        port: 5173,\n        hmr: {\n            host: 'localhost',\n            clientPort: ${VITE_PORT_VAL}\n        }\n    }," /var/www/vite.config.js
    fi
fi

exec "$@"
