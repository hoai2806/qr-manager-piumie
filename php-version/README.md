# 🎯 QR Manager - PHP Version

## ✨ Tính năng

- ✅ **Chạy trực tiếp trên OpenLiteSpeed** (như PHP thông thường)
- ✅ **Không cần Node.js, PM2, Nginx**
- ✅ **PostgreSQL database**
- ✅ **Tùy chỉnh màu sắc QR code**
- ✅ **Tùy chỉnh màu nền**
- ✅ **Upload logo**
- ✅ **Chọn vị trí logo**
- ✅ **Tùy chỉnh kích thước**
- ✅ **Thống kê scan/click**
- ✅ **Authentication với passcode**

---

## 🚀 Cài đặt nhanh

### Bước 1: SSH vào server

```bash
ssh root@15.235.192.138
# Password: HiPP2003
```

### Bước 2: Chạy script cài đặt

```bash
curl -fsSL https://raw.githubusercontent.com/hoai2806/qr-manager-piumie/main/php-version/install.sh | bash
```

### Bước 3: Cấu hình OpenLiteSpeed

1. Login: `https://15.235.192.138:7080`
2. **Virtual Hosts** → **piumie.com** → **Context** → **Add**
3. **Type:** `Static`
4. **URI:** `/qr`
5. **Location:** `/home/piumie.com/html/qr/php-version/`
6. **Accessible:** `Yes`
7. **Graceful Restart**

### Bước 4: Truy cập

```
https://piumie.com/qr
```

**Passcode:** `Piumie2024`

---

## 📋 Yêu cầu hệ thống

- PHP >= 7.4
- PostgreSQL >= 12
- PHP Extensions:
  - pdo_pgsql
  - gd
  - mbstring
  - curl
- Composer

---

## 🎨 Tính năng tạo QR Code

### Form tạo QR Code bao gồm:

1. **Tiêu đề** - Tên QR code
2. **URL đích** - Link redirect
3. **Kích thước** - 100-1000px
4. **Màu QR Code** - Color picker
5. **Màu nền** - Color picker
6. **Logo** - Upload ảnh (JPG/PNG/GIF, max 2MB)
7. **Vị trí logo** - Giữa/Trên/Dưới

---

## 📁 Cấu trúc thư mục

```
php-version/
├── index.php           # Entry point
├── config.php          # Configuration & database
├── api.php             # API endpoints
├── redirect.php        # Short URL redirect
├── login.html          # Login page
├── dashboard.html      # Dashboard
├── .htaccess           # URL rewriting
├── composer.json       # Dependencies
├── uploads/
│   ├── logos/          # Uploaded logos
│   └── qrcodes/        # Generated QR codes
└── vendor/             # Composer packages
```

---

## 🔧 Cấu hình

Edit `config.php`:

```php
define('DB_HOST', 'localhost');
define('DB_PORT', '5432');
define('DB_NAME', 'qrmanager');
define('DB_USER', 'qrmanager_user');
define('DB_PASS', 'Piumie2024QR');
define('ADMIN_PASSCODE', 'Piumie2024');
define('BASE_URL', 'https://piumie.com/qr');
```

---

## 🗄️ Database Schema

```sql
CREATE TABLE qrcodes (
    id SERIAL PRIMARY KEY,
    short_code VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    original_url TEXT NOT NULL,
    qr_image TEXT NOT NULL,
    logo_path VARCHAR(255),
    qr_size INTEGER DEFAULT 300,
    qr_color VARCHAR(7) DEFAULT '#000000',
    qr_bg_color VARCHAR(7) DEFAULT '#FFFFFF',
    logo_position VARCHAR(20) DEFAULT 'center',
    scan_count INTEGER DEFAULT 0,
    click_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🌐 API Endpoints

### Authentication

- `POST /api.php/login` - Login
- `POST /api.php/logout` - Logout
- `GET /api.php/auth/status` - Check auth status

### QR Codes

- `GET /api.php/qrcodes` - Get all QR codes
- `POST /api.php/qrcodes` - Create QR code
- `PUT /api.php/qrcodes/:id` - Update QR code
- `DELETE /api.php/qrcodes/:id` - Delete QR code

### Stats

- `GET /api.php/stats` - Get statistics

### Redirect

- `GET /:shortCode` - Redirect to original URL

---

## 🧪 Test

```bash
# Health check
curl https://piumie.com/qr/

# API test
curl https://piumie.com/qr/api.php/stats
```

---

## 🔄 Update

```bash
cd /home/piumie.com/html/qr/php-version
git pull origin main
composer install --no-dev
```

---

## 🐛 Troubleshooting

### Lỗi: Database connection failed

```bash
# Check PostgreSQL
systemctl status postgresql

# Check connection
sudo -u postgres psql -d qrmanager -c "SELECT 1"
```

### Lỗi: Permission denied

```bash
cd /home/piumie.com/html/qr/php-version
chmod -R 755 .
chown -R nobody:nogroup .
chmod 755 uploads uploads/logos uploads/qrcodes
```

### Lỗi: Composer not found

```bash
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
```

---

## 📊 So sánh với Node.js version

| Feature | PHP Version | Node.js Version |
|---------|-------------|-----------------|
| **Chạy trên OLS** | ✅ Trực tiếp | ❌ Cần proxy |
| **Cài đặt** | ✅ Đơn giản | ❌ Phức tạp |
| **Dependencies** | ✅ Ít | ❌ Nhiều |
| **Performance** | ⚡ Tốt | ⚡⚡ Rất tốt |
| **Memory** | 💾 Thấp | 💾 Cao hơn |
| **Maintenance** | ✅ Dễ | ❌ Khó hơn |

---

## 🎉 Ưu điểm PHP version

1. ✅ **Chạy trực tiếp** trên OpenLiteSpeed (như PHP thông thường)
2. ✅ **Không cần** Node.js, PM2, Nginx
3. ✅ **Đơn giản** hơn nhiều
4. ✅ **Ít lỗi** hơn
5. ✅ **Dễ maintain** hơn
6. ✅ **Tích hợp** tốt với OpenLiteSpeed

---

## 📞 Support

Nếu có vấn đề:

```bash
# Check PHP error log
tail -f /var/log/php-error.log

# Check OpenLiteSpeed error log
tail -f /usr/local/lsws/logs/error.log

# Check PostgreSQL log
tail -f /var/log/postgresql/postgresql-*.log
```

---

## 🔐 Security

- ✅ Session-based authentication
- ✅ SQL injection protection (PDO prepared statements)
- ✅ XSS protection (htmlspecialchars)
- ✅ File upload validation
- ✅ HTTP-only cookies

---

## 📝 License

MIT License

---

## 🎯 Kết luận

**PHP version là lựa chọn tốt nhất cho OpenLiteSpeed!**

- Đơn giản
- Dễ cài đặt
- Dễ maintain
- Chạy trực tiếp (không cần proxy)

