#!/bin/bash

# 1. Limpieza preventiva de Apache (SOLUCIÓN AL ERROR 98)
# Borramos el archivo de proceso (PID) por si quedó de un cierre anterior
rm -f /var/run/apache2/apache2.pid

echo "Esperando a que la base de datos inicie..."
sleep 10

# 2. Definir rutas
MOODLE_PATH="/var/www/html"
DATA_PATH="/var/www/moodledata"

# 3. Lógica de instalación
if [ -f "$MOODLE_PATH/config.php" ]; then
    echo "Moodle ya está instalado. Iniciando Apache..."
else
    echo "Config.php no encontrado. Iniciando instalación automática..."

    # Ajustar permisos
    chown -R www-data:www-data $MOODLE_PATH
    chown -R www-data:www-data $DATA_PATH
    chmod -R 777 $DATA_PATH

    # Ejecutar instalador
    # AGREGADO: --allow-unstable para que no se queje de tu versión 5.2dev
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
        --allow-unstable \
        --non-interactive

    echo "Instalación completada."
fi

# 4. Asegurar permisos finales y arrancar
chown -R www-data:www-data $MOODLE_PATH
echo "Iniciando servidor web Apache..."

# Usamos exec para que Apache tome el control PID 1
exec apache2-foreground