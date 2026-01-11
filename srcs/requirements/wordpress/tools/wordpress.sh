
#!/bin/bash
set -e

mkdir -p "$WP_DIR"

# Download/config only once (volume safe)
if [ ! -f "$WP_DIR/wp-config.php" ]; then
  wget -qO /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
  tar -xzf /tmp/wordpress.tar.gz -C /tmp/
  cp -r /tmp/wordpress/* "$WP_DIR"
  chown -R www-data:www-data "$WP_DIR"

  cp "$WP_DIR/wp-config-sample.php" "$WP_DIR/wp-config.php"
  sed -i "s/database_name_here/${DB_NAME}/" "$WP_DIR/wp-config.php"
  sed -i "s/username_here/${DB_USER}/" "$WP_DIR/wp-config.php"
  sed -i "s/password_here/${DB_PASSWORD}/" "$WP_DIR/wp-config.php"
  sed -i "s/192.168.0.3/${DB_HOST}/" "$WP_DIR/wp-config.php"
fi

# Install only once
if ! wp --path="$WP_DIR" core is-installed --allow-root; then
  wp --path="$WP_DIR" core install \
    --url="http://localhost" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root
fi

rm -rf /tmp/wordpress.tar.gz /tmp/wordpress

echo "WordPress ready!"

exec $@
