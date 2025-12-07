#!/bin/bash

# AI Backend Deployment Script for Hetzner
# This script automates the deployment process

set -e  # Exit on error

echo "🚀 AI Backend Deployment Script"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}Please run as root (use sudo)${NC}"
  exit 1
fi

# Update system
echo -e "${GREEN}[1/8] Updating system...${NC}"
apt update && apt upgrade -y

# Install Docker
echo -e "${GREEN}[2/8] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl start docker
    systemctl enable docker
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${YELLOW}✓ Docker already installed${NC}"
fi

# Install Docker Compose
echo -e "${GREEN}[3/8] Installing Docker Compose...${NC}"
if ! command -v docker compose &> /dev/null; then
    apt install -y docker-compose-plugin
    echo -e "${GREEN}✓ Docker Compose installed${NC}"
else
    echo -e "${YELLOW}✓ Docker Compose already installed${NC}"
fi

# Install additional tools
echo -e "${GREEN}[4/8] Installing additional tools...${NC}"
apt install -y git curl nano htop ufw

# Configure firewall
echo -e "${GREEN}[5/8] Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw --force enable
echo -e "${GREEN}✓ Firewall configured${NC}"

# Create application directory
echo -e "${GREEN}[6/8] Setting up application directory...${NC}"
APP_DIR="/opt/ai-backend"
mkdir -p $APP_DIR
cd $APP_DIR

# Create required directories
mkdir -p uploads frames jobs data
touch uploads/.gitkeep frames/.gitkeep jobs/.gitkeep data/.gitkeep

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}[7/8] Creating .env file...${NC}"
    
    # Generate random API key
    API_KEY=$(openssl rand -hex 32)
    
    cat > .env << EOF
# API Configuration
API_KEY=$API_KEY

# Server Configuration
PORT=3000
NODE_ENV=production

# Detection Configuration
MIN_CONFIDENCE=0.5
EOF
    
    echo -e "${GREEN}✓ .env file created${NC}"
    echo -e "${YELLOW}Your API Key: $API_KEY${NC}"
    echo -e "${YELLOW}Save this key! You'll need it to access the API.${NC}"
else
    echo -e "${YELLOW}✓ .env file already exists${NC}"
fi

# Build and start
echo -e "${GREEN}[8/8] Building and starting application...${NC}"
if [ -f "docker-compose.yml" ]; then
    docker compose build
    docker compose up -d
    echo -e "${GREEN}✓ Application started${NC}"
else
    echo -e "${RED}❌ docker-compose.yml not found${NC}"
    echo -e "${YELLOW}Please upload your application files to $APP_DIR${NC}"
    exit 1
fi

# Display status
echo ""
echo "================================"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "================================"
echo ""
echo "📊 Application Status:"
docker compose ps
echo ""
echo "🌐 Access your application:"
echo "   Dashboard: http://$(curl -s ifconfig.me):3000"
echo "   API Docs:  http://$(curl -s ifconfig.me):3000/docs.html"
echo "   Status:    http://$(curl -s ifconfig.me):3000/status.html"
echo ""
echo "🔐 Your API Key:"
if [ -f ".env" ]; then
    grep "API_KEY=" .env | cut -d'=' -f2
fi
echo ""
echo "📝 View logs:"
echo "   docker compose logs -f"
echo ""
echo "🔄 Restart application:"
echo "   cd $APP_DIR && docker compose restart"
echo ""
echo "🎉 Happy deploying!"

