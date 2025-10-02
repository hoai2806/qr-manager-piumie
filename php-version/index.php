<?php
require_once 'config.php';

// Check if authenticated
if (isAuthenticated()) {
    include 'dashboard.html';
} else {
    include 'login.html';
}

