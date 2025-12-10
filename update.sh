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

# 1. Backup current .env file (in case it gets overwritten)
if [ -f ".env" ]; then
    echo -e "${YELLOW}[1/6] Backing up .env file...${NC}"
    cp .env .env.backup
    echo -e "${GREEN}✓ .env backed up to .env.backup${NC}"
fi

# 2. Pull latest changes from git
echo -e "\n${YELLOW}[2/6] Pulling latest changes from git...${NC}"
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

# 3. Restore .env file if it was overwritten
if [ -f ".env.backup" ] && [ -f ".env" ]; then
    # Check if .env was modified by git pull
    if git diff --quiet .env 2>/dev/null || [ ! -f ".git/HEAD" ]; then
        echo -e "${YELLOW}[3/6] Restoring .env file...${NC}"
        mv .env.backup .env
        chown "$APP_USER:$APP_USER" .env
        chmod 600 .env
        echo -e "${GREEN}✓ .env restored${NC}"
    else
        echo -e "${YELLOW}[3/6] .env was not modified, keeping current version${NC}"
        rm -f .env.backup
    fi
fi

# 4. Update Python dependencies (if requirements.txt changed)
if [ -f "python/requirements.txt" ]; then
    echo -e "\n${YELLOW}[4/6] Checking Python dependencies...${NC}"
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
echo -e "\n${YELLOW}[5/6] Rebuilding TypeScript...${NC}"
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

# 6. Restart service
echo -e "\n${YELLOW}[6/6] Restarting service...${NC}"
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

