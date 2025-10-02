# 🎯 QR Code Manager - Vercel Edition

QR Code & Shortlink Manager cho piumie.com - Deploy lên Vercel với subdomain `qr.piumie.com`

## ✨ Tính năng

- ✅ Tạo QR code từ URL
- ✅ Tạo shortlink tự động (6 ký tự)
- ✅ Theo dõi lượt quét QR và click link
- ✅ Giao diện đẹp, responsive
- ✅ Deploy miễn phí lên Vercel
- ✅ Database MongoDB Atlas (miễn phí)
- ✅ SSL tự động
- ✅ Custom domain: qr.piumie.com

## 🚀 Hướng dẫn Deploy (10 phút)

### Bước 1: Tạo MongoDB Database (3 phút)

1. Truy cập: https://www.mongodb.com/cloud/atlas
2. Click **"Try Free"** → Đăng ký tài khoản (miễn phí)
3. Tạo cluster mới:
   - Chọn **FREE** tier (M0)
   - Chọn region gần Việt Nam (Singapore)
   - Click **"Create"**
4. Tạo database user:
   - Username: `qrmanager`
   - Password: (tạo password mạnh, lưu lại)
5. Whitelist IP:
   - Click **"Network Access"**
   - Click **"Add IP Address"**
   - Chọn **"Allow Access from Anywhere"** (0.0.0.0/0)
6. Lấy connection string:
   - Click **"Connect"**
   - Chọn **"Connect your application"**
   - Copy connection string:
     ```
     mongodb+srv://qrmanager:<password>@cluster.mongodb.net/qrmanager?retryWrites=true&w=majority
     ```
   - Thay `<password>` bằng password bạn vừa tạo

### Bước 2: Push code lên GitHub (2 phút)

1. Tạo repository mới trên GitHub:
   - Tên: `qr-manager-piumie`
   - Public hoặc Private đều được

2. Push code:
   ```bash
   cd qr-manager-vercel
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/qr-manager-piumie.git
   git push -u origin main
   ```

### Bước 3: Deploy lên Vercel (3 phút)

1. Truy cập: https://vercel.com
2. Click **"Sign Up"** → Đăng nhập bằng GitHub
3. Click **"New Project"**
4. Import repository `qr-manager-piumie`
5. Configure project:
   - **Framework Preset:** Other
   - **Build Command:** (để trống)
   - **Output Directory:** (để trống)
6. Add Environment Variables:
   - Click **"Environment Variables"**
   - Thêm:
     ```
     MONGODB_URI = mongodb+srv://qrmanager:YOUR_PASSWORD@cluster.mongodb.net/qrmanager
     BASE_URL = https://qr-manager-piumie.vercel.app
     ```
7. Click **"Deploy"**
8. Đợi 1-2 phút → Xong!

### Bước 4: Trỏ domain qr.piumie.com (2 phút)

1. Trong Vercel project, click **"Settings"** → **"Domains"**
2. Thêm domain: `qr.piumie.com`
3. Vercel sẽ cho bạn DNS records:
   ```
   Type: CNAME
   Name: qr
   Value: cname.vercel-dns.com
   ```
4. Vào quản lý DNS của piumie.com (nơi bạn mua domain)
5. Thêm CNAME record như trên
6. Đợi 5-10 phút → Xong!

## 🎯 URLs

- **Vercel URL:** https://qr-manager-piumie.vercel.app
- **Custom Domain:** https://qr.piumie.com (sau khi setup DNS)
- **Short URL:** https://qr.piumie.com/go/abc123

## 🧪 Test Local

```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env and add your MONGODB_URI

# Run locally
npm start

# Visit
open http://localhost:3000
```

## 📁 Cấu trúc dự án

```
qr-manager-vercel/
├── index.js              # Server Node.js + Express
├── public/
│   └── index.html        # Frontend HTML
├── package.json          # Dependencies
├── vercel.json           # Vercel config
├── .env.example          # Environment variables template
└── README.md             # This file
```

## 🔧 API Endpoints

### GET /
- Trang chủ (HTML)

### GET /api/qrcodes
- Lấy tất cả QR codes

### POST /api/qrcodes
- Tạo QR code mới
- Body: `{ title, url }`

### DELETE /api/qrcodes/:id
- Xóa QR code

### GET /api/stats
- Lấy thống kê

### GET /go/:shortlink
- Redirect shortlink

### GET /api/health
- Health check

## 🛠️ Tech Stack

- **Backend:** Node.js + Express
- **Database:** MongoDB Atlas
- **QR Generation:** qrcode library
- **Shortlink:** nanoid
- **Hosting:** Vercel
- **Domain:** qr.piumie.com

## 💰 Chi phí

- ✅ **Vercel:** Miễn phí (Hobby plan)
- ✅ **MongoDB Atlas:** Miễn phí (M0 tier - 512MB)
- ✅ **Domain:** Đã có sẵn (piumie.com)
- ✅ **SSL:** Miễn phí tự động

**Tổng: $0/tháng** 🎉

## 🔒 Bảo mật

- ✅ HTTPS tự động
- ✅ Environment variables
- ✅ CORS enabled
- ✅ Input validation
- ✅ MongoDB connection secured

## 📊 Giới hạn (Free tier)

- **Vercel:** 100GB bandwidth/tháng
- **MongoDB:** 512MB storage (~10,000 QR codes)
- **Requests:** Unlimited

## 🆘 Troubleshooting

### Lỗi: "Cannot connect to MongoDB"
- Kiểm tra connection string trong Environment Variables
- Kiểm tra IP whitelist trong MongoDB Atlas
- Kiểm tra password có đúng không

### Lỗi: "Domain not working"
- Đợi 5-10 phút để DNS propagate
- Kiểm tra CNAME record đã thêm đúng chưa
- Thử clear DNS cache: `ipconfig /flushdns` (Windows) hoặc `sudo dscacheutil -flushcache` (Mac)

### Lỗi: "Build failed"
- Kiểm tra package.json có đúng không
- Kiểm tra Node version >= 14
- Xem build logs trong Vercel

## 📞 Support

Nếu gặp vấn đề:
1. Check Vercel logs: Project → Deployments → View Function Logs
2. Check MongoDB logs: Atlas → Metrics
3. Test API: https://qr.piumie.com/api/health

## 🎉 Hoàn tất!

Sau khi deploy xong, bạn có:
- ✅ Trang quản lý QR: https://qr.piumie.com
- ✅ API endpoints
- ✅ Database MongoDB
- ✅ SSL miễn phí
- ✅ Auto deploy khi push code

**Chúc bạn sử dụng thành công! 🚀**
