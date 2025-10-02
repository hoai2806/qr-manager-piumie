# OpenLiteSpeed Configuration Guide

## 🔧 Cấu hình OpenLiteSpeed để proxy sang Node.js

### **Phương án 1: Proxy toàn bộ subdomain qr.piumie.com**

#### Bước 1: Tạo Virtual Host mới

1. Login vào OpenLiteSpeed WebAdmin: `https://15.235.192.138:7080`
2. Vào **Virtual Hosts** → Click **Add**
3. Điền thông tin:
   - **Virtual Host Name:** `qr.piumie.com`
   - **Virtual Host Root:** `/home/piumie.com/html/qr-manager/`
   - **Config File:** `$SERVER_ROOT/conf/vhosts/qr.piumie.com/vhconf.conf`
   - **Enable Scripts/ExtApps:** `Yes`
   - Click **Save**

#### Bước 2: Tạo External App (Node.js)

1. Vào **Server Configuration** → **External App** → Click **Add**
2. Chọn **Type:** `Web Server`
3. Điền thông tin:
   - **Name:** `qr-manager-node`
   - **Address:** `http://127.0.0.1:3000`
   - **Max Connections:** `100`
   - **Initial Request Timeout:** `60`
   - **Retry Timeout:** `0`
   - Click **Save**

#### Bước 3: Tạo Context cho Virtual Host

1. Vào **Virtual Hosts** → **qr.piumie.com** → **Context** → Click **Add**
2. Chọn **Type:** `Proxy`
3. Điền thông tin:
   - **URI:** `/`
   - **Web Server Type:** `External`
   - **Web Server:** `[Server Level]: qr-manager-node`
   - Click **Save**

#### Bước 4: Cấu hình Listener

1. Vào **Listeners** → **Default** (hoặc listener của bạn)
2. Vào tab **Virtual Host Mappings** → Click **Add**
3. Điền:
   - **Virtual Host:** `qr.piumie.com`
   - **Domains:** `qr.piumie.com`
   - Click **Save**

#### Bước 5: Graceful Restart

```bash
sudo systemctl restart lsws
```

hoặc click **Actions** → **Graceful Restart** trong WebAdmin

---

### **Phương án 2: Proxy path /qr trên piumie.com**

#### Bước 1: Tạo External App (giống trên)

1. **Server Configuration** → **External App** → **Add**
2. **Type:** `Web Server`
3. **Name:** `qr-manager-node`
4. **Address:** `http://127.0.0.1:3000`
5. **Save**

#### Bước 2: Thêm Context vào Virtual Host hiện tại

1. Vào **Virtual Hosts** → **piumie.com** → **Context** → **Add**
2. **Type:** `Proxy`
3. **URI:** `/qr`
4. **Web Server Type:** `External`
5. **Web Server:** `[Server Level]: qr-manager-node`
6. **Save**

#### Bước 3: Graceful Restart

```bash
sudo systemctl restart lsws
```

---

## 🧪 Test

### Test local:
```bash
curl http://localhost:3000/api/health
```

### Test qua OpenLiteSpeed:

**Phương án 1:**
```bash
curl https://qr.piumie.com/api/health
```

**Phương án 2:**
```bash
curl https://piumie.com/qr/api/health
```

---

## 📝 Troubleshooting

### Lỗi 503 Service Unavailable

**Kiểm tra Node.js có chạy không:**
```bash
pm2 status
pm2 logs qr-manager
```

**Kiểm tra port 3000:**
```bash
netstat -tulpn | grep 3000
```

**Restart PM2:**
```bash
pm2 restart qr-manager
```

### Lỗi 404 Not Found

**Kiểm tra Context URI:**
- Đảm bảo URI trong Context khớp với URL bạn truy cập
- Nếu dùng `/qr` thì phải truy cập `https://piumie.com/qr`

### Lỗi Connection Refused

**Kiểm tra External App Address:**
- Phải là `http://127.0.0.1:3000` (không phải `localhost`)
- Kiểm tra Node.js có listen đúng port không

---

## 🔒 SSL/HTTPS

Nếu dùng subdomain `qr.piumie.com`, cần tạo SSL certificate:

```bash
# Cài Certbot
apt-get install certbot

# Tạo certificate
certbot certonly --webroot -w /home/piumie.com/html/qr-manager/public -d qr.piumie.com

# Certificate sẽ ở: /etc/letsencrypt/live/qr.piumie.com/
```

Sau đó config SSL trong OpenLiteSpeed:
1. **Virtual Hosts** → **qr.piumie.com** → **SSL**
2. **Private Key File:** `/etc/letsencrypt/live/qr.piumie.com/privkey.pem`
3. **Certificate File:** `/etc/letsencrypt/live/qr.piumie.com/fullchain.pem`
4. **Save** và **Graceful Restart**

---

## 🎯 Recommended: Phương án 1 (Subdomain)

**Ưu điểm:**
- ✅ URL đẹp: `https://qr.piumie.com`
- ✅ Tách biệt hoàn toàn với site chính
- ✅ Dễ quản lý SSL
- ✅ Không conflict với routes khác

**Nhược điểm:**
- ❌ Cần config DNS cho subdomain
- ❌ Cần SSL certificate riêng

---

## 📋 DNS Configuration (nếu dùng subdomain)

Thêm A record:
```
Type: A
Name: qr
Value: 15.235.192.138
TTL: 3600
```

Hoặc CNAME:
```
Type: CNAME
Name: qr
Value: piumie.com
TTL: 3600
```

