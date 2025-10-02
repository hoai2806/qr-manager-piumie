const express = require('express');
const mongoose = require('mongoose');
const QRCode = require('qrcode');
const { nanoid } = require('nanoid');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static('public'));

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/qrmanager';

// Connect to MongoDB (non-blocking)
mongoose.connect(MONGODB_URI)
    .then(() => {
        console.log('✅ Connected to MongoDB');
    })
    .catch(err => {
        console.error('❌ MongoDB connection error:', err);
        // Don't exit - let serverless function handle it
    });

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

// Routes

// Home page - Serve HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API: Get all QR codes
app.get('/api/qrcodes', async (req, res) => {
    try {
        const qrcodes = await QRCodeModel.find().sort({ createdAt: -1 });
        res.json({ success: true, data: qrcodes });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// API: Create QR code
app.post('/api/qrcodes', async (req, res) => {
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

// API: Delete QR code
app.delete('/api/qrcodes/:id', async (req, res) => {
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

// API: Get statistics
app.get('/api/stats', async (req, res) => {
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
