#!/bin/bash

# 1. Esperar un momento a que la base de datos arranque (parche simple)
echo "Esperando a que la base de datos inicie..."
sleep 10

# 2. Definir rutas
MOODLE_PATH="/var/www/html"
DATA_PATH="/var/www/moodledata"

# 3. Verificar si Moodle ya está instalado
if [ -f "$MOODLE_PATH/config.php" ]; then
    echo "Moodle ya está instalado. Saltando instalación."
else
    echo "Config.php no encontrado. Iniciando instalación automática de Moodle..."

    # Ajustar permisos antes de instalar
    chown -R www-data:www-data $MOODLE_PATH
    chown -R www-data:www-data $DATA_PATH
    chmod -R 777 $DATA_PATH

    # Ejecutar instalador usando variables de entorno
    # Usamos 'runuser' para ejecutarlo como el usuario del servidor web
    runuser -u www-data -- php $MOODLE_PATH/admin/cli/install.php \
        --lang=es \
        --wwwroot=$MOODLE_URL \
        --dataroot=$DATA_PATH \
        --dbtype=mariadb \
        --dbhost=$MOODLE_DB_HOST \
        --dbname=$MOODLE_DB_NAME \
        --dbuser=$MOODLE_DB_USER \
        --dbpass=$MOODLE_DB_PASSWORD \
        --fullname="$MOODLE_SITE_FULLNAME" \
        --shortname="$MOODLE_SITE_SHORTNAME" \
        --adminuser=$MOODLE_ADMIN_USER \
        --adminpass=$MOODLE_ADMIN_PASSWORD \
        --adminemail=$MOODLE_ADMIN_EMAIL \
        --agree-license \
        --non-interactive

    echo "Instalación completada."
fi

# 4. Asegurar permisos finales
chown -R www-data:www-data $MOODLE_PATH

# 5. Arrancar Apache (el comando por defecto de la imagen PHP)
exec apache2-foreground