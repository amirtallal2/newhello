<?php

declare(strict_types=1);

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';
$uri = $uri === '' ? '/' : $uri;
$file = __DIR__ . $uri;

if (str_starts_with($uri, '/app-assets/')) {
    $relativePath = substr($uri, strlen('/app-assets/'));
    $assetsBase = realpath(dirname(__DIR__) . '/assets');
    $assetPath = realpath(dirname(__DIR__) . '/assets/' . $relativePath);

    if ($assetsBase !== false && $assetPath !== false && str_starts_with($assetPath, $assetsBase) && is_file($assetPath)) {
        $extension = strtolower(pathinfo($assetPath, PATHINFO_EXTENSION));
        $contentTypes = [
            'css' => 'text/css; charset=utf-8',
            'js' => 'application/javascript; charset=utf-8',
            'png' => 'image/png',
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'webp' => 'image/webp',
            'svg' => 'image/svg+xml',
            'gif' => 'image/gif',
            'mp3' => 'audio/mpeg',
            'mpeg' => 'audio/mpeg',
            'wav' => 'audio/wav',
            'ogg' => 'audio/ogg',
            'ico' => 'image/x-icon',
        ];

        if (isset($contentTypes[$extension])) {
            header('Content-Type: ' . $contentTypes[$extension]);
        }

        readfile($assetPath);
        return true;
    }
}

if ($uri !== '/' && is_dir($file) && is_file(rtrim($file, '/') . '/index.php')) {
    require rtrim($file, '/') . '/index.php';
    return true;
}

if ($uri !== '/' && is_file($file)) {
    $extension = strtolower(pathinfo($file, PATHINFO_EXTENSION));
    $contentTypes = [
        'css' => 'text/css; charset=utf-8',
        'js' => 'application/javascript; charset=utf-8',
        'png' => 'image/png',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        'svg' => 'image/svg+xml',
        'gif' => 'image/gif',
        'json' => 'application/json; charset=utf-8',
        'mp3' => 'audio/mpeg',
        'mpeg' => 'audio/mpeg',
        'wav' => 'audio/wav',
        'ogg' => 'audio/ogg',
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

if ($uri === '/' || $uri === '/admin' || $uri === '/admin/') {
    require __DIR__ . '/admin/index.php';
    return true;
}

http_response_code(404);
echo 'Not Found';
