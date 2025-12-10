#!/bin/bash
# Quick update script for AI Backend
# Pulls latest changes, rebuilds, and restarts services
# Run as: sudo bash update.sh

set -euo pipefail

APP_DIR="/opt/ai-backend"
APP_USER="ai-backend"
SERVICE_NAME="ai-backend"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Updating AI Backend${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Check if directory exists
if [ ! -d "$APP_DIR" ]; then
    echo -e "${RED}ERROR: Application directory not found: $APP_DIR${NC}"
    exit 1
fi

cd "$APP_DIR"

# 1. Backup current .env file
if [ -f ".env" ]; then
    echo -e "${YELLOW}[1/7] Backing up .env file...${NC}"
    cp .env .env.backup
    echo -e "${GREEN}✓ .env backed up to .env.backup${NC}"
else
    echo -e "${YELLOW}[1/7] No .env file found, will create one from .env.example${NC}"
fi

# 2. Pull latest changes from git
echo -e "\n${YELLOW}[2/7] Pulling latest changes from git...${NC}"
if [ -d ".git" ]; then
    # Stash any local changes (if any)
    git stash || true
    
    # Pull latest changes
    git pull
    
    echo -e "${GREEN}✓ Git pull completed${NC}"
else
    echo -e "${RED}⚠ Warning: Not a git repository. Skipping git pull.${NC}"
    echo -e "${YELLOW}  If you need to update files, copy them manually.${NC}"
fi

# 3. Update .env file with correct paths while preserving sensitive values
echo -e "\n${YELLOW}[3/7] Updating .env file paths...${NC}"
if [ -f ".env.backup" ]; then
    # Restore backup first
    cp .env.backup .env
    
    # Extract API_KEY and other sensitive values from backup
    OLD_API_KEY=$(grep "^API_KEY=" .env.backup | cut -d'=' -f2- || echo "")
    OLD_MIN_CONFIDENCE=$(grep "^MIN_CONFIDENCE=" .env.backup | cut -d'=' -f2- || echo "0.5")
    OLD_PORT=$(grep "^PORT=" .env.backup | cut -d'=' -f2- || echo "3000")
    OLD_NODE_ENV=$(grep "^NODE_ENV=" .env.backup | cut -d'=' -f2- || echo "production")
    
    # Update paths in .env file
    # Remove old path entries
    sed -i '/^HOME=/d' .env
    sed -i '/^APP_DIR=/d' .env
    sed -i '/^RUNTIME_DIR=/d' .env
    sed -i '/^MPLCONFIGDIR=/d' .env
    sed -i '/^XDG_CACHE_HOME=/d' .env
    sed -i '/^XDG_CONFIG_HOME=/d' .env
    sed -i '/^EASYOCR_CACHE_DIR=/d' .env
    sed -i '/^PYTHON_EXECUTABLE=/d' .env
    sed -i '/^YOLO_MODEL_PATH=/d' .env
    
    # Add correct paths
    cat >> .env <<EOF

# Updated paths (auto-updated by update.sh)
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
    
    # Ensure sensitive values are preserved
    if [ -n "$OLD_API_KEY" ]; then
        sed -i "s|^API_KEY=.*|API_KEY=${OLD_API_KEY}|" .env || echo "API_KEY=${OLD_API_KEY}" >> .env
    fi
    if [ -n "$OLD_MIN_CONFIDENCE" ]; then
        sed -i "s|^MIN_CONFIDENCE=.*|MIN_CONFIDENCE=${OLD_MIN_CONFIDENCE}|" .env || echo "MIN_CONFIDENCE=${OLD_MIN_CONFIDENCE}" >> .env
    fi
    if [ -n "$OLD_PORT" ]; then
        sed -i "s|^PORT=.*|PORT=${OLD_PORT}|" .env || echo "PORT=${OLD_PORT}" >> .env
    fi
    if [ -n "$OLD_NODE_ENV" ]; then
        sed -i "s|^NODE_ENV=.*|NODE_ENV=${OLD_NODE_ENV}|" .env || echo "NODE_ENV=${OLD_NODE_ENV}" >> .env
    fi
    
    # Remove duplicate entries and clean up
    awk '!seen[$0]++' .env > .env.tmp && mv .env.tmp .env
    
    chown "$APP_USER:$APP_USER" .env
    chmod 600 .env
    echo -e "${GREEN}✓ .env file updated with correct paths${NC}"
    echo -e "${GREEN}✓ Sensitive values (API_KEY, etc.) preserved${NC}"
elif [ -f ".env.example" ]; then
    # Create .env from example if it doesn't exist
    echo -e "${YELLOW}Creating .env from .env.example...${NC}"
    cp .env.example .env
    
    # Update paths in the new .env
    sed -i "s|/app|${APP_DIR}|g" .env
    
    # Generate API key if not set
    if ! grep -q "^API_KEY=" .env || grep -q "change-me-in-production" .env; then
        API_KEY=$(openssl rand -hex 32)
        sed -i "s|API_KEY=.*|API_KEY=${API_KEY}|" .env
        echo -e "${YELLOW}⚠ Generated new API key: ${API_KEY}${NC}"
        echo -e "${YELLOW}⚠ IMPORTANT: Save this API key!${NC}"
    fi
    
    chown "$APP_USER:$APP_USER" .env
    chmod 600 .env
    echo -e "${GREEN}✓ Created .env file from .env.example${NC}"
else
    echo -e "${RED}⚠ Warning: No .env or .env.example found${NC}"
    echo -e "${YELLOW}  Creating basic .env file...${NC}"
    cat > .env <<EOF
NODE_ENV=production
PORT=3000
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
    chown "$APP_USER:$APP_USER" .env
    chmod 600 .env
    echo -e "${GREEN}✓ Created basic .env file${NC}"
fi

# 4. Update Python dependencies (if requirements.txt changed)
if [ -f "python/requirements.txt" ]; then
    echo -e "\n${YELLOW}[4/7] Checking Python dependencies...${NC}"
    if [ -d "python/venv" ]; then
        source python/venv/bin/activate
        pip install --upgrade pip setuptools wheel >/dev/null 2>&1
        pip install -r python/requirements.txt
        deactivate
        echo -e "${GREEN}✓ Python dependencies updated${NC}"
    else
        echo -e "${RED}⚠ Python venv not found. Creating...${NC}"
        python3 -m venv python/venv
        source python/venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r python/requirements.txt
        deactivate
        echo -e "${GREEN}✓ Python venv created and dependencies installed${NC}"
    fi
fi

# 5. Rebuild TypeScript
echo -e "\n${YELLOW}[5/7] Rebuilding TypeScript...${NC}"
if [ -f "package.json" ]; then
    # Install dependencies if needed
    npm ci --production
    
    # Install TypeScript for build (temporary)
    npm install typescript --no-save
    
    # Build
    npm run build
    
    # Remove TypeScript (keep production dependencies only)
    npm uninstall typescript
    
    echo -e "${GREEN}✓ TypeScript build completed${NC}"
else
    echo -e "${RED}⚠ Warning: package.json not found${NC}"
fi

# 6. Update systemd service with correct paths (if needed)
echo -e "\n${YELLOW}[6/7] Verifying systemd service configuration...${NC}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
if [ -f "$SERVICE_FILE" ]; then
    # Check if PYTHON_EXECUTABLE is set correctly
    if ! grep -q "PYTHON_EXECUTABLE=${APP_DIR}/python/venv/bin/python" "$SERVICE_FILE"; then
        echo -e "${YELLOW}Updating systemd service with correct paths...${NC}"
        # Add/update PYTHON_EXECUTABLE if missing
        if ! grep -q 'Environment="PYTHON_EXECUTABLE=' "$SERVICE_FILE"; then
            sed -i '/Environment="EASYOCR_CACHE_DIR=/a Environment="PYTHON_EXECUTABLE='"${APP_DIR}"'/python/venv/bin/python"' "$SERVICE_FILE"
        else
            sed -i "s|Environment=\"PYTHON_EXECUTABLE=.*|Environment=\"PYTHON_EXECUTABLE=${APP_DIR}/python/venv/bin/python\"|" "$SERVICE_FILE"
        fi
        # Update YOLO_MODEL_PATH if missing
        if ! grep -q 'Environment="YOLO_MODEL_PATH=' "$SERVICE_FILE"; then
            sed -i '/Environment="PYTHON_EXECUTABLE=/a Environment="YOLO_MODEL_PATH='"${APP_DIR}"'/models/my_model/train/weights/best.pt"' "$SERVICE_FILE"
        else
            sed -i "s|Environment=\"YOLO_MODEL_PATH=.*|Environment=\"YOLO_MODEL_PATH=${APP_DIR}/models/my_model/train/weights/best.pt\"|" "$SERVICE_FILE"
        fi
        systemctl daemon-reload
        echo -e "${GREEN}✓ Systemd service updated${NC}"
    else
        echo -e "${GREEN}✓ Systemd service paths are correct${NC}"
    fi
fi

# 7. Restart service
echo -e "\n${YELLOW}[7/7] Restarting service...${NC}"
systemctl daemon-reload
systemctl restart "$SERVICE_NAME.service"

# Wait a moment for service to start
sleep 2

# Check status
if systemctl is-active --quiet "$SERVICE_NAME.service"; then
    echo -e "${GREEN}✓ Service restarted successfully${NC}"
else
    echo -e "${RED}✗ Service failed to start. Check logs:${NC}"
    echo -e "${YELLOW}  journalctl -u $SERVICE_NAME.service -n 50${NC}"
    exit 1
fi

# Set ownership
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${YELLOW}Service Status:${NC}"
systemctl status "$SERVICE_NAME.service" --no-pager -l | head -15

echo -e "\n${YELLOW}Useful commands:${NC}"
echo -e "  View logs:    journalctl -u $SERVICE_NAME.service -f"
echo -e "  Check status: systemctl status $SERVICE_NAME.service"
echo -e "  Restart:      systemctl restart $SERVICE_NAME.service"

