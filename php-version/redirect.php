<?php
require_once 'config.php';

$shortCode = $_GET['code'] ?? '';

if (empty($shortCode)) {
    http_response_code(404);
    die('QR Code not found');
}

try {
    $db = getDB();
    $stmt = $db->prepare("SELECT * FROM qrcodes WHERE short_code = ? AND is_active = true");
    $stmt->execute([$shortCode]);
    $qrcode = $stmt->fetch();
    
    if (!$qrcode) {
        http_response_code(404);
        die('QR Code not found or inactive');
    }
    
    // Update click count
    $updateStmt = $db->prepare("UPDATE qrcodes SET click_count = click_count + 1 WHERE id = ?");
    $updateStmt->execute([$qrcode['id']]);
    
    // Redirect
    header('Location: ' . $qrcode['original_url']);
    exit;
    
} catch (Exception $e) {
    http_response_code(500);
    die('Server error');
}

