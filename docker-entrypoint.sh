#!/bin/bash

echo "--- Iniciando Moodle Container (Script Corregido) ---"

# 1. Limpieza preventiva de Apache (Evita el error Address already in use)
rm -f /var/run/apache2/apache2.pid

echo "Esperando a que la base de datos inicie..."
sleep 10

# 2. Definir rutas
MOODLE_PATH="/var/www/html"
DATA_PATH="/var/www/moodledata"

# 3. Generar SIEMPRE el config.php con la configuración SSL correcta
# Esto soluciona el problema de que el archivo se borre al reiniciar
# y además inyecta la configuración para Nginx Proxy Manager.
echo "Generando archivo config.php..."

cat <<EOF > $MOODLE_PATH/config.php
<?php
unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

\$CFG->dbtype    = 'mariadb';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${MOODLE_DB_HOST}';
\$CFG->dbname    = '${MOODLE_DB_NAME}';
\$CFG->dbuser    = '${MOODLE_DB_USER}';
\$CFG->dbpass    = '${MOODLE_DB_PASSWORD}';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '',
  'dbsocket' => '',
);

\$CFG->wwwroot   = '${MOODLE_URL}';
\$CFG->dataroot  = '${DATA_PATH}';
\$CFG->admin     = 'admin';

// --- CONFIGURACIÓN CRÍTICA PARA NGINX PROXY MANAGER ---
\$CFG->sslproxy  = true;
// Esto evita el bucle de redirecciones ERR_TOO_MANY_REDIRECTS
// -----------------------------------------------------

\$CFG->directorypermissions = 0777;

require_once(__DIR__ . '/lib/setup.php');
EOF

# 4. Ajustar permisos
echo "Ajustando permisos..."
chown -R www-data:www-data $MOODLE_PATH
chown -R www-data:www-data $DATA_PATH
chmod -R 777 $DATA_PATH

# 5. Instalación Inteligente de la Base de Datos
# Como ya creamos el config.php manualmente, NO usamos 'install.php'.
# Usamos 'install_database.php' si la base de datos está vacía.

echo "Verificando estado de la instalación..."

# Intentamos un upgrade en modo 'check' para ver si Moodle ya está instalado en la DB
if runuser -u www-data -- php $MOODLE_PATH/admin/cli/upgrade.php --non-interactive --allow-unstable > /dev/null 2>&1; then
    echo "Moodle y base de datos ya instalados. Saltando instalación."
else
    echo "Base de datos incompleta. Ejecutando instalación de tablas..."

    runuser -u www-data -- php $MOODLE_PATH/admin/cli/install_database.php \
        --lang=es \
        --adminuser=$MOODLE_ADMIN_USER \
        --adminpass=$MOODLE_ADMIN_PASSWORD \
        --adminemail=$MOODLE_ADMIN_EMAIL \
        --fullname="$MOODLE_SITE_FULLNAME" \
        --shortname="$MOODLE_SITE_SHORTNAME" \
        --agree-license \
        --allow-unstable
fi

# 6. Arrancar Apache
echo "Iniciando servidor web Apache..."
exec apache2-foreground