<?php

declare(strict_types=1);

return [
    'db' => [
        'driver' => 'mysql',
        'host' => 'localhost',
        'port' => 3306,
        'database' => 'halloparty_db',
        'username' => 'halloparty_user',
        'password' => 'CHANGE_ME',
    ],
    'google' => [
        'client_ids' => [
            '920413815879-apmg5tgaalgir8j7d5tn64tcnveg52g9.apps.googleusercontent.com',
            '920413815879-s79b1iub0q3c1mdpsqbt5sgde2168bq4.apps.googleusercontent.com',
        ],
    ],
    'agora' => [
        'app_id' => 'PUT_YOUR_AGORA_APP_ID_HERE',
        'app_certificate' => 'PUT_YOUR_AGORA_APP_CERTIFICATE_HERE',
        'token_expire_seconds' => 3600,
        'presence_ttl_seconds' => 90,
    ],
    'admin' => [
        'seed_name' => 'Super Admin',
        'seed_email' => 'admin@voicelive.local',
        'seed_password_hash' => '$2y$12$ruZVxpodIVICMazLRrA6uufm2PUg5ITAsapjBBqS7hOmoDY48L2Zu',
    ],
];
