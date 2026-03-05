# Docker PHP · Nginx · MySQL — Template Laravel

Entorno Docker listo para desarrollo con Laravel. Incluye PHP-FPM, Nginx, MySQL y Node.js con Vite (HMR).

---

## Requisitos previos

- [Docker](https://docs.docker.com/get-docker/) y [Docker Compose](https://docs.docker.com/compose/install/) instalados
- Git

---

## Inicio rápido

### 1. Clonar el repositorio con el nombre de tu proyecto

```bash
git clone https://github.com/homerjavi/docker-php-nginx-mysql.git mi-proyecto
cd mi-proyecto
```

### 2. Configurar el entorno

Edita `.env_docker` con tus valores. Es la única fuente de verdad para la **primera** configuración:

```env
APP_NAME=MiProyecto      # Nombre de la app (también es el nombre del proyecto Docker)

NGINX_PORT=80            # Puerto web en el host
MYSQL_PORT=3306          # Puerto MySQL en el host (cámbialo si hay conflictos)
VITE_PORT=5173           # Puerto del servidor de desarrollo Vite

DB_DATABASE=laravel      # Nombre de la base de datos
DB_USERNAME=user         # Usuario de MySQL
DB_PASSWORD=123456       # Contraseña del usuario
DB_ROOT_PASSWORD=645321  # Contraseña root de MySQL

INSTALL_LARAVEL=true     # true = instala Laravel automáticamente al iniciar
LARAVEL_VERSION=         # Vacío = última versión, o p.ej: 11.*
```

> **IMPORTANTE sobre el `.env`**: Las variables de `.env_docker` se copian al `.env` de Laravel **una sola vez** (en la primera instalación). Después, edita `.env` directamente para cualquier cambio. El `.env_docker` nunca sobrescribirá tu `.env`.

### 3. Levantar los contenedores

```bash
./scripts/up.sh
```

En el primer arranque (con `INSTALL_LARAVEL=true`) se ejecutará automáticamente:
- Instalación de Laravel vía Composer
- Configuración inicial del `.env` desde `.env_docker` (solo esta vez)
- Migración y seed de la base de datos
- Instalación de dependencias NPM
- Configuración de Vite para Docker con soporte HMR y Tailwind CSS
- Arranque del servidor Vite en background

---

## Scripts disponibles

Todos los scripts deben ejecutarse desde la **raíz del proyecto** (aunque funcionan desde cualquier directorio).

| Script | Descripción |
|---|---|
| `./scripts/up.sh` | Construye e inicia los contenedores |
| `./scripts/down.sh` | Para y elimina los contenedores |
| `./scripts/bash.sh` | Abre una terminal bash en el contenedor PHP |
| `./scripts/artisan.sh <cmd>` | Ejecuta un comando Artisan en el contenedor |
| `./scripts/reset-db.sh` | Borra todos los datos de MySQL (pide confirmación) |

### Ejemplos de uso

```bash
./scripts/artisan.sh migrate
./scripts/artisan.sh migrate --seed
./scripts/artisan.sh make:controller UserController
./scripts/bash.sh
```

---

## Vite (HMR)

Vite arranca automáticamente en background cuando se inicia el contenedor PHP (solo en `APP_ENV=local`). Los logs aparecen mezclados con los de PHP:

```bash
docker compose logs -f php
```

El `vite.config.js` se configura automáticamente en la primera instalación para funcionar con Docker:

```js
server: {
    host: '0.0.0.0',
    port: parseInt(process.env.VITE_PORT || 5173),
    hmr: { host: 'localhost', clientPort: ... },
}
```

Si necesitas reconfigurarlo manualmente en un proyecto clonado, copia esa configuración en tu `vite.config.js`.

---

## Servicios y puertos

| Servicio | URL / Puerto (por defecto) |
|---|---|
| Web (Nginx) | http://localhost:80 |
| Vite (HMR) | http://localhost:5173 |
| MySQL (externo) | localhost:3306 |

Los puertos se configuran en `.env_docker`. Si tienes conflictos con otros proyectos, cambia `NGINX_PORT`, `MYSQL_PORT` o `VITE_PORT`.

---

## Producción (Cloudflare Tunnel)

Este template usa Nginx en HTTP plano. El HTTPS lo gestiona Cloudflare Tunnel en la capa exterior, sin necesidad de certificados en el servidor.

Al pasar a producción, edita directamente el `.env` del proyecto (no `.env_docker`):

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://tu-dominio.com   # Con https, tal como llega desde Cloudflare
```

> Vite no arranca en producción (el entrypoint detecta `APP_ENV=production`). Compila los assets con `npm run build` antes de desplegar.

---

## Versiones configurables

En `.env_docker`:

```env
PHP_VERSION=8.3     # Cualquier versión disponible en php:X.X-fpm
NODE_VERSION=lts    # lts, 20, 22, etc.
```

> Cambiar versiones requiere reconstruir la imagen: `./scripts/up.sh` ya lo hace con `--build`.

---

## Conexión a la base de datos desde herramientas externas

| Campo | Valor |
|---|---|
| Host | `127.0.0.1` |
| Puerto | Valor de `MYSQL_PORT` en `.env_docker` |
| Base de datos | Valor de `DB_DATABASE` |
| Usuario | Valor de `DB_USERNAME` |
| Contraseña | Valor de `DB_PASSWORD` |

---

## Empezar un nuevo proyecto desde cero

```bash
# 1. Bajar los contenedores
./scripts/down.sh

# 2. Borrar datos de MySQL (pide confirmación)
./scripts/reset-db.sh

# 3. Editar .env_docker con los nuevos valores

# 4. Levantar de nuevo (instalará Laravel desde cero)
./scripts/up.sh
```

---

## Opciones avanzadas (comentadas en docker-compose.yml)

- **phpMyAdmin** — Gestor web de MySQL
- **Adminer** — Alternativa ligera a phpMyAdmin
- **Mailpit** — Captura de correos en desarrollo
- **Redis** — Caché y colas
- **MariaDB** — Alternativa a MySQL
- **PostgreSQL + pgAdmin** — Soporte para Postgres

---

## Comandos Docker útiles

```bash
# Estado de los contenedores
docker compose ps

# Logs (php incluye logs de Vite en desarrollo)
docker compose logs -f php
docker compose logs nginx
docker compose logs db

# Reconstruir solo la imagen PHP
docker compose build php

# Acceder como root al contenedor PHP
docker compose exec --user root php bash
```
