<?php
// QR Manager Entry Point
// Access via: https://piumie.com/qr-manager.php

require_once 'config.php';

// Check if authenticated
if (isAuthenticated()) {
    include 'dashboard.html';
} else {
    include 'login.html';
}

