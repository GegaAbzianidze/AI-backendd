#!/bin/bash
set -euo pipefail

# ============================================
# Ubuntu Server Deployment Script
# AI Backend - Node.js + Python Detection Service
# ============================================
# This script sets up the entire application on a fresh Ubuntu 22.04 server
# Run as: sudo bash deploy_ubuntu.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration (modify these as needed)
APP_NAME="ai-backend"
APP_USER="ai-backend"
APP_DIR="/opt/${APP_NAME}"
DOMAIN="${DOMAIN:-shuaman.publicvm.com}"  # Set DOMAIN environment variable or edit here
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"  # For Let's Encrypt
NODE_VERSION="20"  # Node.js version
BACKEND_PORT="3000"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting deployment of ${APP_NAME}${NC}"
echo -e "${GREEN}========================================${NC}"

# ============================================
# 3.1. Basic System Setup
# ============================================
echo -e "\n${YELLOW}[1/8] Updating system packages...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

echo -e "\n${YELLOW}[2/8] Installing system dependencies...${NC}"
apt-get install -y \
    git \
    curl \
    build-essential \
    python3 \
    python3-venv \
    python3-pip \
    nginx \
    ufw \
    certbot \
    python3-certbot-nginx \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libgomp1 \
    fonts-dejavu-core \
    fonts-liberation

# Install Node.js via NodeSource repository
echo -e "\n${YELLOW}Installing Node.js ${NODE_VERSION}...${NC}"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install -y nodejs

# Verify installations
echo -e "\n${GREEN}✓ Installed versions:${NC}"
node --version
npm --version
python3 --version
nginx -v

# ============================================
# 3.2. Project Setup (Python)
# ============================================
echo -e "\n${YELLOW}[3/8] Setting up Python environment...${NC}"

# Create application user if it doesn't exist
if ! id "$APP_USER" &>/dev/null; then
    useradd -r -s /bin/bash -d "$APP_DIR" -m "$APP_USER"
    echo -e "${GREEN}✓ Created user: ${APP_USER}${NC}"
else
    echo -e "${GREEN}✓ User ${APP_USER} already exists${NC}"
fi

# Create application directory structure
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# If repo is not cloned, clone it (assuming it's in current directory)
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Note: If repository is not in ${APP_DIR}, please clone it there first${NC}"
    echo -e "${YELLOW}Or copy the project files to ${APP_DIR}${NC}"
fi

# Create Python virtual environment
if [ ! -d "python/venv" ]; then
    python3 -m venv python/venv
    echo -e "${GREEN}✓ Created Python virtual environment${NC}"
fi

# Activate venv and install dependencies
source python/venv/bin/activate
pip install --upgrade pip setuptools wheel
if [ -f "python/requirements.txt" ]; then
    pip install -r python/requirements.txt
    echo -e "${GREEN}✓ Installed Python dependencies${NC}"
else
    echo -e "${RED}⚠ Warning: python/requirements.txt not found${NC}"
fi
deactivate

# Create cache directories with proper permissions
mkdir -p "$APP_DIR/.config/matplotlib"
mkdir -p "$APP_DIR/.cache"
mkdir -p "$APP_DIR/.EasyOCR"
mkdir -p "$APP_DIR/uploads"
mkdir -p "$APP_DIR/frames"
mkdir -p "$APP_DIR/jobs"
mkdir -p "$APP_DIR/data"

# Set ownership
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
chmod -R 755 "$APP_DIR/.config" "$APP_DIR/.cache" "$APP_DIR/.EasyOCR"
chmod -R 755 "$APP_DIR/uploads" "$APP_DIR/frames" "$APP_DIR/jobs" "$APP_DIR/data"

echo -e "${GREEN}✓ Python environment configured${NC}"

# ============================================
# 3.3. Project Setup (Node.js)
# ============================================
echo -e "\n${YELLOW}[4/8] Setting up Node.js backend...${NC}"

cd "$APP_DIR"

# Install Node.js dependencies
if [ -f "package.json" ]; then
    npm ci --production
    echo -e "${GREEN}✓ Installed Node.js dependencies${NC}"
    
    # Build TypeScript
    if [ -f "tsconfig.json" ]; then
        npm install typescript --no-save
        npm run build
        npm uninstall typescript
        echo -e "${GREEN}✓ Built TypeScript project${NC}"
    fi
else
    echo -e "${RED}⚠ Warning: package.json not found${NC}"
fi

# Create .env file if it doesn't exist
if [ ! -f "$APP_DIR/.env" ]; then
    echo -e "${YELLOW}Creating .env file from .env.example...${NC}"
    if [ -f "$APP_DIR/.env.example" ]; then
        cp "$APP_DIR/.env.example" "$APP_DIR/.env"
        # Generate a random API key
        API_KEY=$(openssl rand -hex 32)
        sed -i "s/API_KEY=change-me-in-production/API_KEY=${API_KEY}/" "$APP_DIR/.env"
        echo -e "${GREEN}✓ Created .env file with generated API key${NC}"
        echo -e "${YELLOW}⚠ IMPORTANT: Save your API key: ${API_KEY}${NC}"
    else
        echo -e "${RED}⚠ Warning: .env.example not found, creating basic .env${NC}"
        cat > "$APP_DIR/.env" <<EOF
NODE_ENV=production
PORT=${BACKEND_PORT}
API_KEY=$(openssl rand -hex 32)
HOME=${APP_DIR}
APP_DIR=${APP_DIR}
RUNTIME_DIR=${APP_DIR}
MPLCONFIGDIR=${APP_DIR}/.config/matplotlib
XDG_CACHE_HOME=${APP_DIR}/.cache
XDG_CONFIG_HOME=${APP_DIR}/.config
EASYOCR_CACHE_DIR=${APP_DIR}/.EasyOCR
PYTHON_EXECUTABLE=${APP_DIR}/python/venv/bin/python
YOLO_MODEL_PATH=${APP_DIR}/models/my_model/train/weights/best.pt
MIN_CONFIDENCE=0.5
EOF
    fi
    chown "$APP_USER:$APP_USER" "$APP_DIR/.env"
    chmod 600 "$APP_DIR/.env"
fi

# Set ownership
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

echo -e "${GREEN}✓ Node.js backend configured${NC}"

# ============================================
# 3.4. Process Management (systemd)
# ============================================
echo -e "\n${YELLOW}[5/8] Setting up systemd services...${NC}"

# Create systemd service file for Node.js backend
cat > "/etc/systemd/system/${APP_NAME}.service" <<EOF
[Unit]
Description=AI Backend Node.js API Server
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/.env
Environment="HOME=${APP_DIR}"
Environment="APP_DIR=${APP_DIR}"
Environment="RUNTIME_DIR=${APP_DIR}"
Environment="MPLCONFIGDIR=${APP_DIR}/.config/matplotlib"
Environment="XDG_CACHE_HOME=${APP_DIR}/.cache"
Environment="XDG_CONFIG_HOME=${APP_DIR}/.config"
Environment="EASYOCR_CACHE_DIR=${APP_DIR}/.EasyOCR"
ExecStart=/usr/bin/node ${APP_DIR}/dist/index.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${APP_NAME}

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${APP_DIR}/uploads ${APP_DIR}/frames ${APP_DIR}/jobs ${APP_DIR}/data ${APP_DIR}/.config ${APP_DIR}/.cache ${APP_DIR}/.EasyOCR

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable "${APP_NAME}.service"
systemctl restart "${APP_NAME}.service"

echo -e "${GREEN}✓ Systemd service created and started${NC}"

# ============================================
# 3.5. Nginx Configuration
# ============================================
echo -e "\n${YELLOW}[6/8] Configuring Nginx...${NC}"

# Create Nginx configuration
cat > "/etc/nginx/sites-available/${APP_NAME}" <<EOF
server {
    listen 80;
    server_name ${DOMAIN} _;

    client_max_body_size 500M;
    
    # Logging
    access_log /var/log/nginx/${APP_NAME}-access.log;
    error_log /var/log/nginx/${APP_NAME}-error.log;

    # Proxy settings
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    
    # Timeouts for long-running requests
    proxy_connect_timeout 300s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    send_timeout 300s;

    # API routes
    location /api/ {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass \$http_upgrade;
    }

    # Static files (frames, previews)
    location /frames/ {
        alias ${APP_DIR}/frames/;
        expires 1h;
        add_header Cache-Control "public, immutable";
    }

    # Public static files
    location / {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable site
ln -sf "/etc/nginx/sites-available/${APP_NAME}" "/etc/nginx/sites-enabled/${APP_NAME}"
rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
nginx -t

# Restart Nginx
systemctl restart nginx
systemctl enable nginx

echo -e "${GREEN}✓ Nginx configured and started${NC}"

# ============================================
# 3.6. HTTPS Setup (Let's Encrypt)
# ============================================
echo -e "\n${YELLOW}[7/8] Setting up HTTPS (Let's Encrypt)...${NC}"

if [ "$DOMAIN" != "mydomain.com" ] && [ "$DOMAIN" != "_" ]; then
    echo -e "${YELLOW}Attempting to obtain SSL certificate for ${DOMAIN}...${NC}"
    
    # Run certbot in non-interactive mode
    certbot --nginx \
        --non-interactive \
        --agree-tos \
        --email "${ADMIN_EMAIL}" \
        -d "${DOMAIN}" \
        --redirect || {
        echo -e "${YELLOW}⚠ SSL certificate setup failed. You can run manually later:${NC}"
        echo -e "${YELLOW}   certbot --nginx -d ${DOMAIN}${NC}"
    }
    
    # Set up auto-renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    echo -e "${GREEN}✓ HTTPS configured${NC}"
else
    echo -e "${YELLOW}⚠ Skipping HTTPS setup (domain not configured)${NC}"
    echo -e "${YELLOW}   To set up HTTPS later, run:${NC}"
    echo -e "${YELLOW}   certbot --nginx -d yourdomain.com${NC}"
fi

# ============================================
# 3.7. Firewall Configuration (UFW)
# ============================================
echo -e "\n${YELLOW}[8/8] Configuring firewall...${NC}"

# Allow SSH first (critical!)
ufw allow OpenSSH

# Allow HTTP and HTTPS
ufw allow 'Nginx Full'

# Enable firewall (non-interactive)
echo "y" | ufw enable

echo -e "${GREEN}✓ Firewall configured${NC}"

# ============================================
# 3.8. Final Checks and Summary
# ============================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Check service status
echo -e "${YELLOW}Service Status:${NC}"
systemctl status "${APP_NAME}.service" --no-pager -l || true

echo -e "\n${YELLOW}Nginx Status:${NC}"
systemctl status nginx --no-pager -l || true

echo -e "\n${YELLOW}Firewall Status:${NC}"
ufw status

echo -e "\n${YELLOW}========================================${NC}"
echo -e "${GREEN}Deployment Summary${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Application Directory: ${APP_DIR}"
echo -e "Application User: ${APP_USER}"
echo -e "Backend Port: ${BACKEND_PORT}"
echo -e "Domain: ${DOMAIN}"
echo -e "\n${GREEN}Access URLs:${NC}"
if [ "$DOMAIN" != "mydomain.com" ] && [ "$DOMAIN" != "_" ]; then
    echo -e "  HTTP:  http://${DOMAIN}"
    echo -e "  HTTPS: https://${DOMAIN}"
else
    echo -e "  HTTP:  http://$(hostname -I | awk '{print $1}')"
    echo -e "  HTTP:  http://localhost"
fi
echo -e "\n${GREEN}Logs:${NC}"
echo -e "  Application: journalctl -u ${APP_NAME}.service -f"
echo -e "  Nginx Access: /var/log/nginx/${APP_NAME}-access.log"
echo -e "  Nginx Error:  /var/log/nginx/${APP_NAME}-error.log"
echo -e "\n${GREEN}Useful Commands:${NC}"
echo -e "  Restart app:    systemctl restart ${APP_NAME}.service"
echo -e "  View logs:      journalctl -u ${APP_NAME}.service -f"
echo -e "  Check status:  systemctl status ${APP_NAME}.service"
echo -e "\n${YELLOW}⚠ IMPORTANT:${NC}"
echo -e "  - Save your API key from ${APP_DIR}/.env"
echo -e "  - Configure your domain DNS to point to this server"
echo -e "  - Run 'certbot --nginx -d yourdomain.com' to enable HTTPS"
echo -e "${GREEN}========================================${NC}\n"

