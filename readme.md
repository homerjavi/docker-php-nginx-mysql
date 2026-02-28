# Docker PHP · Nginx · MySQL — Template Laravel

Entorno Docker listo para desarrollo con Laravel. Incluye PHP-FPM, Nginx, MySQL y Node.js.

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

Edita el fichero `.env_docker` con tus valores. Es la **única fuente de verdad** para toda la configuración:

```env
APP_NAME=MiProyecto      # Nombre de la aplicación Laravel

NGINX_PORT=80            # Puerto web en el host
MYSQL_PORT=3306          # Puerto MySQL en el host (cámbialo si hay conflictos)
VITE_PORT=5173           # Puerto del servidor de desarrollo Vite

DB_DATABASE=laravel      # Nombre de la base de datos
DB_USERNAME=user         # Usuario de MySQL
DB_PASSWORD=123456       # Contraseña del usuario
DB_ROOT_PASSWORD=645321  # Contraseña root de MySQL

INSTALL_LARAVEL=true     # true = instala Laravel automáticamente al iniciar
LARAVEL_VERSION=         # Dejar vacío para la última versión, o p.ej: 11.*
```

> El fichero `.env` de Laravel se genera y sincroniza automáticamente desde `.env_docker`
> al arrancar los contenedores. No es necesario editarlo a mano.

### 3. Levantar los contenedores

```bash
./scripts/up.sh
```

En el primer arranque (con `INSTALL_LARAVEL=true` y sin Laravel instalado) se ejecutará:
- Instalación de Laravel vía Composer
- Sincronización de variables al `.env` de Laravel
- Migración y seed de la base de datos (`php artisan migrate --seed`)
- Instalación de dependencias NPM
- Configuración de Vite para Docker (HMR)

---

## Scripts disponibles

Todos los scripts deben ejecutarse desde la **raíz del proyecto**.

| Script | Descripción |
|---|---|
| `./scripts/up.sh` | Construye e inicia los contenedores |
| `./scripts/down.sh` | Para y elimina los contenedores |
| `./scripts/bash.sh` | Abre una terminal bash en el contenedor PHP |
| `./scripts/artisan.sh <comando>` | Ejecuta un comando Artisan en el contenedor |
| `./scripts/reset-db.sh` | Borra todos los datos de MySQL (pide confirmación) |

### Ejemplos de uso

```bash
# Ejecutar migraciones
./scripts/artisan.sh migrate

# Ejecutar migraciones con seed
./scripts/artisan.sh migrate --seed

# Crear un controlador
./scripts/artisan.sh make:controller UserController

# Acceder a la terminal del contenedor PHP
./scripts/bash.sh
```

---

## Servicios y puertos

| Servicio | URL / Puerto (por defecto) |
|---|---|
| Web (Nginx) | http://localhost:80 |
| PHP artisan serve | http://localhost:8000 |
| Vite (HMR) | http://localhost:5173 |
| MySQL (externo) | localhost:3306 |

Los puertos se configuran en `.env_docker`. Si tienes conflictos con otros proyectos,
cambia `NGINX_PORT`, `MYSQL_PORT` o `VITE_PORT`.

---

## Versiones configurables

En `.env_docker` puedes ajustar:

```env
PHP_VERSION=8.3     # Versión de PHP (cualquier versión disponible en php:X.X-fpm)
NODE_VERSION=lts    # Versión de Node.js (lts, 20, 22, etc.)
```

> Cambiar estas versiones requiere reconstruir la imagen: `./scripts/up.sh` ya lo hace con `--build`.

---

## Conexión a la base de datos desde herramientas externas

Usa los siguientes datos en DBeaver, TablePlus, etc.:

| Campo | Valor |
|---|---|
| Host | `127.0.0.1` |
| Puerto | El valor de `MYSQL_PORT` en `.env_docker` |
| Base de datos | El valor de `DB_DATABASE` |
| Usuario | El valor de `DB_USERNAME` |
| Contraseña | El valor de `DB_PASSWORD` |

---

## Empezar un nuevo proyecto desde cero

Si quieres reutilizar el template para un proyecto nuevo:

```bash
# 1. Bajar los contenedores
./scripts/down.sh

# 2. Eliminar los ficheros de Laravel generados (composer.json, artisan, app/, etc.)
#    y los datos de MySQL
./scripts/reset-db.sh

# 3. Configurar .env_docker con los nuevos valores

# 4. Levantar de nuevo (instalará Laravel desde cero)
./scripts/up.sh
```

---

## Opciones avanzadas (comentadas en docker-compose.yml)

El `docker-compose.yml` incluye configuraciones listas para activar descomentando:

- **phpMyAdmin** — Gestor web de MySQL
- **Adminer** — Alternativa ligera a phpMyAdmin
- **Mailpit** — Captura de correos en desarrollo
- **Redis** — Caché y colas
- **MariaDB** — Alternativa a MySQL
- **PostgreSQL + pgAdmin** — Soporte para Postgres

---

## Comandos Docker útiles

```bash
# Ver el estado de los contenedores
docker compose ps

# Ver los logs de un servicio
docker compose logs php
docker compose logs nginx
docker compose logs db

# Reconstruir solo la imagen PHP (tras cambiar Dockerfile o .env_docker)
docker compose build php

# Acceder al contenedor PHP como root (para operaciones de sistema)
docker exec -it -u root <nombre-contenedor-php> bash
```
