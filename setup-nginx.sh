#!/bin/bash

# Setup Nginx for QR Manager (song song với OpenLiteSpeed)
# Nginx sẽ chạy trên port 8080, không ảnh hưởng OpenLiteSpeed port 80

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Setup Nginx for QR Manager          ║${NC}"
echo -e "${BLUE}║   Port 8080 (không conflict OLS)       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root${NC}"
    exit 1
fi

# Install Nginx
echo -e "${YELLOW}[1/4] Installing Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    apt-get update
    apt-get install -y nginx
    echo -e "${GREEN}✅ Nginx installed${NC}"
else
    echo -e "${GREEN}✅ Nginx already installed: $(nginx -v 2>&1)${NC}"
fi

# Stop Nginx
echo ""
echo -e "${YELLOW}[2/4] Stopping Nginx...${NC}"
systemctl stop nginx 2>/dev/null || true

# Configure Nginx
echo ""
echo -e "${YELLOW}[3/4] Configuring Nginx...${NC}"

# Update default config to use port 8080
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 8080 default_server;
    listen [::]:8080 default_server;
    
    server_name _;
    
    root /var/www/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# Create QR Manager config
cat > /etc/nginx/sites-available/qr-manager << 'EOF'
server {
    listen 8080;
    listen [::]:8080;
    
    # Accept requests from IP or domain
    server_name qr.piumie.com 15.235.192.138;
    
    # Logs
    access_log /var/log/nginx/qr-manager-access.log;
    error_log /var/log/nginx/qr-manager-error.log;
    
    # Proxy to Node.js app
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Cache
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable site
ln -sf /etc/nginx/sites-available/qr-manager /etc/nginx/sites-enabled/

echo -e "${GREEN}✅ Nginx configured${NC}"

# Test and start
echo ""
echo -e "${YELLOW}[4/4] Starting Nginx...${NC}"

if nginx -t 2>&1; then
    echo -e "${GREEN}✅ Nginx config valid${NC}"
    systemctl start nginx
    systemctl enable nginx
    echo -e "${GREEN}✅ Nginx started${NC}"
else
    echo -e "${RED}❌ Nginx config error${NC}"
    exit 1
fi

# Show status
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Setup Complete!                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📊 Nginx Status:${NC}"
systemctl status nginx --no-pager | head -5

echo ""
echo -e "${GREEN}🌐 Access URLs:${NC}"
echo -e "  • Via Nginx (port 8080): ${YELLOW}http://15.235.192.138:8080${NC}"
echo -e "  • Direct Node.js (port 5000): ${YELLOW}http://localhost:5000${NC}"
echo ""

echo -e "${GREEN}🔍 Check if ports are listening:${NC}"
netstat -tlnp | grep -E ':(8080|5000)' || ss -tlnp | grep -E ':(8080|5000)'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   OpenLiteSpeed vẫn chạy bình thường  ║${NC}"
echo -e "${BLUE}║   Port 80/443: OpenLiteSpeed           ║${NC}"
echo -e "${BLUE}║   Port 8080: Nginx → QR Manager        ║${NC}"
echo -e "${BLUE}║   Port 5000: Node.js App               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📝 Useful commands:${NC}"
echo -e "  • Check Nginx status: ${GREEN}systemctl status nginx${NC}"
echo -e "  • View Nginx logs: ${GREEN}tail -f /var/log/nginx/qr-manager-access.log${NC}"
echo -e "  • Restart Nginx: ${GREEN}systemctl restart nginx${NC}"
echo -e "  • Test config: ${GREEN}nginx -t${NC}"
echo ""

echo -e "${YELLOW}🧪 Test now:${NC}"
echo -e "  ${GREEN}curl http://localhost:8080/api/health${NC}"
echo ""

# Test
echo -e "${YELLOW}Testing...${NC}"
sleep 2
if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ QR Manager is accessible via Nginx!${NC}"
    echo ""
    curl -s http://localhost:8080/api/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8080/api/health
else
    echo -e "${RED}❌ Cannot access QR Manager. Check if Node.js app is running:${NC}"
    echo -e "  ${YELLOW}pm2 status${NC}"
    echo -e "  ${YELLOW}pm2 logs qr-manager${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Done!${NC}"

