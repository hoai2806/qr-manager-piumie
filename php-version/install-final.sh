#!/bin/bash

# QR Manager PHP - FINAL Installation Script
# Cài đặt hoàn chỉnh vào /home/piumie.com/html/

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   QR Manager - FINAL Installation     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Configuration
INSTALL_PATH="/home/piumie.com/html"
REPO_URL="https://github.com/hoai2806/qr-manager-piumie.git"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

# Step 1: Check directory
echo -e "${YELLOW}[1/8] Checking installation directory...${NC}"
if [ ! -d "$INSTALL_PATH" ]; then
    echo -e "${RED}❌ Directory $INSTALL_PATH not found!${NC}"
    echo -e "${YELLOW}Creating directory...${NC}"
    mkdir -p $INSTALL_PATH
fi
echo -e "${GREEN}✅ Directory: $INSTALL_PATH${NC}"

# Step 2: Install PHP
echo ""
echo -e "${YELLOW}[2/8] Installing PHP...${NC}"
if ! command -v php &> /dev/null; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y php php-cli php-pgsql php-gd php-mbstring php-curl php-xml php-zip
fi
echo -e "${GREEN}✅ PHP: $(php -v | head -n 1)${NC}"

# Step 3: Install Composer
echo ""
echo -e "${YELLOW}[3/8] Installing Composer...${NC}"
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php
    mv composer.phar /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
fi
echo -e "${GREEN}✅ Composer installed${NC}"

# Step 4: Install PostgreSQL
echo ""
echo -e "${YELLOW}[4/8] Installing PostgreSQL...${NC}"
if ! command -v psql &> /dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-contrib
    systemctl start postgresql
    systemctl enable postgresql
    sleep 3
fi
echo -e "${GREEN}✅ PostgreSQL installed${NC}"

# Step 5: Setup Database
echo ""
echo -e "${YELLOW}[5/8] Setting up database...${NC}"
sudo -u postgres psql << 'EOSQL' 2>/dev/null || echo "Database may already exist"
DROP DATABASE IF EXISTS qrmanager;
DROP USER IF EXISTS qrmanager_user;
CREATE DATABASE qrmanager;
CREATE USER qrmanager_user WITH ENCRYPTED PASSWORD 'Piumie2024QR';
GRANT ALL PRIVILEGES ON DATABASE qrmanager TO qrmanager_user;
ALTER DATABASE qrmanager OWNER TO qrmanager_user;
EOSQL

sudo -u postgres psql -d qrmanager << 'EOSQL' 2>/dev/null || true
GRANT ALL ON SCHEMA public TO qrmanager_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO qrmanager_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO qrmanager_user;
EOSQL

echo -e "${GREEN}✅ Database configured${NC}"

# Step 6: Download and install application
echo ""
echo -e "${YELLOW}[6/8] Installing application...${NC}"

# Clone to temp directory
TEMP_DIR="/tmp/qr-manager-install-$(date +%s)"
git clone $REPO_URL $TEMP_DIR

# Copy PHP files
echo -e "${YELLOW}Copying files to $INSTALL_PATH...${NC}"
cp -f $TEMP_DIR/php-version/*.php $INSTALL_PATH/
cp -f $TEMP_DIR/php-version/*.html $INSTALL_PATH/
cp -f $TEMP_DIR/php-version/.htaccess $INSTALL_PATH/
cp -f $TEMP_DIR/php-version/composer.json $INSTALL_PATH/

# Create directories
mkdir -p $INSTALL_PATH/uploads/logos
mkdir -p $INSTALL_PATH/uploads/qrcodes

# Install composer dependencies
cd $INSTALL_PATH
composer install --no-dev --optimize-autoloader --no-interaction

# Cleanup
rm -rf $TEMP_DIR

echo -e "${GREEN}✅ Application installed${NC}"

# Step 7: Set permissions
echo ""
echo -e "${YELLOW}[7/8] Setting permissions...${NC}"
chown -R nobody:nogroup $INSTALL_PATH
chmod -R 755 $INSTALL_PATH
chmod -R 777 $INSTALL_PATH/uploads
echo -e "${GREEN}✅ Permissions set${NC}"

# Step 8: Test installation
echo ""
echo -e "${YELLOW}[8/8] Testing installation...${NC}"

# Test PHP
if php -r "echo 'PHP OK';" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PHP working${NC}"
else
    echo -e "${RED}❌ PHP not working${NC}"
fi

# Test PostgreSQL connection
if php -r "new PDO('pgsql:host=localhost;dbname=qrmanager', 'qrmanager_user', 'Piumie2024QR');" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database connection OK${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
fi

# Test files
if [ -f "$INSTALL_PATH/qr-manager.php" ]; then
    echo -e "${GREEN}✅ Files installed${NC}"
else
    echo -e "${RED}❌ Files missing${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      Installation Complete! 🎉        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📍 Installation Path:${NC} $INSTALL_PATH"
echo -e "${GREEN}🌐 Access URLs:${NC}"
echo -e "   • ${YELLOW}https://piumie.com/qr-manager.php${NC}"
echo -e "   • ${YELLOW}https://15.235.192.138/qr-manager.php${NC}"
echo ""
echo -e "${GREEN}🔑 Login:${NC}"
echo -e "   Passcode: ${YELLOW}Piumie2024${NC}"
echo ""

echo -e "${GREEN}📁 Installed files:${NC}"
ls -lh $INSTALL_PATH/*.php $INSTALL_PATH/*.html 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}'

echo ""
echo -e "${YELLOW}🧪 Test now:${NC}"
echo -e "   ${GREEN}curl http://localhost/qr-manager.php${NC}"
echo ""

# Test local access
echo -e "${YELLOW}Testing local access...${NC}"
if curl -s http://localhost/qr-manager.php | grep -q "QR Manager" 2>/dev/null; then
    echo -e "${GREEN}✅ Application is accessible!${NC}"
else
    echo -e "${YELLOW}⚠️  Cannot test local access (may need OpenLiteSpeed restart)${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Next: Open browser and access:       ║${NC}"
echo -e "${BLUE}║  https://piumie.com/qr-manager.php    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}🎉 Done! Enjoy your QR Manager!${NC}"

