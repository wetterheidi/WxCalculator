#!/bin/bash
set -euo pipefail

APP_NAME="wxcalculator"
APP_DIR="/apps/${APP_NAME}"
REPO_URL="https://github.com/wetterheidi/WxCalculator.git"
SUBDOMAIN="wxcalculator.wetterheidi.de"
NGINX_CONF_SRC="$(dirname "$0")/nginx-wxcalculator.conf"
NGINX_CONF_DEST="/etc/nginx/sites-available/wxcalculator.conf"
NGINX_CONF_LINK="/etc/nginx/sites-enabled/wxcalculator.conf"

echo "==> Deploying ${APP_NAME} to ${APP_DIR}"

# Clone or pull repo
if [ -d "${APP_DIR}/.git" ]; then
    echo "==> Pulling latest changes..."
    git -C "${APP_DIR}" pull
else
    echo "==> Cloning repository..."
    git clone "${REPO_URL}" "${APP_DIR}"
fi

# Set permissions
echo "==> Setting permissions..."
chown -R www-data:www-data "${APP_DIR}"
chmod -R 755 "${APP_DIR}"

# Install nginx config
echo "==> Installing nginx config..."
cp "${NGINX_CONF_SRC}" "${NGINX_CONF_DEST}"

if [ ! -L "${NGINX_CONF_LINK}" ]; then
    ln -s "${NGINX_CONF_DEST}" "${NGINX_CONF_LINK}"
fi

# Test and reload nginx BEFORE certbot (required for ACME challenge)
echo "==> Testing nginx config..."
nginx -t

echo "==> Reloading nginx (before certbot)..."
systemctl reload nginx

# Run certbot
echo "==> Running certbot..."
certbot --nginx -d "${SUBDOMAIN}" --non-interactive --agree-tos --redirect

# Reload nginx again after certbot modified the config
echo "==> Reloading nginx (after certbot)..."
systemctl reload nginx

echo "==> Done. App available at https://${SUBDOMAIN}"
