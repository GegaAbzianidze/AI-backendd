#!/bin/bash
# Quick fix script for nginx configuration after certbot

set -euo pipefail

APP_NAME="ai-backend"
APP_DIR="/opt/ai-backend"
BACKEND_PORT="3000"
DOMAIN="shuaman.publicvm.com"

echo "Fixing nginx configuration..."

# Remove any duplicate configs first
echo "Checking for duplicate configurations..."
if [ -f "/etc/nginx/sites-enabled/${APP_NAME}" ]; then
    # Count how many times the domain appears
    DUPLICATE_COUNT=$(grep -c "server_name ${DOMAIN}" /etc/nginx/sites-enabled/* 2>/dev/null || echo "0")
    if [ "$DUPLICATE_COUNT" -gt "1" ]; then
        echo "⚠ Found duplicate server blocks. Cleaning up..."
        # Backup all configs
        mkdir -p /etc/nginx/sites-enabled/backups
        cp /etc/nginx/sites-enabled/${APP_NAME}* /etc/nginx/sites-enabled/backups/ 2>/dev/null || true
    fi
fi

# Backup current config
cp /etc/nginx/sites-enabled/${APP_NAME} /etc/nginx/sites-enabled/${APP_NAME}.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create proper config with both HTTP redirect and HTTPS proxy
cat > "/etc/nginx/sites-available/${APP_NAME}" <<EOF
# HTTP server - redirect to HTTPS
server {
    listen 80;
    server_name ${DOMAIN} _;
    
    # Redirect all HTTP to HTTPS
    return 301 https://\$host\$request_uri;
}

# HTTPS server - proxy to backend
server {
    listen 443 ssl http2;
    server_name ${DOMAIN} _;

    # SSL configuration (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 500M;
    
    access_log /var/log/nginx/${APP_NAME}-access.log;
    error_log /var/log/nginx/${APP_NAME}-error.log;

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    send_timeout 300s;

    location /api/ {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass \$http_upgrade;
    }

    location /frames/ {
        alias ${APP_DIR}/frames/;
        expires 1h;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Ensure symlink exists and remove any other configs with same domain
ln -sf "/etc/nginx/sites-available/${APP_NAME}" "/etc/nginx/sites-enabled/${APP_NAME}"

# Remove any other files that might have duplicate server blocks
# (certbot sometimes creates separate files)
find /etc/nginx/sites-enabled/ -name "*${APP_NAME}*" ! -name "${APP_NAME}" ! -name "*.backup.*" -type f -delete 2>/dev/null || true

# Test configuration
echo "Testing nginx configuration..."
if nginx -t; then
    echo "✓ Configuration is valid"
    systemctl reload nginx
    echo "✓ Nginx reloaded"
    echo ""
    echo "Test your site:"
    echo "  HTTPS: https://${DOMAIN}"
    echo "  HTTP:  http://${DOMAIN} (should redirect to HTTPS)"
else
    echo "✗ Configuration test failed!"
    echo "Restoring backup..."
    # Restore from most recent backup
    BACKUP=$(ls -t /etc/nginx/sites-enabled/${APP_NAME}.backup.* 2>/dev/null | head -1)
    if [ -n "$BACKUP" ]; then
        cp "$BACKUP" /etc/nginx/sites-enabled/${APP_NAME}
        nginx -t && systemctl reload nginx
        echo "Backup restored"
    fi
    exit 1
fi

