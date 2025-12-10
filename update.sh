#!/bin/bash
set -euo pipefail

# ============================================
# AI Backend - Update Script
# ============================================
# This script updates an existing installation
# Pulls latest code, rebuilds, and restarts services
# Run as: sudo bash update.sh
#
# Environment variables (optional):
#   SKIP_PYTHON_UPDATE=true    - Skip Python dependency updates
#   SKIP_NODE_UPDATE=true      - Skip Node.js dependency updates

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
SKIP_PYTHON_UPDATE="${SKIP_PYTHON_UPDATE:-false}"
SKIP_NODE_UPDATE="${SKIP_NODE_UPDATE:-false}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Check if installation exists
if [ ! -d "$APP_DIR" ] || [ ! -f "$APP_DIR/package.json" ]; then
    echo -e "${RED}ERROR: Installation not found at ${APP_DIR}${NC}"
    echo -e "${YELLOW}For fresh installations, please use: sudo bash build.sh${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AI Backend - Update${NC}"
echo -e "${GREEN}========================================${NC}\n"

cd "$APP_DIR"

# ============================================
# 1. Backup .env
# ============================================
echo -e "${YELLOW}[1/5] Backing up configuration...${NC}"

if [ -f ".env" ]; then
    cp .env .env.backup
    echo -e "${GREEN}✓ Backed up .env file${NC}"
else
    echo -e "${YELLOW}⚠ Warning: .env file not found${NC}"
fi

echo ""

# ============================================
# 2. Pull Latest Code
# ============================================
echo -e "${YELLOW}[2/5] Pulling latest code...${NC}"

if [ -d ".git" ]; then
    # Stash any local changes
    git stash || true
    
    # Pull latest code
    git pull
    
    # Pull Git LFS files if needed
    if command -v git-lfs >/dev/null 2>&1; then
        git lfs install || true
        git lfs pull || true
    fi
    
    echo -e "${GREEN}✓ Code updated${NC}"
else
    echo -e "${RED}⚠ Warning: Not a git repository${NC}"
fi

echo ""

# ============================================
# 3. Update Python Dependencies
# ============================================
echo -e "${YELLOW}[3/5] Updating Python environment...${NC}"

if [ "$SKIP_PYTHON_UPDATE" != "true" ]; then
    # Ensure python directory exists
    mkdir -p python
    
    # Ensure virtual environment exists
    if [ ! -d "python/venv" ]; then
        echo -e "${YELLOW}Creating Python virtual environment...${NC}"
        python3 -m venv python/venv
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ ERROR: Failed to create Python virtual environment${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Created Python virtual environment${NC}"
    fi
    
    # Verify activate script exists
    ACTIVATE_SCRIPT="python/venv/bin/activate"
    if [ ! -f "$ACTIVATE_SCRIPT" ]; then
        echo -e "${RED}✗ ERROR: Virtual environment activate script not found at ${ACTIVATE_SCRIPT}${NC}"
        echo -e "${YELLOW}Recreating virtual environment...${NC}"
        rm -rf python/venv
        python3 -m venv python/venv
        if [ $? -ne 0 ] || [ ! -f "$ACTIVATE_SCRIPT" ]; then
            echo -e "${RED}✗ ERROR: Failed to create Python virtual environment${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Recreated Python virtual environment${NC}"
    fi
    
    # Activate and update
    source "$ACTIVATE_SCRIPT"
    pip install --upgrade pip setuptools wheel --quiet
    
    if [ -f "python/requirements.txt" ]; then
        pip install -r python/requirements.txt
        echo -e "${GREEN}✓ Updated Python dependencies${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: python/requirements.txt not found${NC}"
    fi
    deactivate
else
    echo -e "${YELLOW}⚠ Skipping Python dependency updates${NC}"
fi

# Verify Python executable
PYTHON_EXEC="${APP_DIR}/python/venv/bin/python"
if [ -f "$PYTHON_EXEC" ]; then
    echo -e "${GREEN}✓ Python executable verified${NC}"
else
    echo -e "${RED}✗ ERROR: Python executable not found at ${PYTHON_EXEC}${NC}"
    exit 1
fi

# Ensure cache directories exist
mkdir -p "$APP_DIR/.config/matplotlib"
mkdir -p "$APP_DIR/.cache"
mkdir -p "$APP_DIR/.EasyOCR"
mkdir -p "$APP_DIR/uploads"
mkdir -p "$APP_DIR/frames"
mkdir -p "$APP_DIR/jobs"
mkdir -p "$APP_DIR/data"

echo ""

# ============================================
# 4. Update Node.js Dependencies and Build
# ============================================
echo -e "${YELLOW}[4/5] Building Node.js application...${NC}"

if [ "$SKIP_NODE_UPDATE" != "true" ]; then
    if [ -f "package.json" ]; then
        # Install/update dependencies
        npm ci --production
        echo -e "${GREEN}✓ Updated Node.js dependencies${NC}"
        
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
else
    echo -e "${YELLOW}⚠ Skipping Node.js dependency updates${NC}"
    # Still build if TypeScript exists
    if [ -f "tsconfig.json" ] && [ -f "package.json" ]; then
        npm install typescript --no-save
        npm run build
        npm uninstall typescript
        echo -e "${GREEN}✓ Built TypeScript project${NC}"
    fi
fi

echo -e "${GREEN}✓ Node.js build complete${NC}\n"

# ============================================
# 5. Update .env if needed
# ============================================
if [ -f ".env.backup" ]; then
    echo -e "${YELLOW}[5/5] Updating environment configuration...${NC}"
    
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
    
    chown "$APP_USER:$APP_USER" .env
    chmod 600 .env
    
    echo -e "${GREEN}✓ Environment configuration updated${NC}\n"
else
    echo -e "${YELLOW}[5/5] Skipping environment update (no backup found)${NC}\n"
fi

# ============================================
# 6. Restart Service
# ============================================
echo -e "${YELLOW}Restarting service...${NC}"

# Reload systemd to pick up any service file changes
systemctl daemon-reload

# Restart the service
systemctl restart "${APP_NAME}.service"

# Set ownership
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

echo -e "${GREEN}✓ Service restarted${NC}\n"

# ============================================
# Final Status
# ============================================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${YELLOW}Service Status:${NC}"
systemctl status "${APP_NAME}.service" --no-pager -l | head -15

echo -e "\n${YELLOW}Useful Commands:${NC}"
echo -e "  View logs:    journalctl -u ${APP_NAME}.service -f"
echo -e "  Restart:      systemctl restart ${APP_NAME}.service"
echo -e "  Status:       systemctl status ${APP_NAME}.service"
echo -e "${GREEN}========================================${NC}\n"

