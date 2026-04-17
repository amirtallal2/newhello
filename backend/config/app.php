<?php

declare(strict_types=1);

return [
    'app_name' => 'Voice Live Backend',
    'api_base_path' => '/api',
    'db' => [
        'driver' => getenv('APP_DB_DRIVER') ?: 'mysql',
        'host' => getenv('DB_HOST') ?: '127.0.0.1',
        'port' => (int) (getenv('DB_PORT') ?: '3306'),
        'database' => getenv('DB_DATABASE') ?: 'voice_live',
        'username' => getenv('DB_USERNAME') ?: 'root',
        'password' => getenv('DB_PASSWORD') ?: '',
        'charset' => 'utf8mb4',
        'sqlite_path' => __DIR__ . '/../database/dev.sqlite',
    ],
    'auth' => [
        'token_ttl_days' => 30,
        'pending_registration_expiry_minutes' => 30,
        'password_reset_expiry_minutes' => 20,
        'default_email_verification_code' => '11111',
        'default_phone_otp_code' => '52678',
    ],
    'admin' => [
        'seed_name' => 'Super Admin',
        'seed_email' => 'admin@voicelive.local',
        'seed_password_hash' => '$2y$12$ruZVxpodIVICMazLRrA6uufm2PUg5ITAsapjBBqS7hOmoDY48L2Zu',
    ],
];
