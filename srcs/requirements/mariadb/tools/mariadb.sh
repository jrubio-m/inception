#!/bin/bash

set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# leer secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
# preparar directorios/permisos
# comprobar si la base ya existe

if [ ! -d "/var/lib/mysql/mysql" ]; then
	echo "INITIALIZING MariaDB..."
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
	mysqld_safe &
	sleep 5
	mysql -u root <<EOF

ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD};
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}'
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

	mysqladmin -u root -p${DB_ROOT_PASSWORD} shutdown
fi

# arrancar mariadb en foreground (primer plano)
exec mysqld