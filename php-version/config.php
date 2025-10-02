<?php
// Database Configuration
define('DB_HOST', 'localhost');
define('DB_PORT', '5432');
define('DB_NAME', 'qrmanager');
define('DB_USER', 'qrmanager_user');
define('DB_PASS', 'Piumie2024QR');

// Admin Configuration
define('ADMIN_PASSCODE', 'Piumie2024');

// Base URL
define('BASE_URL', 'https://qr.piumie.com');

// Upload Directory
define('UPLOAD_DIR', __DIR__ . '/uploads/logos/');
define('UPLOAD_URL', '/uploads/logos/');

// QR Code Directory
define('QR_DIR', __DIR__ . '/uploads/qrcodes/');
define('QR_URL', '/uploads/qrcodes/');

// Session Configuration
ini_set('session.cookie_httponly', 1);
ini_set('session.use_strict_mode', 1);
session_start();

// Database Connection
function getDB() {
    static $pdo = null;
    
    if ($pdo === null) {
        try {
            $dsn = sprintf(
                "pgsql:host=%s;port=%s;dbname=%s",
                DB_HOST,
                DB_PORT,
                DB_NAME
            );
            
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false
            ]);
        } catch (PDOException $e) {
            die(json_encode([
                'success' => false,
                'message' => 'Database connection failed: ' . $e->getMessage()
            ]));
        }
    }
    
    return $pdo;
}

// Create directories if not exist
if (!file_exists(UPLOAD_DIR)) {
    mkdir(UPLOAD_DIR, 0755, true);
}

if (!file_exists(QR_DIR)) {
    mkdir(QR_DIR, 0755, true);
}

// Initialize database tables
function initDatabase() {
    $db = getDB();
    
    $sql = "
    CREATE TABLE IF NOT EXISTS qrcodes (
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
    
    CREATE INDEX IF NOT EXISTS idx_short_code ON qrcodes(short_code);
    CREATE INDEX IF NOT EXISTS idx_created_at ON qrcodes(created_at DESC);
    ";
    
    try {
        $db->exec($sql);
    } catch (PDOException $e) {
        error_log("Database init error: " . $e->getMessage());
    }
}

initDatabase();

// Helper Functions
function isAuthenticated() {
    return isset($_SESSION['authenticated']) && $_SESSION['authenticated'] === true;
}

function requireAuth() {
    if (!isAuthenticated()) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Authentication required']);
        exit;
    }
}

function jsonResponse($data, $statusCode = 200) {
    http_response_code($statusCode);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

function generateShortCode($length = 8) {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $code = '';
    for ($i = 0; $i < $length; $i++) {
        $code .= $characters[random_int(0, strlen($characters) - 1)];
    }
    return $code;
}

function sanitizeInput($data) {
    return htmlspecialchars(strip_tags(trim($data)), ENT_QUOTES, 'UTF-8');
}

