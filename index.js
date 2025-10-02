const express = require('express');
const mongoose = require('mongoose');
const QRCode = require('qrcode');
const { nanoid } = require('nanoid');
const cors = require('cors');
const path = require('path');
const cookieParser = require('cookie-parser');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Admin passcode (from environment variables)
const ADMIN_PASSCODE = process.env.ADMIN_PASSCODE || 'Piumie2024';
const AUTH_TOKEN = 'qr_manager_authenticated';

// Middleware
app.use(cors({
    origin: true,
    credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(express.static('public'));

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/qrmanager';

// Connect to MongoDB with better error handling
mongoose.connect(MONGODB_URI, {
    serverSelectionTimeoutMS: 5000,
    socketTimeoutMS: 45000,
})
.then(() => {
    console.log('✅ Connected to MongoDB');
})
.catch(err => {
    console.error('❌ MongoDB connection error:', err.message);
});

// Middleware to check MongoDB connection
const checkDBConnection = (req, res, next) => {
    if (mongoose.connection.readyState !== 1) {
        return res.status(503).json({
            success: false,
            message: 'Database connection not ready. Please check MONGODB_URI environment variable.'
        });
    }
    next();
};

// QR Code Schema
const qrCodeSchema = new mongoose.Schema({
    title: { type: String, required: true },
    url: { type: String, required: true },
    shortlink: { type: String, required: true, unique: true },
    qrCodeData: { type: String, required: true }, // Base64 QR code image
    scanCount: { type: Number, default: 0 },
    clickCount: { type: Number, default: 0 },
    createdAt: { type: Date, default: Date.now }
});

const QRCodeModel = mongoose.model('QRCode', qrCodeSchema);

// Authentication Middleware
const requireAuth = (req, res, next) => {
    const authCookie = req.cookies.auth_token;
    if (authCookie === AUTH_TOKEN) {
        return next();
    }
    res.status(401).json({ success: false, message: 'Authentication required' });
};

// Routes

// Login page
app.get('/', (req, res) => {
    const authCookie = req.cookies.auth_token;
    if (authCookie === AUTH_TOKEN) {
        res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
    } else {
        res.sendFile(path.join(__dirname, 'public', 'login.html'));
    }
});

// Login API
app.post('/api/login', (req, res) => {
    const { passcode } = req.body;

    if (passcode === ADMIN_PASSCODE) {
        // Set cookie for authentication
        res.cookie('auth_token', AUTH_TOKEN, {
            httpOnly: true,
            maxAge: 24 * 60 * 60 * 1000, // 24 hours
            sameSite: 'lax'
        });
        res.json({ success: true, message: 'Login successful' });
    } else {
        res.status(401).json({ success: false, message: 'Mã passcode không đúng' });
    }
});

// Logout API
app.post('/api/logout', (req, res) => {
    res.clearCookie('auth_token');
    res.json({ success: true, message: 'Logged out successfully' });
});

// Check auth status
app.get('/api/auth/status', (req, res) => {
    const authCookie = req.cookies.auth_token;
    const isAuthenticated = authCookie === AUTH_TOKEN;
    res.json({
        isAuthenticated: isAuthenticated,
        username: isAuthenticated ? 'Admin' : null
    });
});

// API: Get all QR codes (protected)
app.get('/api/qrcodes', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const qrcodes = await QRCodeModel.find().sort({ createdAt: -1 });
        res.json({ success: true, data: qrcodes });
    } catch (error) {
        console.error('Error fetching QR codes:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// API: Create QR code (protected)
app.post('/api/qrcodes', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const { title, url } = req.body;

        if (!title || !url) {
            return res.status(400).json({ 
                success: false, 
                message: 'Vui lòng điền đầy đủ thông tin' 
            });
        }

        // Validate URL
        try {
            new URL(url);
        } catch (e) {
            return res.status(400).json({ 
                success: false, 
                message: 'URL không hợp lệ' 
            });
        }

        // Generate unique shortlink
        const shortlink = nanoid(6);
        const baseUrl = process.env.BASE_URL || `http://localhost:${PORT}`;
        const shortUrl = `${baseUrl}/go/${shortlink}`;

        // Generate QR code as base64
        const qrCodeData = await QRCode.toDataURL(shortUrl, {
            errorCorrectionLevel: 'H',
            type: 'image/png',
            width: 300,
            margin: 2
        });

        // Save to database
        const newQR = new QRCodeModel({
            title,
            url,
            shortlink,
            qrCodeData
        });

        await newQR.save();

        res.json({ 
            success: true, 
            message: 'Tạo QR code thành công!',
            data: newQR 
        });

    } catch (error) {
        console.error('Error creating QR code:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Lỗi: ' + error.message 
        });
    }
});

// API: Delete QR code (protected)
app.delete('/api/qrcodes/:id', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const { id } = req.params;
        const deleted = await QRCodeModel.findByIdAndDelete(id);

        if (!deleted) {
            return res.status(404).json({ 
                success: false, 
                message: 'Không tìm thấy QR code' 
            });
        }

        res.json({ 
            success: true, 
            message: 'Đã xóa thành công' 
        });

    } catch (error) {
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// API: Get statistics (protected)
app.get('/api/stats', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const totalQR = await QRCodeModel.countDocuments();
        const qrcodes = await QRCodeModel.find();
        
        const totalScans = qrcodes.reduce((sum, qr) => sum + qr.scanCount, 0);
        const totalClicks = qrcodes.reduce((sum, qr) => sum + qr.clickCount, 0);

        res.json({
            success: true,
            data: {
                totalQR,
                totalScans,
                totalClicks
            }
        });
    } catch (error) {
        console.error('Error fetching stats:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// Redirect handler - Short URL
app.get('/go/:shortlink', async (req, res) => {
    try {
        const { shortlink } = req.params;
        const source = req.query.source || 'click';

        const qrCode = await QRCodeModel.findOne({ shortlink });

        if (!qrCode) {
            return res.status(404).send(`
                <!DOCTYPE html>
                <html>
                <head>
                    <title>404 - Not Found</title>
                    <style>
                        body {
                            font-family: Arial, sans-serif;
                            text-align: center;
                            padding: 50px;
                            background: #f5f7fa;
                        }
                        h1 { color: #e74c3c; }
                        a {
                            display: inline-block;
                            margin-top: 20px;
                            padding: 10px 20px;
                            background: #3498db;
                            color: white;
                            text-decoration: none;
                            border-radius: 5px;
                        }
                    </style>
                </head>
                <body>
                    <h1>404 - Không tìm thấy</h1>
                    <p>Short URL này không tồn tại hoặc đã bị xóa.</p>
                    <a href="/">← Quay lại trang chủ</a>
                </body>
                </html>
            `);
        }

        // Update counter
        if (source === 'qr') {
            qrCode.scanCount += 1;
        } else {
            qrCode.clickCount += 1;
        }
        await qrCode.save();

        // Redirect to original URL
        res.redirect(301, qrCode.url);

    } catch (error) {
        console.error('Redirect error:', error);
        res.status(500).send('Error: ' + error.message);
    }
});

// Health check
app.get('/api/health', (req, res) => {
    res.json({ 
        success: true, 
        message: 'QR Code Manager is running!',
        mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
    });
});

// Start server (only for local development)
if (process.env.NODE_ENV !== 'production') {
    app.listen(PORT, () => {
        console.log(`🚀 Server running on port ${PORT}`);
        console.log(`📱 Visit: http://localhost:${PORT}`);
    });
}

// Export for Vercel
module.exports = app;
