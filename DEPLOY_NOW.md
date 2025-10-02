# 🚀 Deploy Ngay - Chỉ còn 2 bước!

## ✅ Đã hoàn thành:

- ✅ Code đã được push lên GitHub: https://github.com/hoai2806/qr-manager-piumie
- ✅ MongoDB credentials đã có sẵn
- ✅ Tất cả files đã sẵn sàng

---

## 📋 Bước 1: Deploy lên Vercel (3 phút)

### 1.1. Đăng nhập Vercel

1. Truy cập: **https://vercel.com/signup**
2. Click **"Continue with GitHub"**
3. Authorize Vercel (cho phép Vercel truy cập GitHub)

### 1.2. Import Project

1. Trong Vercel Dashboard, click **"Add New..."** → **"Project"**
2. Tìm repository: **qr-manager-piumie**
3. Click **"Import"**

### 1.3. Configure Project

**Project Settings:**
- **Project Name:** `qr-manager-piumie` (hoặc tên khác bạn thích)
- **Framework Preset:** Other
- **Root Directory:** `./`
- **Build Command:** (để trống)
- **Output Directory:** (để trống)
- **Install Command:** `npm install`

### 1.4. Add Environment Variables

Click **"Environment Variables"**, thêm 2 biến:

**Variable 1:**
```
Name: MONGODB_URI
Value: mongodb+srv://cvhoai_db_user:Ry5Z62YUprIYexWp@cluster.mongodb.net/qrmanager?retryWrites=true&w=majority
```

**Variable 2:**
```
Name: BASE_URL
Value: https://qr-manager-piumie.vercel.app
```

⚠️ **Lưu ý:** Nếu MongoDB cluster của bạn có tên khác, thay `cluster` bằng tên cluster thực tế (ví dụ: `cluster0.xxxxx`)

### 1.5. Deploy

1. Click **"Deploy"**
2. Đợi 1-2 phút
3. Thấy "🎉 Congratulations!" → Click **"Visit"**
4. Test trang web: Tạo QR code thử

**URL tạm thời:** `https://qr-manager-piumie.vercel.app`

---

## 📋 Bước 2: Trỏ domain qr.piumie.com (2 phút)

### 2.1. Add Domain trong Vercel

1. Trong Vercel project, click **"Settings"** (menu trên)
2. Click **"Domains"** (menu bên trái)
3. Nhập: `qr.piumie.com`
4. Click **"Add"**

### 2.2. Lấy DNS Records

Vercel sẽ hiển thị:
```
Type: CNAME
Name: qr
Value: cname.vercel-dns.com
```

### 2.3. Thêm CNAME vào DNS của piumie.com

**Nếu dùng Cloudflare:**
1. Đăng nhập Cloudflare
2. Chọn domain `piumie.com`
3. Vào **DNS** → **Records**
4. Click **"Add record"**
5. Điền:
   - **Type:** CNAME
   - **Name:** qr
   - **Target:** cname.vercel-dns.com
   - **Proxy status:** DNS only (tắt cloud màu cam)
   - **TTL:** Auto
6. Click **"Save"**

**Nếu dùng cPanel:**
1. Đăng nhập cPanel
2. Vào **Zone Editor**
3. Tìm domain `piumie.com`
4. Click **"+ Add Record"** → **"Add CNAME Record"**
5. Điền:
   - **Name:** qr
   - **CNAME:** cname.vercel-dns.com
   - **TTL:** 14400
6. Click **"Add Record"**

**Nếu dùng nhà cung cấp khác:**
- Tìm phần **DNS Management** hoặc **DNS Settings**
- Thêm CNAME record như trên

### 2.4. Cập nhật BASE_URL

1. Quay lại Vercel project
2. Click **"Settings"** → **"Environment Variables"**
3. Tìm `BASE_URL`
4. Click **"Edit"** (icon bút chì)
5. Đổi value thành: `https://qr.piumie.com`
6. Click **"Save"**
7. Vào tab **"Deployments"**
8. Click **"..."** ở deployment mới nhất → **"Redeploy"**

### 2.5. Đợi DNS Propagate

- Đợi 5-10 phút
- Thử truy cập: **https://qr.piumie.com**
- Nếu chưa được, đợi thêm 10-20 phút (DNS cần thời gian)

---

## ✅ Hoàn tất!

Bây giờ bạn có:

- ✅ **Trang quản lý:** https://qr.piumie.com
- ✅ **GitHub repo:** https://github.com/hoai2806/qr-manager-piumie
- ✅ **Database:** MongoDB Atlas (miễn phí)
- ✅ **Hosting:** Vercel (miễn phí)
- ✅ **SSL:** Tự động (miễn phí)

---

## 🧪 Test hệ thống

1. Truy cập: **https://qr.piumie.com**
2. Click **"Tạo QR Code Mới"**
3. Nhập:
   - **Tiêu đề:** Test QR
   - **URL:** https://google.com
4. Click **"Tạo QR Code"**
5. QR code sẽ hiển thị
6. Copy short URL (dạng: `https://qr.piumie.com/go/abc123`)
7. Mở tab mới, paste short URL
8. Kiểm tra redirect tới Google
9. Quay lại trang quản lý, xem số lượt click tăng

---

## 🔄 Update code sau này

Khi bạn muốn sửa code:

```bash
# Sửa code trong qr-manager-vercel/

# Commit và push
git add .
git commit -m "Update: mô tả thay đổi"
git push

# Vercel sẽ tự động deploy lại trong 1-2 phút!
```

---

## 🆘 Nếu gặp lỗi

### Lỗi: "Cannot connect to MongoDB"

**Nguyên nhân:** Connection string sai hoặc IP chưa được whitelist

**Giải pháp:**
1. Vào MongoDB Atlas: https://cloud.mongodb.com
2. Chọn cluster của bạn
3. Click **"Network Access"** (menu bên trái)
4. Kiểm tra có IP `0.0.0.0/0` chưa
5. Nếu chưa có, click **"Add IP Address"** → **"Allow Access from Anywhere"**
6. Quay lại Vercel, click **"Redeploy"**

### Lỗi: "qr.piumie.com not found"

**Nguyên nhân:** DNS chưa propagate hoặc CNAME record sai

**Giải pháp:**
1. Kiểm tra CNAME record đã thêm đúng chưa
2. Đợi thêm 10-20 phút
3. Thử clear DNS cache:
   - Windows: `ipconfig /flushdns`
   - Mac: `sudo dscacheutil -flushcache`
4. Thử truy cập bằng 4G/5G (không dùng WiFi)

### Lỗi: "Build failed" trong Vercel

**Nguyên nhân:** Thiếu dependencies hoặc code lỗi

**Giải pháp:**
1. Vào Vercel project → **"Deployments"**
2. Click vào deployment failed
3. Click **"View Function Logs"**
4. Xem lỗi cụ thể
5. Fix code và push lại

### Lỗi: "QR code không hiển thị"

**Nguyên nhân:** MongoDB chưa kết nối hoặc data chưa lưu

**Giải pháp:**
1. Mở Developer Tools (F12)
2. Vào tab **Console**
3. Xem có lỗi gì không
4. Thử tạo QR code mới
5. Check API: https://qr.piumie.com/api/health

---

## 📞 Cần hỗ trợ?

### Check logs:
- **Vercel logs:** Project → Deployments → View Function Logs
- **Browser console:** F12 → Console tab
- **MongoDB logs:** Atlas → Metrics

### Test API:
```
https://qr.piumie.com/api/health
https://qr.piumie.com/api/stats
https://qr.piumie.com/api/qrcodes
```

---

## 🎯 URLs quan trọng:

- **Trang chủ:** https://qr.piumie.com
- **GitHub:** https://github.com/hoai2806/qr-manager-piumie
- **Vercel Dashboard:** https://vercel.com/dashboard
- **MongoDB Atlas:** https://cloud.mongodb.com

---

## 💡 Tips:

1. **Bookmark các URLs** để dễ truy cập
2. **Enable notifications** trong Vercel để nhận thông báo khi deploy
3. **Backup MongoDB** định kỳ (Atlas có auto backup)
4. **Monitor usage** trong Vercel Dashboard

---

## 🎉 Chúc mừng!

Bạn đã có một hệ thống QR Code Manager chuyên nghiệp:
- ✅ Miễn phí 100%
- ✅ SSL tự động
- ✅ Deploy tự động
- ✅ Scalable & Fast
- ✅ Professional domain

**Enjoy! 🚀**
