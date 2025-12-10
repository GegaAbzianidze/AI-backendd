#!/bin/bash
set -euo pipefail

# ============================================
# AI Backend - Fresh Installation Script
# ============================================
# This script performs a complete fresh installation from start to finish
# For updates, use: sudo bash update.sh
# Run as: sudo bash build.sh
#
# Environment variables (optional):
#   DOMAIN=yourdomain.com          - Domain name for HTTPS
#   ADMIN_EMAIL=admin@domain.com   - Email for Let's Encrypt
#   SKIP_SYSTEM_UPDATE=true        - Skip system package updates
#   SKIP_HTTPS=true                - Skip HTTPS setup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="ai-backend"
APP_USER="ai-backend"
APP_DIR="/opt/${APP_NAME}"
DOMAIN="${DOMAIN:-shuaman.publicvm.com}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${DOMAIN}}"
NODE_VERSION="20"
BACKEND_PORT="3000"
SKIP_SYSTEM_UPDATE="${SKIP_SYSTEM_UPDATE:-false}"
SKIP_HTTPS="${SKIP_HTTPS:-false}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Check if installation already exists (more thorough check)
# A complete installation should have at least one of: systemd service, built dist, or node_modules
IS_COMPLETE_INSTALL=false
if [ -d "$APP_DIR" ] && [ -f "$APP_DIR/package.json" ]; then
    if [ -f "/etc/systemd/system/${APP_NAME}.service" ] || \
       [ -d "$APP_DIR/dist" ] || \
       [ -d "$APP_DIR/node_modules" ] || \
       [ -d "$APP_DIR/python/venv" ]; then
        IS_COMPLETE_INSTALL=true
    fi
fi

if [ "$IS_COMPLETE_INSTALL" = true ]; then
    echo -e "${RED}ERROR: Complete installation already exists at ${APP_DIR}${NC}"
    echo -e "${YELLOW}For updates, please use: sudo bash update.sh${NC}"
    echo -e "${YELLOW}To force a fresh rebuild, set FORCE_REBUILD=true${NC}"
    if [ "${FORCE_REBUILD:-false}" != "true" ]; then
        exit 1
    else
        echo -e "${YELLOW}⚠ FORCE_REBUILD enabled - proceeding with fresh installation${NC}\n"
    fi
fi

# Detect Ubuntu version
if [ -f /etc/os-release ]; then
    UBUNTU_VERSION=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2 | cut -d. -f1,2)
    UBUNTU_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
    UBUNTU_MAJOR=$(echo "$UBUNTU_VERSION" | cut -d. -f1)
elif command -v lsb_release >/dev/null 2>&1; then
    UBUNTU_VERSION=$(lsb_release -rs)
    UBUNTU_CODENAME=$(lsb_release -cs)
    UBUNTU_MAJOR=$(echo "$UBUNTU_VERSION" | cut -d. -f1)
else
    UBUNTU_VERSION="22.04"
    UBUNTU_CODENAME="jammy"
    UBUNTU_MAJOR="22"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AI Backend - Fresh Installation${NC}"
echo -e "${GREEN}Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME})${NC}"
echo -e "${GREEN}========================================${NC}\n"

# ============================================
# 1. System Setup
# ============================================
echo -e "${YELLOW}[1/9] Setting up system...${NC}"

if [ "$SKIP_SYSTEM_UPDATE" != "true" ]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get upgrade -y
fi

echo -e "${YELLOW}Installing system dependencies...${NC}"

# Determine correct GL package for Ubuntu version
if [ "$UBUNTU_MAJOR" -ge 24 ]; then
    GL_PACKAGE="libgl1"
else
    GL_PACKAGE="libgl1-mesa-glx"
fi

apt-get install -y \
    git \
    git-lfs \
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
    "$GL_PACKAGE" \
    libglib2.0-0 \
    libgomp1 \
    fonts-dejavu-core \
    fonts-liberation

# Install Node.js
echo -e "${YELLOW}Installing Node.js ${NODE_VERSION}...${NC}"
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install -y nodejs

echo -e "${GREEN}✓ System setup complete${NC}\n"

# ============================================
# 2. Application Directory Setup
# ============================================
echo -e "${YELLOW}[2/9] Setting up application directory...${NC}"

# Create application user
if ! id "$APP_USER" &>/dev/null; then
    useradd -r -s /bin/bash -d "$APP_DIR" -m "$APP_USER"
    echo -e "${GREEN}✓ Created user: ${APP_USER}${NC}"
fi

# Create application directory
mkdir -p "$APP_DIR"

# If repo is not cloned, user needs to clone it first
if [ ! -d "$APP_DIR/.git" ]; then
    echo -e "${RED}ERROR: Repository not found in ${APP_DIR}${NC}"
    echo -e "${YELLOW}Please clone the repository first:${NC}"
    echo -e "${YELLOW}  git clone <your-repo-url> ${APP_DIR}${NC}"
    exit 1
fi

cd "$APP_DIR"

# Pull latest code (if git repo)
if [ -d ".git" ]; then
    echo -e "${YELLOW}Pulling latest code...${NC}"
    git stash || true
    git pull
    
    # Pull Git LFS files if needed
    if command -v git-lfs >/dev/null 2>&1; then
        git lfs install || true
        git lfs pull || true
    fi
    
    echo -e "${GREEN}✓ Code updated${NC}"
fi

echo -e "${GREEN}✓ Application directory ready${NC}\n"

# ============================================
# 3. Python Environment Setup
# ============================================
echo -e "${YELLOW}[3/9] Setting up Python environment...${NC}"

# Create Python virtual environment
if [ ! -d "python/venv" ]; then
    python3 -m venv python/venv
    echo -e "${GREEN}✓ Created Python virtual environment${NC}"
fi

# Install Python dependencies
source python/venv/bin/activate
pip install --upgrade pip setuptools wheel --quiet
if [ -f "python/requirements.txt" ]; then
    pip install -r python/requirements.txt
    echo -e "${GREEN}✓ Installed Python dependencies${NC}"
else
    echo -e "${RED}⚠ Warning: python/requirements.txt not found${NC}"
fi
deactivate

# Verify Python executable
PYTHON_EXEC="${APP_DIR}/python/venv/bin/python"
if [ -f "$PYTHON_EXEC" ]; then
    echo -e "${GREEN}✓ Python executable verified${NC}"
else
    echo -e "${RED}✗ ERROR: Python executable not found${NC}"
    exit 1
fi

# Create cache directories
mkdir -p "$APP_DIR/.config/matplotlib"
mkdir -p "$APP_DIR/.cache"
mkdir -p "$APP_DIR/.EasyOCR"
mkdir -p "$APP_DIR/uploads"
mkdir -p "$APP_DIR/frames"
mkdir -p "$APP_DIR/jobs"
mkdir -p "$APP_DIR/data"

echo -e "${GREEN}✓ Python environment configured${NC}\n"

# ============================================
# 4. Model File Validation
# ============================================
echo -e "${YELLOW}[4/9] Validating model file...${NC}"

MODEL_PATH="${APP_DIR}/models/my_model/train/weights/best.pt"
if [ -f "$MODEL_PATH" ]; then
    FILE_SIZE=$(stat -f%z "$MODEL_PATH" 2>/dev/null || stat -c%s "$MODEL_PATH" 2>/dev/null)
    FIRST_BYTES=$(head -c 50 "$MODEL_PATH" 2>/dev/null || echo "")
    
    # Check if it's a Git LFS pointer
    if echo "$FIRST_BYTES" | grep -q "version https://git-"; then
        echo -e "${YELLOW}⚠ Detected Git LFS pointer, pulling actual file...${NC}"
        if command -v git-lfs >/dev/null 2>&1; then
            git lfs pull
            FILE_SIZE=$(stat -f%z "$MODEL_PATH" 2>/dev/null || stat -c%s "$MODEL_PATH" 2>/dev/null)
        else
            echo -e "${RED}✗ Git LFS not installed. Install with: apt-get install git-lfs${NC}"
        fi
    fi
    
    if [ "$FILE_SIZE" -gt 1048576 ]; then  # > 1MB
        echo -e "${GREEN}✓ Model file valid (${FILE_SIZE} bytes)${NC}"
    else
        echo -e "${RED}⚠ WARNING: Model file is small (${FILE_SIZE} bytes), may be corrupted${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Model file not found at ${MODEL_PATH}${NC}"
    echo -e "${YELLOW}   You may need to upload it manually${NC}"
fi

echo ""

# ============================================
# 5. Node.js Build
# ============================================
echo -e "${YELLOW}[5/9] Building Node.js application...${NC}"

if [ -f "package.json" ]; then
    # Install dependencies
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

echo -e "${GREEN}✓ Node.js build complete${NC}\n"

# ============================================
# 6. Environment Configuration
# ============================================
echo -e "${YELLOW}[6/9] Configuring environment...${NC}"

# Update or create .env file
if [ -f ".env.backup" ]; then
    # Restore backup
    cp .env.backup .env
    
    # Extract sensitive values
    OLD_API_KEY=$(grep "^API_KEY=" .env | cut -d'=' -f2- || echo "")
    OLD_MIN_CONFIDENCE=$(grep "^MIN_CONFIDENCE=" .env | cut -d'=' -f2- || echo "0.5")
    OLD_PORT=$(grep "^PORT=" .env | cut -d'=' -f2- || echo "3000")
    OLD_NODE_ENV=$(grep "^NODE_ENV=" .env | cut -d'=' -f2- || echo "production")
    
    # Remove old path entries
    sed -i '/^HOME=/d; /^APP_DIR=/d; /^RUNTIME_DIR=/d; /^MPLCONFIGDIR=/d; /^XDG_CACHE_HOME=/d; /^XDG_CONFIG_HOME=/d; /^EASYOCR_CACHE_DIR=/d; /^PYTHON_EXECUTABLE=/d; /^YOLO_MODEL_PATH=/d' .env
    
    # Add correct paths
    cat >> .env <<EOF

# Auto-updated paths
HOME=${APP_DIR}
APP_DIR=${APP_DIR}
RUNTIME_DIR=${APP_DIR}
MPLCONFIGDIR=${APP_DIR}/.config/matplotlib
XDG_CACHE_HOME=${APP_DIR}/.cache
XDG_CONFIG_HOME=${APP_DIR}/.config
EASYOCR_CACHE_DIR=${APP_DIR}/.EasyOCR
PYTHON_EXECUTABLE=${APP_DIR}/python/venv/bin/python
YOLO_MODEL_PATH=${APP_DIR}/models/my_model/train/weights/best.pt
EOF
    
    # Preserve sensitive values
    [ -n "$OLD_API_KEY" ] && sed -i "s|^API_KEY=.*|API_KEY=${OLD_API_KEY}|" .env || echo "API_KEY=${OLD_API_KEY}" >> .env
    [ -n "$OLD_MIN_CONFIDENCE" ] && sed -i "s|^MIN_CONFIDENCE=.*|MIN_CONFIDENCE=${OLD_MIN_CONFIDENCE}|" .env || echo "MIN_CONFIDENCE=${OLD_MIN_CONFIDENCE}" >> .env
    [ -n "$OLD_PORT" ] && sed -i "s|^PORT=.*|PORT=${OLD_PORT}|" .env || echo "PORT=${OLD_PORT}" >> .env
    [ -n "$OLD_NODE_ENV" ] && sed -i "s|^NODE_ENV=.*|NODE_ENV=${OLD_NODE_ENV}|" .env || echo "NODE_ENV=${OLD_NODE_ENV}" >> .env
    
    # Clean up duplicates
    awk '!seen[$0]++' .env > .env.tmp && mv .env.tmp .env
    rm -f .env.backup
    echo -e "${GREEN}✓ Updated .env file with correct paths${NC}"
elif [ -f ".env.example" ]; then
    cp .env.example .env
    sed -i "s|/app|${APP_DIR}|g" .env
    
    # Generate API key if needed
    if ! grep -q "^API_KEY=" .env || grep -q "change-me-in-production" .env; then
        API_KEY=$(openssl rand -hex 32)
        sed -i "s|API_KEY=.*|API_KEY=${API_KEY}|" .env
        echo -e "${YELLOW}⚠ Generated API key: ${API_KEY}${NC}"
        echo -e "${YELLOW}⚠ IMPORTANT: Save this API key!${NC}"
    fi
    echo -e "${GREEN}✓ Created .env from .env.example${NC}"
else
    # Create basic .env
    cat > .env <<EOF
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
    echo -e "${GREEN}✓ Created basic .env file${NC}"
fi

chown "$APP_USER:$APP_USER" .env
chmod 600 .env

echo -e "${GREEN}✓ Environment configured${NC}\n"

# ============================================
# 7. Systemd Service Setup
# ============================================
echo -e "${YELLOW}[7/9] Setting up systemd service...${NC}"

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
Environment="PYTHON_EXECUTABLE=${APP_DIR}/python/venv/bin/python"
Environment="YOLO_MODEL_PATH=${APP_DIR}/models/my_model/train/weights/best.pt"
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

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${APP_NAME}.service"
systemctl restart "${APP_NAME}.service"

echo -e "${GREEN}✓ Systemd service configured${NC}\n"

# ============================================
# 8. Nginx Configuration
# ============================================
echo -e "${YELLOW}[8/9] Configuring Nginx...${NC}"

cat > "/etc/nginx/sites-available/${APP_NAME}" <<EOF
server {
    listen 80;
    server_name ${DOMAIN} _;

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

ln -sf "/etc/nginx/sites-available/${APP_NAME}" "/etc/nginx/sites-enabled/${APP_NAME}"
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl restart nginx
systemctl enable nginx

echo -e "${GREEN}✓ Nginx configured${NC}\n"

# ============================================
# 9. HTTPS Setup (Optional)
# ============================================
if [ "$SKIP_HTTPS" != "true" ] && [ "$DOMAIN" != "mydomain.com" ] && [ "$DOMAIN" != "_" ]; then
    echo -e "${YELLOW}[9/9] Setting up HTTPS...${NC}"
    
    # Check DNS
    SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "unknown")
    DOMAIN_IP=$(dig +short "${DOMAIN}" | tail -n1 || echo "unknown")
    
    if [ "$DOMAIN_IP" = "$SERVER_IP" ] || [ "$DOMAIN_IP" = "unknown" ] || [ "$SERVER_IP" = "unknown" ]; then
        if certbot --nginx \
            --non-interactive \
            --agree-tos \
            --email "${ADMIN_EMAIL}" \
            -d "${DOMAIN}" \
            --redirect 2>&1 | tee /tmp/certbot-output.log; then
            systemctl enable certbot.timer
            systemctl start certbot.timer
            echo -e "${GREEN}✓ HTTPS configured${NC}"
        else
            echo -e "${YELLOW}⚠ HTTPS setup failed. Run manually: certbot --nginx -d ${DOMAIN}${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Domain ${DOMAIN} does not point to this server (${SERVER_IP})${NC}"
        echo -e "${YELLOW}   Skipping HTTPS. Configure DNS and run: certbot --nginx -d ${DOMAIN}${NC}"
    fi
else
    echo -e "${YELLOW}[9/9] Skipping HTTPS setup${NC}"
fi

# ============================================
# Firewall Setup
# ============================================
echo -e "\n${YELLOW}Configuring firewall...${NC}"
ufw allow OpenSSH
ufw allow 'Nginx Full'
echo "y" | ufw enable
echo -e "${GREEN}✓ Firewall configured${NC}"

# Set ownership
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

# ============================================
# Final Status
# ============================================
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${YELLOW}Service Status:${NC}"
systemctl status "${APP_NAME}.service" --no-pager -l | head -15

echo -e "\n${YELLOW}Summary:${NC}"
echo -e "  Application: ${APP_DIR}"
echo -e "  User: ${APP_USER}"
echo -e "  Port: ${BACKEND_PORT}"
echo -e "  Domain: ${DOMAIN}"
echo -e "\n${GREEN}Access URLs:${NC}"
if [ "$DOMAIN" != "mydomain.com" ] && [ "$DOMAIN" != "_" ]; then
    echo -e "  HTTP:  http://${DOMAIN}"
    echo -e "  HTTPS: https://${DOMAIN}"
else
    echo -e "  HTTP:  http://$(hostname -I | awk '{print $1}')"
fi
echo -e "\n${YELLOW}Useful Commands:${NC}"
echo -e "  View logs:    journalctl -u ${APP_NAME}.service -f"
echo -e "  Restart:      systemctl restart ${APP_NAME}.service"
echo -e "  Status:       systemctl status ${APP_NAME}.service"
echo -e "  Update:       sudo bash update.sh"
echo -e "${GREEN}========================================${NC}\n"

