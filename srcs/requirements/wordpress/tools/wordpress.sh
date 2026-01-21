#!/bin/bash
set -e
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)

mkdir -p "$WP_DIR"

if [ ! -f "$WP_DIR/wp-config.php" ]; then
  wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp/
  cp -r /tmp/wordpress/* "$WP_DIR"
  chown -R www-data:www-data "$WP_DIR"

  cp "$WP_DIR/wp-config-sample.php" "$WP_DIR/wp-config.php"
  sed -i "s/database_name_here/${DB_NAME}/" "$WP_DIR/wp-config.php"
  sed -i "s/username_here/${DB_USER}/" "$WP_DIR/wp-config.php"
  sed -i "s/password_here/${DB_PASSWORD}/" "$WP_DIR/wp-config.php"
  sed -i "s/localhost/${DB_HOST}/" "$WP_DIR/wp-config.php"
fi

if ! wp --path="$WP_DIR" core is-installed --allow-root; then
  wp --path="$WP_DIR" core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root
    
    rm -rf /tmp/wordpress.tar.gz /tmp/wordpress
fi
    sed -i "s|listen = /run/php/php8.2-fpm.sock|listen = 9000|" "/etc/php/8.2/fpm/pool.d/www.conf" 

exec php-fpm8.2 -F
