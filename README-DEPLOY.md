# 🚀 QR Manager - Deployment Guide

## 📋 Thông tin Server

- **IP:** 15.235.192.138
- **User:** root
- **Password:** HiPP2003
- **Deploy Path:** /root/qr-manager
- **Port:** 5000
- **Database:** PostgreSQL (port 5432)

---

## 🔥 Cài đặt nhanh (1 lệnh)

SSH vào server và chạy:

```bash
cd /root && curl -fsSL https://raw.githubusercontent.com/hoai2806/qr-manager-piumie/main/install-on-server.sh | bash
```

**Hoặc:**

```bash
cd /root
git clone https://github.com/hoai2806/qr-manager-piumie.git qr-manager
cd qr-manager
bash install-on-server.sh
```

---

## 📦 Script sẽ tự động:

1. ✅ Cài Node.js 18.x
2. ✅ Cài PM2 (process manager)
3. ✅ Cài PostgreSQL
4. ✅ Tạo database `qrmanager`
5. ✅ Tạo user `qrmanager_user`
6. ✅ Clone code từ GitHub
7. ✅ Install dependencies
8. ✅ Tạo file .env
9. ✅ Start app với PM2
10. ✅ Setup auto-restart

---

## 🔧 Cấu hình Nginx Reverse Proxy

### Bước 1: Cài Nginx (nếu chưa có)

```bash
apt-get update
apt-get install -y nginx
```

### Bước 2: Tạo config cho subdomain

```bash
nano /etc/nginx/sites-available/qr.piumie.com
```

**Nội dung:**

```nginx
server {
    listen 80;
    server_name qr.piumie.com;
    
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
```

### Bước 3: Enable site

```bash
ln -s /etc/nginx/sites-available/qr.piumie.com /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### Bước 4: Setup SSL (Let's Encrypt)

```bash
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d qr.piumie.com
```

---

## 🌐 Cấu hình DNS

Thêm A record vào DNS của domain:

```
Type: A
Name: qr
Value: 15.235.192.138
TTL: 3600
```

---

## 🧪 Test

### 1. Test local trên server:

```bash
curl http://localhost:5000/api/health
```

**Kết quả mong đợi:**
```json
{
  "success": true,
  "message": "QR Code Manager is running!",
  "database": "connected",
  "port": 5000
}
```

### 2. Test qua domain:

```bash
curl https://qr.piumie.com/api/health
```

---

## 📝 Quản lý PM2

### Xem status:
```bash
pm2 status
```

### Xem logs:
```bash
pm2 logs qr-manager
pm2 logs qr-manager --lines 100
```

### Restart:
```bash
pm2 restart qr-manager
```

### Stop:
```bash
pm2 stop qr-manager
```

### Start:
```bash
pm2 start qr-manager
```

### Monitor real-time:
```bash
pm2 monit
```

### Xem thông tin chi tiết:
```bash
pm2 show qr-manager
```

---

## 🗄️ Quản lý PostgreSQL

### Kết nối database:
```bash
sudo -u postgres psql -d qrmanager
```

### Xem tables:
```sql
\dt
```

### Xem dữ liệu:
```sql
SELECT * FROM qrcodes;
```

### Backup database:
```bash
sudo -u postgres pg_dump qrmanager > backup.sql
```

### Restore database:
```bash
sudo -u postgres psql qrmanager < backup.sql
```

---

## 🔄 Update code

```bash
cd /root/qr-manager
git pull origin main
npm install
pm2 restart qr-manager
```

---

## 🔐 Thông tin đăng nhập

- **URL:** https://qr.piumie.com
- **Passcode:** Piumie2024

---

## 🐛 Troubleshooting

### Lỗi: Application not responding

```bash
# Check PM2 status
pm2 status

# Check logs
pm2 logs qr-manager --lines 50

# Restart
pm2 restart qr-manager
```

### Lỗi: Database connection failed

```bash
# Check PostgreSQL status
systemctl status postgresql

# Restart PostgreSQL
systemctl restart postgresql

# Check connection
sudo -u postgres psql -c "SELECT 1"
```

### Lỗi: Port 5000 already in use

```bash
# Find process using port 5000
lsof -i :5000

# Kill process
kill -9 <PID>

# Restart app
pm2 restart qr-manager
```

### Lỗi: Nginx 502 Bad Gateway

```bash
# Check if app is running
curl http://localhost:5000/api/health

# Check Nginx error log
tail -f /var/log/nginx/error.log

# Restart Nginx
systemctl restart nginx
```

---

## 📊 Monitoring

### Check system resources:
```bash
pm2 monit
```

### Check disk space:
```bash
df -h
```

### Check memory:
```bash
free -h
```

### Check CPU:
```bash
top
```

---

## 🔒 Security

### Firewall (UFW):
```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 22/tcp
ufw enable
```

### Đổi PostgreSQL password:
```bash
sudo -u postgres psql
ALTER USER qrmanager_user WITH PASSWORD 'new_password';
```

Nhớ update trong file `.env`:
```bash
nano /root/qr-manager/.env
# Sửa DATABASE_URL
pm2 restart qr-manager
```

---

## 📞 Support

Nếu có vấn đề, check logs:

```bash
# PM2 logs
pm2 logs qr-manager

# Nginx logs
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log

# PostgreSQL logs
tail -f /var/log/postgresql/postgresql-*.log
```

---

## 🎉 Done!

Application đang chạy tại: **https://qr.piumie.com**

Passcode: **Piumie2024**

