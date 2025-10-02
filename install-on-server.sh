#!/bin/bash

# QR Manager - Installation Script for OpenLiteSpeed Server
# Run this script directly on your server: bash install-on-server.sh

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   QR Manager - Auto Installation      ║${NC}"
echo -e "${BLUE}║   OpenLiteSpeed + Node.js + PM2        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
SERVER_PATH="/home/piumie.com/html/qr-manager"
REPO_URL="https://github.com/hoai2806/qr-manager-piumie.git"
APP_PORT=3000

# Step 1: Check Node.js
echo -e "${YELLOW}[1/8] Checking Node.js...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Node.js 18.x...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
    echo -e "${GREEN}✅ Node.js installed: $(node -v)${NC}"
else
    echo -e "${GREEN}✅ Node.js already installed: $(node -v)${NC}"
fi

# Step 2: Check PM2
echo ""
echo -e "${YELLOW}[2/8] Checking PM2...${NC}"
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}📦 Installing PM2...${NC}"
    npm install -g pm2
    echo -e "${GREEN}✅ PM2 installed: $(pm2 -v)${NC}"
else
    echo -e "${GREEN}✅ PM2 already installed: $(pm2 -v)${NC}"
fi

# Step 3: Create directory
echo ""
echo -e "${YELLOW}[3/8] Setting up directory...${NC}"
if [ ! -d "$SERVER_PATH" ]; then
    echo -e "${YELLOW}📁 Creating directory: $SERVER_PATH${NC}"
    mkdir -p $SERVER_PATH
    echo -e "${GREEN}✅ Directory created${NC}"
else
    echo -e "${GREEN}✅ Directory already exists${NC}"
fi

cd $SERVER_PATH

# Step 4: Clone/Pull repository
echo ""
echo -e "${YELLOW}[4/8] Getting latest code...${NC}"
if [ -d ".git" ]; then
    echo -e "${YELLOW}🔄 Pulling latest changes...${NC}"
    git pull origin main
    echo -e "${GREEN}✅ Code updated${NC}"
else
    echo -e "${YELLOW}📥 Cloning repository...${NC}"
    git clone $REPO_URL .
    echo -e "${GREEN}✅ Repository cloned${NC}"
fi

# Step 5: Install dependencies
echo ""
echo -e "${YELLOW}[5/8] Installing dependencies...${NC}"
npm install --production
echo -e "${GREEN}✅ Dependencies installed${NC}"

# Step 6: Create logs directory
echo ""
echo -e "${YELLOW}[6/8] Creating logs directory...${NC}"
mkdir -p logs
echo -e "${GREEN}✅ Logs directory created${NC}"

# Step 7: Create .env file
echo ""
echo -e "${YELLOW}[7/8] Configuring environment...${NC}"
if [ ! -f ".env" ]; then
    cat > .env << 'EOF'
MONGODB_URI=mongodb+srv://cvhoai_db_user:Ry5Z62YUprIYexWp@qrcodesdc.emvwzan.mongodb.net/qrmanager?retryWrites=true&w=majority&appName=qrcodesdc
ADMIN_PASSCODE=Piumie2024
BASE_URL=https://qr.piumie.com
PORT=3000
NODE_ENV=production
EOF
    echo -e "${GREEN}✅ .env file created${NC}"
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Step 8: Start with PM2
echo ""
echo -e "${YELLOW}[8/8] Starting application...${NC}"

# Stop existing process
pm2 stop qr-manager 2>/dev/null || true
pm2 delete qr-manager 2>/dev/null || true

# Start with PM2
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup
pm2 startup systemd -u root --hp /root 2>/dev/null || true

echo -e "${GREEN}✅ Application started${NC}"

# Show status
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Installation Complete!         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📊 PM2 Status:${NC}"
pm2 status

echo ""
echo -e "${GREEN}🌐 Application Info:${NC}"
echo -e "  • Running on: ${YELLOW}http://localhost:$APP_PORT${NC}"
echo -e "  • Health check: ${YELLOW}http://localhost:$APP_PORT/api/health${NC}"
echo ""

echo -e "${GREEN}📝 Useful Commands:${NC}"
echo -e "  • Check status:  ${YELLOW}pm2 status${NC}"
echo -e "  • View logs:     ${YELLOW}pm2 logs qr-manager${NC}"
echo -e "  • Restart:       ${YELLOW}pm2 restart qr-manager${NC}"
echo -e "  • Stop:          ${YELLOW}pm2 stop qr-manager${NC}"
echo -e "  • Monitor:       ${YELLOW}pm2 monit${NC}"
echo ""

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Next: Configure OpenLiteSpeed    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Option 1: Subdomain (Recommended)${NC}"
echo -e "  URL: ${GREEN}https://qr.piumie.com${NC}"
echo ""
echo -e "  1. Login to OpenLiteSpeed Admin Panel"
echo -e "  2. Create Virtual Host: ${YELLOW}qr.piumie.com${NC}"
echo -e "  3. Add External App:"
echo -e "     - Name: ${YELLOW}qr-manager-node${NC}"
echo -e "     - Address: ${YELLOW}http://127.0.0.1:3000${NC}"
echo -e "  4. Add Context (Proxy):"
echo -e "     - URI: ${YELLOW}/${NC}"
echo -e "     - External App: ${YELLOW}qr-manager-node${NC}"
echo -e "  5. Graceful Restart"
echo ""

echo -e "${YELLOW}Option 2: Path on main domain${NC}"
echo -e "  URL: ${GREEN}https://piumie.com/qr${NC}"
echo ""
echo -e "  1. Login to OpenLiteSpeed Admin Panel"
echo -e "  2. Go to Virtual Host: ${YELLOW}piumie.com${NC}"
echo -e "  3. Add External App (same as above)"
echo -e "  4. Add Context (Proxy):"
echo -e "     - URI: ${YELLOW}/qr${NC}"
echo -e "     - External App: ${YELLOW}qr-manager-node${NC}"
echo -e "  5. Graceful Restart"
echo ""

echo -e "${GREEN}📖 Full guide: ${YELLOW}cat openlitespeed-config.md${NC}"
echo ""

# Test local connection
echo -e "${YELLOW}🧪 Testing local connection...${NC}"
sleep 2
if curl -s http://localhost:$APP_PORT/api/health > /dev/null; then
    echo -e "${GREEN}✅ Application is responding!${NC}"
    echo ""
    echo -e "${GREEN}Response:${NC}"
    curl -s http://localhost:$APP_PORT/api/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:$APP_PORT/api/health
else
    echo -e "${RED}❌ Application not responding. Check logs:${NC}"
    echo -e "${YELLOW}pm2 logs qr-manager${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Done! Happy coding!${NC}"

