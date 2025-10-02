const express = require('express');
const { Pool } = require('pg');
const QRCode = require('qrcode');
const { nanoid } = require('nanoid');
const cors = require('cors');
const path = require('path');
const cookieParser = require('cookie-parser');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;

// Admin passcode
const ADMIN_PASSCODE = process.env.ADMIN_PASSCODE || 'Piumie2024';
const AUTH_TOKEN = 'qr_manager_authenticated';

// PostgreSQL connection
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
    if (err) {
        console.error('❌ PostgreSQL connection error:', err.message);
    } else {
        console.log('✅ Connected to PostgreSQL');
    }
});

// Create tables if not exists
const initDatabase = async () => {
    const createTableQuery = `
        CREATE TABLE IF NOT EXISTS qrcodes (
            id SERIAL PRIMARY KEY,
            short_code VARCHAR(20) UNIQUE NOT NULL,
            title VARCHAR(255) NOT NULL,
            original_url TEXT NOT NULL,
            qr_image TEXT NOT NULL,
            scan_count INTEGER DEFAULT 0,
            click_count INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE INDEX IF NOT EXISTS idx_short_code ON qrcodes(short_code);
        CREATE INDEX IF NOT EXISTS idx_created_at ON qrcodes(created_at DESC);
    `;
    
    try {
        await pool.query(createTableQuery);
        console.log('✅ Database tables initialized');
    } catch (error) {
        console.error('❌ Error initializing database:', error.message);
    }
};

initDatabase();

// Middleware
app.use(cors({
    origin: true,
    credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(express.static('public'));

// Authentication Middleware
const requireAuth = (req, res, next) => {
    const authCookie = req.cookies.auth_token;
    if (authCookie === AUTH_TOKEN) {
        return next();
    }
    res.status(401).json({ success: false, message: 'Authentication required' });
};

// Middleware to check DB connection
const checkDBConnection = async (req, res, next) => {
    try {
        await pool.query('SELECT 1');
        next();
    } catch (error) {
        res.status(503).json({ 
            success: false, 
            message: 'Database connection not ready' 
        });
    }
};

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
        res.cookie('auth_token', AUTH_TOKEN, {
            httpOnly: true,
            maxAge: 24 * 60 * 60 * 1000,
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

// API: Get all QR codes
app.get('/api/qrcodes', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT * FROM qrcodes ORDER BY created_at DESC'
        );
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('Error fetching QR codes:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// API: Create QR code
app.post('/api/qrcodes', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const { title, url } = req.body;

        if (!title || !url) {
            return res.status(400).json({ 
                success: false, 
                message: 'Title and URL are required' 
            });
        }

        // Validate URL
        try {
            new URL(url);
        } catch (e) {
            return res.status(400).json({ 
                success: false, 
                message: 'Invalid URL format' 
            });
        }

        // Generate short code
        const shortCode = nanoid(8);
        const shortUrl = `${process.env.BASE_URL || 'http://localhost:' + PORT}/${shortCode}`;

        // Generate QR code
        const qrImage = await QRCode.toDataURL(shortUrl, {
            errorCorrectionLevel: 'H',
            type: 'image/png',
            quality: 0.95,
            margin: 1,
            width: 512,
            color: {
                dark: '#000000',
                light: '#FFFFFF'
            }
        });

        // Save to database
        const result = await pool.query(
            `INSERT INTO qrcodes (short_code, title, original_url, qr_image) 
             VALUES ($1, $2, $3, $4) 
             RETURNING *`,
            [shortCode, title, url, qrImage]
        );

        res.json({ 
            success: true, 
            message: 'QR Code created successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating QR code:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// API: Update QR code
app.put('/api/qrcodes/:id', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const { id } = req.params;
        const { title, url, isActive } = req.body;

        const result = await pool.query(
            `UPDATE qrcodes 
             SET title = COALESCE($1, title),
                 original_url = COALESCE($2, original_url),
                 is_active = COALESCE($3, is_active),
                 updated_at = CURRENT_TIMESTAMP
             WHERE id = $4
             RETURNING *`,
            [title, url, isActive, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'QR Code not found' 
            });
        }

        res.json({ 
            success: true, 
            message: 'QR Code updated successfully',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error updating QR code:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// API: Delete QR code
app.delete('/api/qrcodes/:id', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const { id } = req.params;
        
        const result = await pool.query(
            'DELETE FROM qrcodes WHERE id = $1 RETURNING *',
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ 
                success: false, 
                message: 'QR Code not found' 
            });
        }

        res.json({ 
            success: true, 
            message: 'QR Code deleted successfully' 
        });
    } catch (error) {
        console.error('Error deleting QR code:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// API: Get statistics
app.get('/api/stats', requireAuth, checkDBConnection, async (req, res) => {
    try {
        const totalResult = await pool.query('SELECT COUNT(*) as count FROM qrcodes');
        const scansResult = await pool.query('SELECT SUM(scan_count) as total FROM qrcodes');
        const clicksResult = await pool.query('SELECT SUM(click_count) as total FROM qrcodes');

        res.json({
            success: true,
            data: {
                totalQR: parseInt(totalResult.rows[0].count),
                totalScans: parseInt(scansResult.rows[0].total) || 0,
                totalClicks: parseInt(clicksResult.rows[0].total) || 0
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

// Redirect short URL
app.get('/:shortCode', async (req, res) => {
    try {
        const { shortCode } = req.params;

        const result = await pool.query(
            'SELECT * FROM qrcodes WHERE short_code = $1 AND is_active = true',
            [shortCode]
        );

        if (result.rows.length === 0) {
            return res.status(404).send('QR Code not found or inactive');
        }

        const qrcode = result.rows[0];

        // Update click count
        await pool.query(
            'UPDATE qrcodes SET click_count = click_count + 1 WHERE id = $1',
            [qrcode.id]
        );

        // Redirect
        res.redirect(qrcode.original_url);
    } catch (error) {
        console.error('Error redirecting:', error);
        res.status(500).send('Server error');
    }
});

// Health check
app.get('/api/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({ 
            success: true, 
            message: 'QR Code Manager is running!',
            database: 'connected',
            port: PORT
        });
    } catch (error) {
        res.json({ 
            success: true, 
            message: 'QR Code Manager is running!',
            database: 'disconnected',
            port: PORT
        });
    }
});

// Start server
if (process.env.NODE_ENV !== 'production') {
    app.listen(PORT, () => {
        console.log(`🚀 Server running on port ${PORT}`);
        console.log(`📱 Visit: http://localhost:${PORT}`);
    });
}

module.exports = app;

