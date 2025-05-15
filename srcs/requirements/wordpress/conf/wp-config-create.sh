#!/bin/sh
if [ ! -f "/var/www/wp-config.php" ]; then
cat << EOF > /var/www/wp-config.php
<?php
define( 'DB_NAME', '${DB_NAME}' );
define( 'DB_USER', '${DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASS}' );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
define('FS_METHOD','direct');
\$table_prefix = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
define( 'ABSPATH', __DIR__ . '/' );}
define( 'WP_REDIS_HOST', 'redis' );
define( 'WP_REDIS_PORT', 6379 );
define( 'WP_REDIS_TIMEOUT', 1 );
define( 'WP_REDIS_READ_TIMEOUT', 1 );
define( 'WP_REDIS_DATABASE', 0 );
require_once ABSPATH . 'wp-settings.php';
EOF
fi

# Wait until MariaDB is ready
until mysqladmin ping -h"mariadb" -u"$DB_USER" -p"$DB_PASS" --silent; do
    echo "MariaDB not ready yet..."
    sleep 1
done
echo "MariaDB is available!"

# Check if WordPress is already installed
if ! wp core is-installed --allow-root --path=/var/www; then
    wp core install \
        --url=https://vbarsegh.42.fr \
        --title="Inception WP" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASS} \
        --admin_email=admin@vbarsegh.42.fr \
        --skip-email \
        --path=/var/www \
        --allow-root

	# Create additional WordPress user
	wp user create ${WP_USER} mywpuser@gmail.com \
    		--user_pass=${WP_USER_PASS} \
    		--role=author \
    		--path=/var/www \
    		--allow-root


fi

exec /usr/sbin/php-fpm82 -F
