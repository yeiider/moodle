# Usamos PHP 8.3 (Requerido para Moodle 5 Dev)
FROM php:8.3-apache

# 1. Instalación de librerías del sistema
# CORRECCIÓN: Usamos 'libjpeg62-turbo-dev' para compatibilidad con Debian 12/PHP 8.3
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libxml2-dev \
    libonig-dev \
    libxslt1-dev \
    acl \
    && rm -rf /var/lib/apt/lists/*

# 2. Configuración de extensiones PHP
# Configurar GD con soporte para imágenes
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    intl \
    soap \
    zip \
    mysqli \
    opcache \
    exif \
    xsl

# 3. Configuración de límites de PHP para Moodle
RUN echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/moodle-reqs.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/moodle-reqs.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/moodle-reqs.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/moodle-reqs.ini

# 4. Habilitar mod_rewrite de Apache
RUN a2enmod rewrite

# 5. CORRECCIÓN APACHE PARA MOODLE 5 (Carpeta /public)
# Define la variable de entorno
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

# Usamos comillas dobles " en sed para asegurar que la variable se expanda correctamente al construir
RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/sites-available/*.conf
RUN sed -ri -e "s!/var/www/html!${APACHE_DOCUMENT_ROOT}!g" /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 6. Copiar el código fuente
COPY . /var/www/html/

# 7. Configurar el Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]