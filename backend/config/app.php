<?php

declare(strict_types=1);

$config = [
    'app_name' => 'Hallo Party Backend',
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
    'google' => [
        'client_ids' => array_values(
            array_filter(
                array_map(
                    static fn (string $value): string => trim($value),
                    explode(
                        ',',
                        getenv('GOOGLE_CLIENT_IDS')
                            ?: (getenv('GOOGLE_SERVER_CLIENT_ID')
                                ?: '920413815879-apmg5tgaalgir8j7d5tn64tcnveg52g9.apps.googleusercontent.com')
                    )
                )
            )
        ),
        'jwks_uri' => getenv('GOOGLE_JWKS_URI') ?: 'https://www.googleapis.com/oauth2/v3/certs',
        'jwks_cache_path' => __DIR__ . '/../storage/cache/google-jwks.json',
    ],
    'agora' => [
        'app_id' => trim((string) (getenv('AGORA_APP_ID') ?: '')),
        'app_certificate' => trim((string) (getenv('AGORA_APP_CERTIFICATE') ?: '')),
        'token_expire_seconds' => max(300, (int) (getenv('AGORA_TOKEN_EXPIRE_SECONDS') ?: '3600')),
        'presence_ttl_seconds' => max(30, (int) (getenv('AGORA_PRESENCE_TTL_SECONDS') ?: '90')),
    ],
    'admin' => [
        'seed_name' => 'Super Admin',
        'seed_email' => 'admin@voicelive.local',
        'seed_password_hash' => '$2y$12$ruZVxpodIVICMazLRrA6uufm2PUg5ITAsapjBBqS7hOmoDY48L2Zu',
    ],
];

$runtimeConfigPath = __DIR__ . '/runtime.php';
if (is_file($runtimeConfigPath)) {
    $runtimeConfig = require $runtimeConfigPath;
    if (is_array($runtimeConfig)) {
        $config = array_replace_recursive($config, $runtimeConfig);
    }
}

return $config;
