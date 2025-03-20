1. Clonar proyecto con el nombre que queramos
git clone https://github.com/homerjavi/docker-php-nginx-mysql.git proyecto-nuevo (nombre que quieras darle a tu proyecto)

2. Accder a la carpeta proyecto-nuevo (o el nombre que le hayas dado)

CREO QUE CON docker compose up -d la primera vez hace el build
3. Construir contenedores (build) 
docker compose build

4. ?Levantar los contenedores:
docker compose up -d

5. Asegurarse que esten levantados
docker compose ps

6. Acceder al contenedor php
docker compose exec php bash








*** EXTRA ***
php artisan serve --host=0.0.0.0 --port=8000 (si no no podrás acceder desde el host con php artisan serve)