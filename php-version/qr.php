<?php
/**
 * QR Manager - All-in-One File
 * Upload file này vào /home/piumie.com/html/qr.php
 * Truy cập: https://piumie.com/qr.php
 */

session_start();

// Configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'qrmanager');
define('DB_USER', 'qrmanager_user');
define('DB_PASS', 'Piumie2024QR');
define('ADMIN_PASSCODE', 'Piumie2024');
define('BASE_URL', 'https://piumie.com');

// Database connection
function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                "pgsql:host=" . DB_HOST . ";dbname=" . DB_NAME,
                DB_USER,
                DB_PASS,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );
        } catch (PDOException $e) {
            die("Database error: " . $e->getMessage());
        }
    }
    return $pdo;
}

// Initialize database
function initDB() {
    $db = getDB();
    $db->exec("
        CREATE TABLE IF NOT EXISTS qrcodes (
            id SERIAL PRIMARY KEY,
            short_code VARCHAR(20) UNIQUE NOT NULL,
            title VARCHAR(255) NOT NULL,
            original_url TEXT NOT NULL,
            qr_image TEXT NOT NULL,
            qr_size INTEGER DEFAULT 300,
            qr_color VARCHAR(7) DEFAULT '#000000',
            qr_bg_color VARCHAR(7) DEFAULT '#FFFFFF',
            scan_count INTEGER DEFAULT 0,
            click_count INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ");
}

initDB();

// Check authentication
function isAuth() {
    return isset($_SESSION['auth']) && $_SESSION['auth'] === true;
}

// Handle actions
$action = $_GET['action'] ?? 'dashboard';

// API Actions
if ($action === 'login' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    if (($data['passcode'] ?? '') === ADMIN_PASSCODE) {
        $_SESSION['auth'] = true;
        die(json_encode(['success' => true]));
    }
    die(json_encode(['success' => false, 'message' => 'Sai passcode']));
}

if ($action === 'logout') {
    session_destroy();
    header('Location: ?');
    exit;
}

if ($action === 'api_stats' && isAuth()) {
    $db = getDB();
    $total = $db->query("SELECT COUNT(*) as c FROM qrcodes")->fetch()['c'];
    $scans = $db->query("SELECT SUM(scan_count) as s FROM qrcodes")->fetch()['s'] ?? 0;
    $clicks = $db->query("SELECT SUM(click_count) as c FROM qrcodes")->fetch()['c'] ?? 0;
    die(json_encode(['success' => true, 'data' => ['totalQR' => (int)$total, 'totalScans' => (int)$scans, 'totalClicks' => (int)$clicks]]));
}

if ($action === 'api_list' && isAuth()) {
    $db = getDB();
    $stmt = $db->query("SELECT * FROM qrcodes ORDER BY created_at DESC");
    die(json_encode(['success' => true, 'data' => $stmt->fetchAll()]));
}

if ($action === 'api_create' && isAuth() && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $title = $_POST['title'] ?? '';
    $url = $_POST['url'] ?? '';
    $size = (int)($_POST['qr_size'] ?? 300);
    $color = $_POST['qr_color'] ?? '#000000';
    $bgcolor = $_POST['qr_bg_color'] ?? '#FFFFFF';
    
    if (empty($title) || empty($url)) {
        die(json_encode(['success' => false, 'message' => 'Thiếu thông tin']));
    }
    
    $code = substr(md5(uniqid()), 0, 8);
    $shortUrl = BASE_URL . '/?r=' . $code;
    
    // Generate QR using Google Charts API (simple, no dependencies)
    $qrUrl = "https://chart.googleapis.com/chart?chs={$size}x{$size}&cht=qr&chl=" . urlencode($shortUrl) . "&choe=UTF-8";
    $qrImage = file_get_contents($qrUrl);
    $qrDataUrl = 'data:image/png;base64,' . base64_encode($qrImage);
    
    $db = getDB();
    $stmt = $db->prepare("INSERT INTO qrcodes (short_code, title, original_url, qr_image, qr_size, qr_color, qr_bg_color) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING *");
    $stmt->execute([$code, $title, $url, $qrDataUrl, $size, $color, $bgcolor]);
    
    die(json_encode(['success' => true, 'data' => $stmt->fetch()]));
}

if ($action === 'api_delete' && isAuth() && $_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? 0;
    $db = getDB();
    $db->prepare("DELETE FROM qrcodes WHERE id = ?")->execute([$id]);
    die(json_encode(['success' => true]));
}

// Redirect short URL
if (isset($_GET['r'])) {
    $code = $_GET['r'];
    $db = getDB();
    $stmt = $db->prepare("SELECT * FROM qrcodes WHERE short_code = ? AND is_active = true");
    $stmt->execute([$code]);
    $qr = $stmt->fetch();
    
    if ($qr) {
        $db->prepare("UPDATE qrcodes SET click_count = click_count + 1 WHERE id = ?")->execute([$qr['id']]);
        header('Location: ' . $qr['original_url']);
        exit;
    }
    die('QR Code not found');
}

// Show UI
if (!isAuth()) {
    // Login page
    ?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QR Manager - Login</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .login-box { background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }
        h1 { text-align: center; margin-bottom: 30px; color: #2c3e50; }
        input { width: 100%; padding: 12px; border: 2px solid #e0e0e0; border-radius: 8px; font-size: 16px; margin-bottom: 20px; }
        button { width: 100%; padding: 14px; background: #3498db; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; }
        button:hover { background: #2980b9; }
        .error { color: red; text-align: center; margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class="login-box">
        <h1>🎯 QR Manager</h1>
        <div id="error" class="error"></div>
        <form id="loginForm">
            <input type="password" id="passcode" placeholder="Nhập passcode" required>
            <button type="submit">Đăng nhập</button>
        </form>
    </div>
    <script>
        document.getElementById('loginForm').onsubmit = async (e) => {
            e.preventDefault();
            const res = await fetch('?action=login', {
                method: 'POST',
                body: JSON.stringify({ passcode: document.getElementById('passcode').value })
            });
            const data = await res.json();
            if (data.success) location.reload();
            else document.getElementById('error').textContent = data.message;
        };
    </script>
</body>
</html>
    <?php
    exit;
}

// Dashboard
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>QR Manager - Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1400px; margin: 0 auto; }
        .header { background: white; padding: 20px; border-radius: 12px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .stat-card { background: white; padding: 20px; border-radius: 12px; }
        .stat-card h3 { color: #7f8c8d; font-size: 14px; margin-bottom: 10px; }
        .stat-card .value { font-size: 32px; font-weight: bold; color: #2c3e50; }
        .form-box { background: white; padding: 30px; border-radius: 12px; margin-bottom: 20px; }
        .form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: 500; }
        .form-group input, .form-group select { width: 100%; padding: 10px; border: 2px solid #e0e0e0; border-radius: 8px; }
        .form-group input[type="color"] { height: 50px; }
        button { padding: 12px 24px; background: #3498db; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; }
        button:hover { background: #2980b9; }
        .btn-logout { background: #e74c3c; }
        .btn-logout:hover { background: #c0392b; }
        .qr-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
        .qr-card { background: white; padding: 20px; border-radius: 12px; }
        .qr-card img { width: 100%; border-radius: 8px; margin-bottom: 10px; }
        .qr-card h3 { margin-bottom: 10px; }
        .qr-card .url { color: #7f8c8d; font-size: 14px; word-break: break-all; margin-bottom: 10px; }
        .qr-card .actions { display: flex; gap: 10px; }
        .btn-delete { background: #e74c3c; flex: 1; }
        .btn-download { background: #27ae60; flex: 1; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎯 QR Manager</h1>
            <a href="?action=logout"><button class="btn-logout">Đăng xuất</button></a>
        </div>
        
        <div class="stats">
            <div class="stat-card"><h3>Tổng QR</h3><div class="value" id="totalQR">0</div></div>
            <div class="stat-card"><h3>Tổng Scan</h3><div class="value" id="totalScans">0</div></div>
            <div class="stat-card"><h3>Tổng Click</h3><div class="value" id="totalClicks">0</div></div>
        </div>
        
        <div class="form-box">
            <h2>➕ Tạo QR Code</h2>
            <form id="createForm">
                <div class="form-grid">
                    <div class="form-group"><label>Tiêu đề *</label><input name="title" required></div>
                    <div class="form-group"><label>URL *</label><input name="url" type="url" required></div>
                    <div class="form-group"><label>Kích thước (px)</label><input name="qr_size" type="number" value="300" min="100" max="1000"></div>
                </div>
                <div class="form-grid">
                    <div class="form-group"><label>Màu QR Code</label><input name="qr_color" type="color" value="#000000"></div>
                    <div class="form-group"><label>Màu nền</label><input name="qr_bg_color" type="color" value="#FFFFFF"></div>
                </div>
                <button type="submit">🎨 Tạo QR Code</button>
            </form>
        </div>
        
        <div class="form-box">
            <h2>📋 Danh sách QR Code</h2>
            <div id="qrList" class="qr-grid"></div>
        </div>
    </div>
    
    <script>
        async function loadStats() {
            const res = await fetch('?action=api_stats');
            const data = await res.json();
            if (data.success) {
                document.getElementById('totalQR').textContent = data.data.totalQR;
                document.getElementById('totalScans').textContent = data.data.totalScans;
                document.getElementById('totalClicks').textContent = data.data.totalClicks;
            }
        }
        
        async function loadList() {
            const res = await fetch('?action=api_list');
            const data = await res.json();
            if (data.success) {
                document.getElementById('qrList').innerHTML = data.data.map(qr => `
                    <div class="qr-card">
                        <img src="${qr.qr_image}" alt="${qr.title}">
                        <h3>${qr.title}</h3>
                        <div class="url">${qr.original_url}</div>
                        <div>👁️ ${qr.scan_count} | 🖱️ ${qr.click_count}</div>
                        <div class="actions">
                            <button class="btn-download" onclick="download('${qr.qr_image}', '${qr.title}')">⬇️ Tải</button>
                            <button class="btn-delete" onclick="deleteQR(${qr.id})">🗑️ Xóa</button>
                        </div>
                    </div>
                `).join('');
            }
        }
        
        document.getElementById('createForm').onsubmit = async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const res = await fetch('?action=api_create', { method: 'POST', body: formData });
            const data = await res.json();
            if (data.success) {
                e.target.reset();
                loadStats();
                loadList();
            } else {
                alert(data.message);
            }
        };
        
        async function deleteQR(id) {
            if (!confirm('Xóa QR code này?')) return;
            const formData = new FormData();
            formData.append('id', id);
            await fetch('?action=api_delete', { method: 'POST', body: formData });
            loadStats();
            loadList();
        }
        
        function download(dataUrl, title) {
            const a = document.createElement('a');
            a.href = dataUrl;
            a.download = `qr-${title}.png`;
            a.click();
        }
        
        loadStats();
        loadList();
    </script>
</body>
</html>

