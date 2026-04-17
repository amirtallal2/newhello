<?php

declare(strict_types=1);

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';
$file = __DIR__ . $uri;

if ($uri !== '/' && is_file($file)) {
    $extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    $contentTypes = [
        'css' => 'text/css; charset=utf-8',
        'js' => 'application/javascript; charset=utf-8',
        'png' => 'image/png',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'svg' => 'image/svg+xml',
        'ico' => 'image/x-icon',
    ];

    if (isset($contentTypes[$extension])) {
        header('Content-Type: ' . $contentTypes[$extension]);
        readfile($file);
        return true;
    }

    require $file;
    return true;
}

if (str_starts_with($uri, '/api')) {
    require __DIR__ . '/api/index.php';
    return true;
}

if ($uri === '/' || $uri === '/admin') {
    require __DIR__ . '/admin/index.php';
    return true;
}

http_response_code(404);
echo 'Not Found';
