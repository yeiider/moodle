# Usamos PHP 8.2 con Apache (versión recomendada para Moodle actual)
FROM php:8.2-apache

# 1. Instalar dependencias del sistema necesarias para las extensiones de PHP
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libonig-dev \
    libxslt1-dev \
    acl \
    && rm -rf /var/lib/apt/lists/*

# 2. Configurar y compilar extensiones de PHP requeridas por Moodle
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

# 3. Instalar Composer (copiándolo desde la imagen oficial)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Aumentar límites de PHP (Moodle necesita memoria y tiempo)
RUN echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/moodle-reqs.ini \
    && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/moodle-reqs.ini \
    && echo "upload_max_filesize = 100M" >> /usr/local/etc/php/conf.d/moodle-reqs.ini \
    && echo "post_max_size = 100M" >> /usr/local/etc/php/conf.d/moodle-reqs.ini

# 5. Habilitar mod_rewrite de Apache (necesario para URLs amigables)
RUN a2enmod rewrite

# 6. Copiar el código del repositorio actual al contenedor
COPY . /var/www/html/

# 7. Ejecutar Composer Install (Si tienes un composer.json en tu repo)
# Si tu fork es del core de Moodle, generalmente ya trae las dependencias en /lib
# Pero si usas composer para plugins, descomenta la siguiente línea:
# RUN composer install --no-dev --optimize-autoloader

# 8. Ajustar permisos para Apache
RUN chown -R www-data:www-data /var/www/html