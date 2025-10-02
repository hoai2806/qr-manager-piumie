<?php
require_once 'config.php';
require_once 'vendor/autoload.php';

use Endroid\QrCode\QrCode;
use Endroid\QrCode\Writer\PngWriter;
use Endroid\QrCode\Color\Color;
use Endroid\QrCode\Logo\Logo;
use Endroid\QrCode\Label\Label;

header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];
$path = $_SERVER['PATH_INFO'] ?? '/';

// Router
switch ($path) {
    case '/login':
        if ($method === 'POST') {
            handleLogin();
        }
        break;
        
    case '/logout':
        if ($method === 'POST') {
            handleLogout();
        }
        break;
        
    case '/auth/status':
        handleAuthStatus();
        break;
        
    case '/qrcodes':
        requireAuth();
        if ($method === 'GET') {
            getQRCodes();
        } elseif ($method === 'POST') {
            createQRCode();
        }
        break;
        
    case '/stats':
        requireAuth();
        getStats();
        break;
        
    default:
        // Handle /qrcodes/:id
        if (preg_match('#^/qrcodes/(\d+)$#', $path, $matches)) {
            requireAuth();
            $id = $matches[1];
            if ($method === 'PUT') {
                updateQRCode($id);
            } elseif ($method === 'DELETE') {
                deleteQRCode($id);
            }
        } else {
            jsonResponse(['success' => false, 'message' => 'Not found'], 404);
        }
}

// API Handlers
function handleLogin() {
    $data = json_decode(file_get_contents('php://input'), true);
    $passcode = $data['passcode'] ?? '';
    
    if ($passcode === ADMIN_PASSCODE) {
        $_SESSION['authenticated'] = true;
        $_SESSION['username'] = 'Admin';
        jsonResponse(['success' => true, 'message' => 'Login successful']);
    } else {
        jsonResponse(['success' => false, 'message' => 'Mã passcode không đúng'], 401);
    }
}

function handleLogout() {
    session_destroy();
    jsonResponse(['success' => true, 'message' => 'Logged out successfully']);
}

function handleAuthStatus() {
    jsonResponse([
        'isAuthenticated' => isAuthenticated(),
        'username' => isAuthenticated() ? 'Admin' : null
    ]);
}

function getQRCodes() {
    $db = getDB();
    $stmt = $db->query("SELECT * FROM qrcodes ORDER BY created_at DESC");
    $qrcodes = $stmt->fetchAll();
    
    jsonResponse(['success' => true, 'data' => $qrcodes]);
}

function createQRCode() {
    $title = sanitizeInput($_POST['title'] ?? '');
    $url = sanitizeInput($_POST['url'] ?? '');
    $qrSize = (int)($_POST['qr_size'] ?? 300);
    $qrColor = sanitizeInput($_POST['qr_color'] ?? '#000000');
    $qrBgColor = sanitizeInput($_POST['qr_bg_color'] ?? '#FFFFFF');
    $logoPosition = sanitizeInput($_POST['logo_position'] ?? 'center');
    
    if (empty($title) || empty($url)) {
        jsonResponse(['success' => false, 'message' => 'Title and URL are required'], 400);
    }
    
    if (!filter_var($url, FILTER_VALIDATE_URL)) {
        jsonResponse(['success' => false, 'message' => 'Invalid URL format'], 400);
    }
    
    // Generate short code
    $shortCode = generateShortCode();
    $shortUrl = BASE_URL . '/' . $shortCode;
    
    // Handle logo upload
    $logoPath = null;
    if (isset($_FILES['logo']) && $_FILES['logo']['error'] === UPLOAD_ERR_OK) {
        $logoPath = handleLogoUpload($_FILES['logo']);
    }
    
    // Generate QR Code
    try {
        $qrImage = generateQRCodeImage($shortUrl, $qrSize, $qrColor, $qrBgColor, $logoPath, $logoPosition);
        
        // Save to database
        $db = getDB();
        $stmt = $db->prepare("
            INSERT INTO qrcodes (short_code, title, original_url, qr_image, logo_path, qr_size, qr_color, qr_bg_color, logo_position)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            RETURNING *
        ");
        
        $stmt->execute([
            $shortCode,
            $title,
            $url,
            $qrImage,
            $logoPath,
            $qrSize,
            $qrColor,
            $qrBgColor,
            $logoPosition
        ]);
        
        $qrcode = $stmt->fetch();
        
        jsonResponse([
            'success' => true,
            'message' => 'QR Code created successfully',
            'data' => $qrcode
        ]);
    } catch (Exception $e) {
        jsonResponse(['success' => false, 'message' => $e->getMessage()], 500);
    }
}

function updateQRCode($id) {
    $data = json_decode(file_get_contents('php://input'), true);
    
    $title = sanitizeInput($data['title'] ?? '');
    $url = sanitizeInput($data['url'] ?? '');
    $isActive = isset($data['isActive']) ? (bool)$data['isActive'] : null;
    
    $db = getDB();
    $stmt = $db->prepare("
        UPDATE qrcodes 
        SET title = COALESCE(?, title),
            original_url = COALESCE(?, original_url),
            is_active = COALESCE(?, is_active),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
        RETURNING *
    ");
    
    $stmt->execute([$title ?: null, $url ?: null, $isActive, $id]);
    $qrcode = $stmt->fetch();
    
    if (!$qrcode) {
        jsonResponse(['success' => false, 'message' => 'QR Code not found'], 404);
    }
    
    jsonResponse([
        'success' => true,
        'message' => 'QR Code updated successfully',
        'data' => $qrcode
    ]);
}

function deleteQRCode($id) {
    $db = getDB();
    $stmt = $db->prepare("DELETE FROM qrcodes WHERE id = ? RETURNING *");
    $stmt->execute([$id]);
    $qrcode = $stmt->fetch();
    
    if (!$qrcode) {
        jsonResponse(['success' => false, 'message' => 'QR Code not found'], 404);
    }
    
    // Delete logo file if exists
    if ($qrcode['logo_path'] && file_exists(UPLOAD_DIR . $qrcode['logo_path'])) {
        unlink(UPLOAD_DIR . $qrcode['logo_path']);
    }
    
    jsonResponse(['success' => true, 'message' => 'QR Code deleted successfully']);
}

function getStats() {
    $db = getDB();
    
    $totalQR = $db->query("SELECT COUNT(*) as count FROM qrcodes")->fetch()['count'];
    $totalScans = $db->query("SELECT SUM(scan_count) as total FROM qrcodes")->fetch()['total'] ?? 0;
    $totalClicks = $db->query("SELECT SUM(click_count) as total FROM qrcodes")->fetch()['total'] ?? 0;
    
    jsonResponse([
        'success' => true,
        'data' => [
            'totalQR' => (int)$totalQR,
            'totalScans' => (int)$totalScans,
            'totalClicks' => (int)$totalClicks
        ]
    ]);
}

function handleLogoUpload($file) {
    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
    $maxSize = 2 * 1024 * 1024; // 2MB
    
    if (!in_array($file['type'], $allowedTypes)) {
        throw new Exception('Invalid file type. Only JPG, PNG, GIF allowed.');
    }
    
    if ($file['size'] > $maxSize) {
        throw new Exception('File too large. Max 2MB.');
    }
    
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = uniqid('logo_') . '.' . $extension;
    $destination = UPLOAD_DIR . $filename;
    
    if (!move_uploaded_file($file['tmp_name'], $destination)) {
        throw new Exception('Failed to upload logo');
    }
    
    return $filename;
}

function generateQRCodeImage($data, $size, $color, $bgColor, $logoPath, $logoPosition) {
    // Parse colors
    list($r, $g, $b) = sscanf($color, "#%02x%02x%02x");
    $foregroundColor = new Color($r, $g, $b);
    
    list($r, $g, $b) = sscanf($bgColor, "#%02x%02x%02x");
    $backgroundColor = new Color($r, $g, $b);
    
    // Create QR Code
    $qrCode = QrCode::create($data)
        ->setSize($size)
        ->setMargin(10)
        ->setForegroundColor($foregroundColor)
        ->setBackgroundColor($backgroundColor);
    
    $writer = new PngWriter();
    
    // Add logo if provided
    $logo = null;
    if ($logoPath && file_exists(UPLOAD_DIR . $logoPath)) {
        $logoSize = (int)($size * 0.2); // Logo is 20% of QR size
        $logo = Logo::create(UPLOAD_DIR . $logoPath)
            ->setResizeToWidth($logoSize);
    }
    
    $result = $writer->write($qrCode, $logo);
    
    // Save to file
    $filename = uniqid('qr_') . '.png';
    $filepath = QR_DIR . $filename;
    $result->saveToFile($filepath);
    
    // Return as data URL for database
    return $result->getDataUri();
}

