#!/bin/bash

# Script kiểm tra cấu trúc thư mục trên VPS

echo "🔍 Checking server structure..."
echo ""

echo "1️⃣ Checking /home/piumie.com/html/"
if [ -d "/home/piumie.com/html/" ]; then
    echo "✅ Directory exists"
    echo "📁 Contents:"
    ls -lah /home/piumie.com/html/ | head -20
else
    echo "❌ Directory NOT found"
fi

echo ""
echo "2️⃣ Checking /home/piumie.com/"
if [ -d "/home/piumie.com/" ]; then
    echo "✅ Directory exists"
    echo "📁 Contents:"
    ls -lah /home/piumie.com/
else
    echo "❌ Directory NOT found"
fi

echo ""
echo "3️⃣ Checking OpenLiteSpeed Virtual Hosts:"
if [ -d "/usr/local/lsws/conf/vhosts/" ]; then
    echo "📁 Virtual Hosts:"
    ls -la /usr/local/lsws/conf/vhosts/
    
    echo ""
    echo "4️⃣ Checking piumie.com config:"
    if [ -f "/usr/local/lsws/conf/vhosts/piumie.com/vhconf.conf" ]; then
        echo "📄 Document Root:"
        grep -i "docRoot" /usr/local/lsws/conf/vhosts/piumie.com/vhconf.conf
    else
        echo "❌ Config file not found"
    fi
fi

echo ""
echo "5️⃣ Finding all piumie.com related directories:"
find /home -name "*piumie*" -type d 2>/dev/null

echo ""
echo "6️⃣ Checking common web directories:"
for dir in "/var/www/html" "/var/www/piumie.com" "/usr/local/lsws/DEFAULT/html" "/home/piumie.com/public_html" "/home/piumie.com/html" "/home/piumie.com/www"; do
    if [ -d "$dir" ]; then
        echo "✅ Found: $dir"
        ls -lah "$dir" | head -5
    fi
done

echo ""
echo "7️⃣ Checking PHP:"
php -v 2>/dev/null || echo "❌ PHP not installed"

echo ""
echo "8️⃣ Checking PostgreSQL:"
systemctl status postgresql 2>/dev/null | head -3 || echo "❌ PostgreSQL not running"

echo ""
echo "✅ Check complete!"

