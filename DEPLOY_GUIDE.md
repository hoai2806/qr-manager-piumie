# 🚀 Hướng dẫn Deploy Nhanh - 10 phút

## ✅ Checklist trước khi bắt đầu

- [ ] Có tài khoản GitHub (đăng ký miễn phí tại github.com)
- [ ] Có quyền quản lý DNS của piumie.com
- [ ] Đã cài Git trên máy

---

## 📋 Bước 1: Setup MongoDB (3 phút)

### 1.1. Tạo tài khoản MongoDB Atlas

1. Truy cập: **https://www.mongodb.com/cloud/atlas**
2. Click **"Try Free"**
3. Đăng ký với email (hoặc Google)

### 1.2. Tạo Cluster

1. Sau khi đăng nhập, click **"Build a Database"**
2. Chọn **"FREE"** (M0 Sandbox)
3. Chọn Provider: **AWS**
4. Chọn Region: **Singapore** (ap-southeast-1)
5. Cluster Name: `qr-manager`
6. Click **"Create"**

### 1.3. Tạo Database User

1. Trong màn hình Security Quickstart:
   - Username: `qrmanager`
   - Password: Click **"Autogenerate Secure Password"** → **Copy password** (LƯU LẠI!)
   - Click **"Create User"**

### 1.4. Whitelist IP

1. Trong màn hình "Where would you like to connect from?":
   - Click **"Add My Current IP Address"**
   - Hoặc click **"Add a Different IP Address"**
   - Nhập: `0.0.0.0/0` (Allow from anywhere)
   - Click **"Add Entry"**
2. Click **"Finish and Close"**

### 1.5. Lấy Connection String

1. Click **"Connect"**
2. Chọn **"Drivers"**
3. Copy connection string:
   ```
   mongodb+srv://qrmanager:<password>@qr-manager.xxxxx.mongodb.net/?retryWrites=true&w=majority
   ```
4. Thay `<password>` bằng password bạn đã copy ở bước 1.3
5. **LƯU LẠI connection string này!**

---

## 📋 Bước 2: Push code lên GitHub (2 phút)

### 2.1. Tạo repository mới

1. Truy cập: **https://github.com/new**
2. Repository name: `qr-manager-piumie`
3. Description: `QR Code Manager for piumie.com`
4. Chọn **Public**
5. Click **"Create repository"**

### 2.2. Push code

Mở Terminal/Command Prompt, chạy:

```bash
cd qr-manager-vercel
git init
git add .
git commit -m "Initial commit - QR Manager for piumie.com"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/qr-manager-piumie.git
git push -u origin main
```

**Thay `YOUR_USERNAME` bằng username GitHub của bạn!**

---

## 📋 Bước 3: Deploy lên Vercel (3 phút)

### 3.1. Đăng ký Vercel

1. Truy cập: **https://vercel.com/signup**
2. Click **"Continue with GitHub"**
3. Authorize Vercel

### 3.2. Import Project

1. Trong Vercel Dashboard, click **"Add New..."** → **"Project"**
2. Tìm repository `qr-manager-piumie`
3. Click **"Import"**

### 3.3. Configure Project

1. **Project Name:** `qr-manager-piumie` (hoặc tên khác)
2. **Framework Preset:** Other
3. **Root Directory:** `./`
4. **Build Command:** (để trống)
5. **Output Directory:** (để trống)
6. **Install Command:** `npm install`

### 3.4. Add Environment Variables

Click **"Environment Variables"**, thêm:

**Variable 1:**
- Name: `MONGODB_URI`
- Value: (paste connection string từ bước 1.5)

**Variable 2:**
- Name: `BASE_URL`
- Value: `https://qr-manager-piumie.vercel.app` (tạm thời, sẽ đổi sau)

### 3.5. Deploy

1. Click **"Deploy"**
2. Đợi 1-2 phút
3. Thấy "🎉 Congratulations!" → Click **"Visit"**
4. Test trang web: Tạo QR code thử

---

## 📋 Bước 4: Trỏ domain qr.piumie.com (2 phút)

### 4.1. Add Domain trong Vercel

1. Trong Vercel project, click **"Settings"**
2. Click **"Domains"** (menu bên trái)
3. Nhập: `qr.piumie.com`
4. Click **"Add"**

### 4.2. Vercel sẽ hiển thị DNS records

Bạn sẽ thấy:
```
Type: CNAME
Name: qr
Value: cname.vercel-dns.com
```

### 4.3. Thêm CNAME record vào DNS của piumie.com

**Nếu dùng Cloudflare:**
1. Đăng nhập Cloudflare
2. Chọn domain `piumie.com`
3. Vào **DNS** → **Records**
4. Click **"Add record"**
5. Điền:
   - Type: `CNAME`
   - Name: `qr`
   - Target: `cname.vercel-dns.com`
   - Proxy status: **DNS only** (tắt cloud màu cam)
6. Click **"Save"**

**Nếu dùng cPanel:**
1. Đăng nhập cPanel
2. Vào **Zone Editor**
3. Tìm domain `piumie.com`
4. Click **"+ Add Record"** → **"Add CNAME Record"**
5. Điền:
   - Name: `qr`
   - CNAME: `cname.vercel-dns.com`
6. Click **"Add Record"**

**Nếu dùng nhà cung cấp khác:**
- Tìm phần **DNS Management** hoặc **DNS Settings**
- Thêm CNAME record như trên

### 4.4. Cập nhật BASE_URL

1. Quay lại Vercel project
2. Click **"Settings"** → **"Environment Variables"**
3. Tìm `BASE_URL`
4. Click **"Edit"**
5. Đổi thành: `https://qr.piumie.com`
6. Click **"Save"**
7. Click **"Redeploy"** để apply changes

### 4.5. Đợi DNS propagate

- Đợi 5-10 phút
- Thử truy cập: **https://qr.piumie.com**
- Nếu chưa được, đợi thêm 10-20 phút

---

## ✅ Hoàn tất!

Bây giờ bạn có:

- ✅ **Trang quản lý:** https://qr.piumie.com
- ✅ **Database:** MongoDB Atlas (miễn phí)
- ✅ **Hosting:** Vercel (miễn phí)
- ✅ **SSL:** Tự động (miễn phí)
- ✅ **Short URL:** https://qr.piumie.com/go/abc123

---

## 🧪 Test hệ thống

1. Truy cập: https://qr.piumie.com
2. Click **"Tạo QR Code Mới"**
3. Nhập:
   - Tiêu đề: `Test QR`
   - URL: `https://google.com`
4. Click **"Tạo QR Code"**
5. QR code sẽ hiển thị
6. Copy short URL
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

# Vercel sẽ tự động deploy lại!
```

---

## 🆘 Nếu gặp lỗi

### Lỗi: "Cannot connect to MongoDB"
→ Kiểm tra:
- Connection string có đúng không
- Password có đúng không
- IP whitelist có `0.0.0.0/0` chưa

### Lỗi: "qr.piumie.com not found"
→ Kiểm tra:
- CNAME record đã thêm đúng chưa
- Đợi thêm 10-20 phút
- Thử clear DNS cache

### Lỗi: "Build failed"
→ Kiểm tra:
- Vercel logs (Deployments → View Function Logs)
- Environment variables đã thêm đúng chưa

---

## 📞 Cần hỗ trợ?

1. Check Vercel logs: Project → Deployments → Logs
2. Check MongoDB: Atlas → Metrics
3. Test API: https://qr.piumie.com/api/health

---

**Chúc bạn deploy thành công! 🎉**
