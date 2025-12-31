# Usamos PHP 8.3 (Requerido para Moodle Dev)
FROM php:8.3-apache

# Instalación de librerías
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libicu-dev libpng-dev libjpeg-dev \
    libfreetype6-dev libxml2-dev libonig-dev libxslt1-dev acl \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd intl soap zip mysqli opcache exif xsl

RUN echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/moodle-reqs.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/moodle-reqs.ini

RUN a2enmod rewrite

# --- CORRECCIÓN APACHE PARA MOODLE 5 (NUEVA ESTRUCTURA) ---
# Cambiamos la carpeta pública de /html a /html/public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
# ---------------------------------------------------------

COPY . /var/www/html/

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]