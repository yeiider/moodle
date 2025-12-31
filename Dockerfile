# CAMBIO IMPORTANTE: Usamos PHP 8.3 para que sea compatible con el Moodle actual
FROM php:8.3-apache

# ... (Tus instalaciones de librerías y extensiones siguen igual aquí) ...
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libicu-dev libpng-dev libjpeg-dev \
    libfreetype6-dev libxml2-dev libonig-dev libxslt1-dev acl \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd intl soap zip mysqli opcache exif xsl

RUN echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/moodle-reqs.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/moodle-reqs.ini

RUN a2enmod rewrite

COPY . /var/www/html/

# --- NUEVO: CONFIGURACIÓN DEL ENTRYPOINT ---
# Copiamos el script
COPY docker-entrypoint.sh /usr/local/bin/

# Le damos permisos de ejecución
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Establecemos el script como el punto de entrada
ENTRYPOINT ["docker-entrypoint.sh"]