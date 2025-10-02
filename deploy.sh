#!/bin/bash

# QR Manager - Auto Deploy Script
# Server: 15.235.192.138
# Path: /home/piumie.com/html/qr-manager

set -e

echo "🚀 Starting deployment..."

# Server details
SERVER_IP="15.235.192.138"
SERVER_USER="root"
SERVER_PATH="/home/piumie.com/html/qr-manager"
REPO_URL="https://github.com/hoai2806/qr-manager-piumie.git"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📡 Connecting to server...${NC}"

# Deploy via SSH
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'

# Set variables
SERVER_PATH="/home/piumie.com/html/qr-manager"
REPO_URL="https://github.com/hoai2806/qr-manager-piumie.git"

echo "✅ Connected to server"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "📦 Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
else
    echo "✅ Node.js already installed: $(node -v)"
fi

# Check if PM2 is installed
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2..."
    npm install -g pm2
else
    echo "✅ PM2 already installed: $(pm2 -v)"
fi

# Create directory if not exists
if [ ! -d "$SERVER_PATH" ]; then
    echo "📁 Creating directory..."
    mkdir -p $SERVER_PATH
fi

cd $SERVER_PATH

# Clone or pull repository
if [ -d ".git" ]; then
    echo "🔄 Pulling latest changes..."
    git pull origin main
else
    echo "📥 Cloning repository..."
    git clone $REPO_URL .
fi

# Create logs directory
mkdir -p logs

# Install dependencies
echo "📦 Installing dependencies..."
npm install --production

# Create .env file if not exists
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file..."
    cat > .env << 'EOF'
MONGODB_URI=mongodb+srv://cvhoai_db_user:Ry5Z62YUprIYexWp@qrcodesdc.emvwzan.mongodb.net/qrmanager?retryWrites=true&w=majority&appName=qrcodesdc
ADMIN_PASSCODE=Piumie2024
BASE_URL=https://qr.piumie.com
PORT=3000
NODE_ENV=production
EOF
    echo "✅ .env file created"
else
    echo "✅ .env file already exists"
fi

# Stop existing PM2 process
echo "🛑 Stopping existing process..."
pm2 stop qr-manager 2>/dev/null || true
pm2 delete qr-manager 2>/dev/null || true

# Start with PM2
echo "🚀 Starting application with PM2..."
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Setup PM2 startup script
pm2 startup systemd -u root --hp /root 2>/dev/null || true

# Show status
echo ""
echo "📊 PM2 Status:"
pm2 status

echo ""
echo "📝 Recent logs:"
pm2 logs qr-manager --lines 20 --nostream

echo ""
echo "✅ Deployment completed!"
echo "🌐 Application running on: http://localhost:3000"
echo ""
echo "📋 Useful commands:"
echo "  - Check status: pm2 status"
echo "  - View logs: pm2 logs qr-manager"
echo "  - Restart: pm2 restart qr-manager"
echo "  - Stop: pm2 stop qr-manager"

ENDSSH

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo -e "${YELLOW}🔧 Next step: Configure OpenLiteSpeed proxy${NC}"
echo ""
echo "1. Login to OpenLiteSpeed Admin: https://15.235.192.138:7080"
echo "2. Go to: Virtual Hosts → piumie.com → Context"
echo "3. Add Proxy Context:"
echo "   - URI: /qr"
echo "   - Web Server Type: Proxy"
echo "   - Web Server: http://127.0.0.1:3000"
echo "4. Graceful Restart"
echo ""
echo "🌐 Access: https://piumie.com/qr"

