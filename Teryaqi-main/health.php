<?php
// فحص سريع: بدون MySQL — افتح من متصفح المحاكي: http://10.0.2.2:8080/health.php
header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
http_response_code(200);
echo json_encode(['ok' => true, 'php' => PHP_VERSION]);
