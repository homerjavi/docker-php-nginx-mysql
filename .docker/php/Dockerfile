ARG PHP_VERSION=latest
FROM php:${PHP_VERSION}-fpm

COPY php.ini /usr/local/etc/php/
COPY docker.conf /usr/local/etc/php-fpm.d/docker.conf
COPY .bashrc /root/

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# mix
RUN apt-get update \
  && apt-get install -y build-essential zlib1g-dev default-mysql-client curl gnupg procps vim git unzip libzip-dev libpq-dev rsync \
  && docker-php-ext-install zip pdo_mysql pdo_pgsql pgsql

# intl
RUN apt-get install -y libicu-dev \
  && docker-php-ext-configure intl \
  && docker-php-ext-install intl

# gd
RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev && \
docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ && \
docker-php-ext-install gd

# redis
RUN pecl install redis && docker-php-ext-enable redis

# pcov
RUN pecl install pcov && docker-php-ext-enable pcov

# Xdebug
# RUN pecl install xdebug \
# && docker-php-ext-enable xdebug \
# && echo ";zend_extension=xdebug" > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Node.js, NPM, Yarn
# RUN curl -sL https://deb.nodesource.com/setup_22.x | bash -
# RUN apt-get install -y nodejs
# RUN npm install npm@latest -g
# RUN npm install yarn -g

# Instalación de Node.js según versión especificada (o LTS por defecto)
ARG NODE_VERSION=lts
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs

# Actualización npm
RUN npm install -g npm

# Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer
ENV PATH $PATH:/composer/vendor/bin
RUN composer config --global process-timeout 3600
# RUN composer global require "laravel/installer"

# Comentar las líneas user y group en www.conf para evitar avisos en PHP-FPM
RUN sed -i 's/^user = .*/user = laravel/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = .*/group = laravel/' /usr/local/etc/php-fpm.d/www.conf


WORKDIR /root
RUN git clone https://github.com/seebi/dircolors-solarized

# Argumentos para definir UID y GID dinámicamente
ARG UID=1000
ARG GID=1000

# Crear el grupo y usuario con el mismo UID/GID que en el host
RUN groupadd -g $GID laravel && useradd -u $UID -g $GID -m laravel

RUN mkdir -p /var/www
# Dar permisos al usuario en los directorios de Laravel
RUN chown -R laravel:laravel /var/www
RUN chown -R laravel:laravel /composer
RUN chmod -R 755 /composer


# Cambiar al usuario creado
USER laravel

EXPOSE 5173
WORKDIR /var/www

#entrypoint
ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]