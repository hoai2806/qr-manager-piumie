#!/bin/bash

# QR Manager PHP - Installation Script
# Chạy trực tiếp trên OpenLiteSpeed

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   QR Manager PHP - Installation       ║${NC}"
echo -e "${BLUE}║   Chạy trực tiếp trên OpenLiteSpeed   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
INSTALL_PATH="/home/piumie.com/html/qr"
REPO_URL="https://github.com/hoai2806/qr-manager-piumie.git"

echo -e "${YELLOW}[1/6] Checking PHP...${NC}"
if ! command -v php &> /dev/null; then
    echo -e "${YELLOW}Installing PHP...${NC}"
    apt-get update
    apt-get install -y php php-pgsql php-gd php-mbstring php-curl
fi
echo -e "${GREEN}✅ PHP installed: $(php -v | head -n 1)${NC}"

echo ""
echo -e "${YELLOW}[2/6] Checking Composer...${NC}"
if ! command -v composer &> /dev/null; then
    echo -e "${YELLOW}Installing Composer...${NC}"
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
fi
echo -e "${GREEN}✅ Composer installed${NC}"

echo ""
echo -e "${YELLOW}[3/6] Checking PostgreSQL...${NC}"
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}Installing PostgreSQL...${NC}"
    apt-get install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
fi
echo -e "${GREEN}✅ PostgreSQL installed${NC}"

echo ""
echo -e "${YELLOW}[4/6] Setting up database...${NC}"
sudo -u postgres psql << 'EOSQL' 2>/dev/null || echo "Database already exists"
CREATE DATABASE qrmanager;
CREATE USER qrmanager_user WITH ENCRYPTED PASSWORD 'Piumie2024QR';
GRANT ALL PRIVILEGES ON DATABASE qrmanager TO qrmanager_user;
\c qrmanager
GRANT ALL ON SCHEMA public TO qrmanager_user;
EOSQL
echo -e "${GREEN}✅ Database configured${NC}"

echo ""
echo -e "${YELLOW}[5/6] Installing application...${NC}"
mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

if [ -d ".git" ]; then
    git pull origin main
else
    git clone $REPO_URL .
fi

cd php-version
composer install --no-dev --optimize-autoloader

# Create directories
mkdir -p uploads/logos uploads/qrcodes
chmod 755 uploads uploads/logos uploads/qrcodes

echo -e "${GREEN}✅ Application installed${NC}"

echo ""
echo -e "${YELLOW}[6/6] Configuring permissions...${NC}"
chown -R nobody:nogroup $INSTALL_PATH
chmod -R 755 $INSTALL_PATH
echo -e "${GREEN}✅ Permissions set${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Installation Complete!         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📍 Installation Path:${NC} $INSTALL_PATH/php-version"
echo -e "${GREEN}🌐 Access URL:${NC} https://piumie.com/qr"
echo -e "${GREEN}🔑 Passcode:${NC} Piumie2024"
echo ""

echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "1. Vào OpenLiteSpeed Admin Panel"
echo -e "2. Virtual Hosts → piumie.com → Context → Add"
echo -e "3. Type: Static"
echo -e "4. URI: /qr"
echo -e "5. Location: $INSTALL_PATH/php-version/"
echo -e "6. Accessible: Yes"
echo -e "7. Graceful Restart"
echo ""

echo -e "${GREEN}🎉 Done!${NC}"

