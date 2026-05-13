#!/bin/bash

set -e

echo "READING SECRETS..."

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_password)

echo "PREPARING WordPress DIRECTORY..."

mkdir -p /var/www/html


until mysql --protocol=TCP --ssl=0 -h"mariadb" -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1
do
	echo "WAITING FOR MariaDB..."
    sleep 2
done

echo "MariaDB IS READY."

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "wp-config.php NOT FOUND. DOWNLOADING WordPress..."

    wp core download \
        --path=/var/www/html \
        --allow-root

    echo "CREATING wp-config.php..."

    wp config create \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="mariadb" \
        --path=/var/www/html \
        --allow-root

    echo "wp-config.php CREATED."
else
    echo "wp-config.php ALREADY EXISTS."
fi

if ! wp core is-installed --path=/var/www/html --allow-root; then
    echo "WordPress IS NOT INSTALLED. INSTALLING..."

    wp core install \
        --url="jrubio-m.42.fr" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --path=/var/www/html \
        --allow-root

    echo "CREATING REGULAR WordPress USER..."

    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --path=/var/www/html \
        --allow-root

    echo "WordPress INSTALLATION COMPLETED."
else
    echo "WordPress IS ALREADY INSTALLED."
fi

echo "SETTING PERMISSIONS..."

chown -R www-data:www-data /var/www/html

echo "STARTING PHP-FPM..."

exec php-fpm8.2 -F


