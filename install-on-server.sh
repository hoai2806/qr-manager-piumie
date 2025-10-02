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
SERVER_PATH="/root/qr-manager"
REPO_URL="https://github.com/hoai2806/qr-manager-piumie.git"
APP_PORT=5000

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

# Step 7: Install and configure PostgreSQL
echo ""
echo -e "${YELLOW}[7/10] Installing PostgreSQL...${NC}"
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}📦 Installing PostgreSQL...${NC}"
    apt-get update
    apt-get install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
    echo -e "${GREEN}✅ PostgreSQL installed${NC}"
else
    echo -e "${GREEN}✅ PostgreSQL already installed${NC}"
fi

# Step 8: Create database and user
echo ""
echo -e "${YELLOW}[8/10] Configuring PostgreSQL database...${NC}"
sudo -u postgres psql << 'EOSQL'
-- Create database
CREATE DATABASE qrmanager;

-- Create user
CREATE USER qrmanager_user WITH ENCRYPTED PASSWORD 'Piumie2024QR';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE qrmanager TO qrmanager_user;

-- Connect to database and grant schema privileges
\c qrmanager
GRANT ALL ON SCHEMA public TO qrmanager_user;
EOSQL

echo -e "${GREEN}✅ PostgreSQL database configured${NC}"

# Step 9: Create .env file
echo ""
echo -e "${YELLOW}[9/10] Configuring environment...${NC}"
cat > .env << 'EOF'
# Database
DATABASE_URL=postgresql://qrmanager_user:Piumie2024QR@localhost:5432/qrmanager

# Admin
ADMIN_PASSCODE=Piumie2024

# Server
BASE_URL=https://qr.piumie.com
PORT=5000
NODE_ENV=production
EOF
echo -e "${GREEN}✅ .env file created${NC}"

# Step 10: Start with PM2
echo ""
echo -e "${YELLOW}[10/10] Starting application...${NC}"

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

echo -e "${YELLOW}Cài đặt Nginx (song song với OpenLiteSpeed):${NC}"
echo ""

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Nginx...${NC}"
    apt-get update
    apt-get install -y nginx
    echo -e "${GREEN}✅ Nginx installed${NC}"
else
    echo -e "${GREEN}✅ Nginx already installed${NC}"
fi

# Stop Nginx first (to avoid port conflict)
systemctl stop nginx 2>/dev/null || true

# Configure Nginx to use port 8080 (avoid conflict with OpenLiteSpeed on port 80)
echo -e "${YELLOW}📝 Configuring Nginx on port 8080...${NC}"

# Update default Nginx config to use port 8080
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 8080 default_server;
    listen [::]:8080 default_server;

    server_name _;

    location / {
        return 404;
    }
}
EOF

# Create QR Manager config
cat > /etc/nginx/sites-available/qr-manager << 'EOF'
server {
    listen 8080;
    listen [::]:8080;
    server_name qr.piumie.com 15.235.192.138;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/qr-manager /etc/nginx/sites-enabled/

# Test Nginx config
if nginx -t 2>/dev/null; then
    echo -e "${GREEN}✅ Nginx config valid${NC}"
    systemctl start nginx
    systemctl enable nginx
    echo -e "${GREEN}✅ Nginx started on port 8080${NC}"
else
    echo -e "${RED}❌ Nginx config error${NC}"
fi

echo ""
echo -e "${GREEN}🌐 Access URLs:${NC}"
echo -e "  • Via Nginx: ${YELLOW}http://15.235.192.138:8080${NC}"
echo -e "  • Direct: ${YELLOW}http://15.235.192.138:5000${NC}"
echo ""
echo -e "${BLUE}Note: Nginx chạy trên port 8080 (không conflict với OpenLiteSpeed port 80)${NC}"
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

