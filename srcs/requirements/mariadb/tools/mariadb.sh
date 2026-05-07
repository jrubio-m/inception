#!/bin/bash

set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

echo "READING SECRETS..."

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "INITIALIZING MariaDB..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "STARTING TEMP MariaDB..."
    mysqld_safe --skip-networking --socket=/run/mysqld/mysqld.sock &

    until mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent
    do
        echo "WAITING FOR TEMP MariaDB..."
        sleep 2
    done

    echo "CREATING DATABASE AND USERS..."

    mysql -u root --socket=/run/mysqld/mysqld.sock <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "SHUTTING DOWN TEMP MariaDB..."
    mysqladmin -u root -p"${DB_ROOT_PASSWORD}" --socket=/run/mysqld/mysqld.sock shutdown

    echo "MariaDB INITIALIZATION FINISHED."
fi

echo "STARTING MariaDB..."
exec mysqld