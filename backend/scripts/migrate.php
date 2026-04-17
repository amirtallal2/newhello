<?php

declare(strict_types=1);

$config = require __DIR__ . '/../config/app.php';

require_once __DIR__ . '/../src/Database.php';

$pdo = Database::connection($config['db']);
$driver = $config['db']['driver'];

$statements = $driver === 'sqlite'
    ? [
        'CREATE TABLE IF NOT EXISTS admins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT "super_admin",
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE,
            phone TEXT UNIQUE,
            password_hash TEXT NOT NULL,
            nickname TEXT,
            birthdate TEXT,
            gender TEXT,
            country TEXT,
            status TEXT NOT NULL DEFAULT "active",
            email_verified_at TEXT,
            phone_verified_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS auth_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            token_name TEXT NOT NULL,
            token_hash TEXT NOT NULL UNIQUE,
            last_used_at TEXT,
            expires_at TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS pending_registrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            phone TEXT UNIQUE,
            password_hash TEXT NOT NULL,
            nickname TEXT,
            birthdate TEXT,
            gender TEXT,
            country TEXT,
            registration_token TEXT NOT NULL UNIQUE,
            email_verification_code TEXT NOT NULL,
            email_verified_at TEXT,
            phone_otp_code TEXT,
            phone_verified_at TEXT,
            expires_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS password_reset_tokens (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            email_snapshot TEXT NOT NULL,
            reset_token TEXT NOT NULL UNIQUE,
            reset_code TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            used_at TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            card_title TEXT NOT NULL,
            room_title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            host_name TEXT NOT NULL,
            room_code TEXT NOT NULL UNIQUE,
            card_image_asset TEXT NOT NULL,
            meta_icon_asset TEXT NOT NULL,
            host_avatar_asset TEXT NOT NULL,
            listener_count INTEGER NOT NULL DEFAULT 0,
            mic_count INTEGER NOT NULL DEFAULT 9,
            background_asset TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS room_seat_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            user_id INTEGER NULL,
            requester_name TEXT NOT NULL,
            requester_avatar_asset TEXT,
            seat_number INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT "pending",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS user_wallets (
            user_id INTEGER PRIMARY KEY,
            coins_balance INTEGER NOT NULL DEFAULT 1235,
            diamonds_balance INTEGER NOT NULL DEFAULT 5,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS gifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            asset_path TEXT NOT NULL,
            price_coins INTEGER NOT NULL DEFAULT 10,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS music_tracks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist_name TEXT NOT NULL,
            source_type TEXT NOT NULL,
            cover_asset TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL DEFAULT 180,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS room_music_playlist_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            track_id INTEGER NOT NULL,
            added_by_user_id INTEGER NULL,
            added_by_name TEXT NOT NULL,
            source_type TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 1,
            status TEXT NOT NULL DEFAULT "queued",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(track_id) REFERENCES music_tracks(id) ON DELETE CASCADE,
            FOREIGN KEY(added_by_user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS room_gift_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            sender_user_id INTEGER NULL,
            sender_name TEXT NOT NULL,
            sender_avatar_asset TEXT,
            gift_id INTEGER NOT NULL,
            gift_name_snapshot TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            unit_price_coins INTEGER NOT NULL DEFAULT 10,
            total_price_coins INTEGER NOT NULL DEFAULT 10,
            recipient_mode TEXT NOT NULL DEFAULT "room_users",
            recipient_slot INTEGER NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            FOREIGN KEY(gift_id) REFERENCES gifts(id) ON DELETE CASCADE
        )',
      ]
    : [
        'CREATE TABLE IF NOT EXISTS admins (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(120) NOT NULL,
            email VARCHAR(190) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            role VARCHAR(50) NOT NULL DEFAULT "super_admin",
            is_active TINYINT(1) NOT NULL DEFAULT 1,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS users (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(190) NULL UNIQUE,
            phone VARCHAR(32) NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            nickname VARCHAR(120) NULL,
            birthdate DATE NULL,
            gender VARCHAR(20) NULL,
            country VARCHAR(120) NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            email_verified_at DATETIME NULL,
            phone_verified_at DATETIME NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS auth_tokens (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            token_name VARCHAR(50) NOT NULL,
            token_hash CHAR(64) NOT NULL UNIQUE,
            last_used_at DATETIME NULL,
            expires_at DATETIME NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_auth_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS pending_registrations (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(190) NOT NULL UNIQUE,
            phone VARCHAR(32) NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            nickname VARCHAR(120) NULL,
            birthdate DATE NULL,
            gender VARCHAR(20) NULL,
            country VARCHAR(120) NULL,
            registration_token CHAR(64) NOT NULL UNIQUE,
            email_verification_code VARCHAR(10) NOT NULL,
            email_verified_at DATETIME NULL,
            phone_otp_code VARCHAR(10) NULL,
            phone_verified_at DATETIME NULL,
            expires_at DATETIME NOT NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS password_reset_tokens (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            email_snapshot VARCHAR(190) NOT NULL,
            reset_token CHAR(64) NOT NULL UNIQUE,
            reset_code VARCHAR(10) NOT NULL,
            expires_at DATETIME NOT NULL,
            used_at DATETIME NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_password_reset_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS rooms (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            card_title VARCHAR(190) NOT NULL,
            room_title VARCHAR(190) NOT NULL,
            subtitle VARCHAR(255) NOT NULL,
            host_name VARCHAR(190) NOT NULL,
            room_code VARCHAR(64) NOT NULL UNIQUE,
            card_image_asset VARCHAR(255) NOT NULL,
            meta_icon_asset VARCHAR(255) NOT NULL,
            host_avatar_asset VARCHAR(255) NOT NULL,
            listener_count INT NOT NULL DEFAULT 0,
            mic_count INT NOT NULL DEFAULT 9,
            background_asset VARCHAR(255) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS room_seat_requests (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NULL,
            requester_name VARCHAR(190) NOT NULL,
            requester_avatar_asset VARCHAR(255) NULL,
            seat_number INT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "pending",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_room_requests_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_requests_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS user_wallets (
            user_id INT UNSIGNED PRIMARY KEY,
            coins_balance INT NOT NULL DEFAULT 1235,
            diamonds_balance INT NOT NULL DEFAULT 5,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_user_wallet_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS gifts (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(190) NOT NULL,
            category VARCHAR(100) NOT NULL,
            asset_path VARCHAR(255) NOT NULL,
            price_coins INT NOT NULL DEFAULT 10,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS music_tracks (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(190) NOT NULL,
            artist_name VARCHAR(190) NOT NULL,
            source_type VARCHAR(20) NOT NULL,
            cover_asset VARCHAR(255) NOT NULL,
            duration_seconds INT NOT NULL DEFAULT 180,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS room_music_playlist_entries (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            track_id INT UNSIGNED NOT NULL,
            added_by_user_id INT UNSIGNED NULL,
            added_by_name VARCHAR(190) NOT NULL,
            source_type VARCHAR(20) NOT NULL,
            sort_order INT NOT NULL DEFAULT 1,
            status VARCHAR(20) NOT NULL DEFAULT "queued",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_room_music_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_music_track FOREIGN KEY (track_id) REFERENCES music_tracks(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_music_user FOREIGN KEY (added_by_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS room_gift_transactions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            sender_user_id INT UNSIGNED NULL,
            sender_name VARCHAR(190) NOT NULL,
            sender_avatar_asset VARCHAR(255) NULL,
            gift_id INT UNSIGNED NOT NULL,
            gift_name_snapshot VARCHAR(190) NOT NULL,
            quantity INT NOT NULL DEFAULT 1,
            unit_price_coins INT NOT NULL DEFAULT 10,
            total_price_coins INT NOT NULL DEFAULT 10,
            recipient_mode VARCHAR(20) NOT NULL DEFAULT "room_users",
            recipient_slot INT NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_room_gifts_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_gifts_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_room_gifts_gift FOREIGN KEY (gift_id) REFERENCES gifts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
      ];

foreach ($statements as $statement) {
    $pdo->exec($statement);
}

$now = gmdate('Y-m-d H:i:s');
$seedEmail = $config['admin']['seed_email'];
$seedStatement = $pdo->prepare('SELECT id FROM admins WHERE email = :email LIMIT 1');
$seedStatement->execute(['email' => $seedEmail]);

if ($seedStatement->fetch() === false) {
    $insert = $pdo->prepare(
        'INSERT INTO admins
            (name, email, password_hash, role, is_active, created_at, updated_at)
         VALUES
            (:name, :email, :password_hash, :role, :is_active, :created_at, :updated_at)'
    );
    $insert->execute([
        'name' => $config['admin']['seed_name'],
        'email' => $seedEmail,
        'password_hash' => $config['admin']['seed_password_hash'],
        'role' => 'super_admin',
        'is_active' => 1,
        'created_at' => $now,
        'updated_at' => $now,
    ]);
}

$roomsCount = (int) $pdo->query('SELECT COUNT(*) FROM rooms')->fetchColumn();

if ($roomsCount === 0) {
    $seedRooms = [
        [
            'card_title' => 'الشكاوي والاقتراحات',
            'room_title' => 'أريد أن أسمع صوتك',
            'subtitle' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'host_name' => 'محمد أحمد',
            'room_code' => '1512345412',
            'card_image_asset' => 'assets/images/home_room_service.png',
            'meta_icon_asset' => 'assets/images/home_pin_icon.png',
            'host_avatar_asset' => 'assets/images/profile_avatar.png',
            'listener_count' => 30,
            'mic_count' => 9,
            'background_asset' => 'assets/images/room_background.jpg',
            'display_order' => 1,
        ],
        [
            'card_title' => 'خدمة العملاء',
            'room_title' => 'غرفة الدعم المباشر',
            'subtitle' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'host_name' => 'محمد أحمد',
            'room_code' => '1512345413',
            'card_image_asset' => 'assets/images/home_room_service.png',
            'meta_icon_asset' => 'assets/images/home_pin_icon.png',
            'host_avatar_asset' => 'assets/images/profile_avatar.png',
            'listener_count' => 30,
            'mic_count' => 9,
            'background_asset' => 'assets/images/room_background.jpg',
            'display_order' => 2,
        ],
        [
            'card_title' => 'وكالة ولاد الملوك',
            'room_title' => 'وكالة ولاد الملوك',
            'subtitle' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'host_name' => 'محمد أحمد',
            'room_code' => '1512345414',
            'card_image_asset' => 'assets/images/home_room_1.png',
            'meta_icon_asset' => 'assets/images/home_egypt_flag.png',
            'host_avatar_asset' => 'assets/images/profile_avatar.png',
            'listener_count' => 30,
            'mic_count' => 9,
            'background_asset' => 'assets/images/room_background.jpg',
            'display_order' => 3,
        ],
        [
            'card_title' => 'وكالة ولاد الملوك',
            'room_title' => 'وكالة ولاد الملوك',
            'subtitle' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'host_name' => 'محمد أحمد',
            'room_code' => '1512345415',
            'card_image_asset' => 'assets/images/home_room_2.png',
            'meta_icon_asset' => 'assets/images/home_egypt_flag.png',
            'host_avatar_asset' => 'assets/images/profile_avatar.png',
            'listener_count' => 30,
            'mic_count' => 9,
            'background_asset' => 'assets/images/room_background.jpg',
            'display_order' => 4,
        ],
    ];

    $insertRoom = $pdo->prepare(
        'INSERT INTO rooms
            (card_title, room_title, subtitle, host_name, room_code, card_image_asset, meta_icon_asset, host_avatar_asset, listener_count, mic_count, background_asset, status, display_order, created_at, updated_at)
         VALUES
            (:card_title, :room_title, :subtitle, :host_name, :room_code, :card_image_asset, :meta_icon_asset, :host_avatar_asset, :listener_count, :mic_count, :background_asset, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedRooms as $room) {
        $insertRoom->execute([
            ...$room,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$usersWithoutWallet = $pdo->query('SELECT id FROM users WHERE id NOT IN (SELECT user_id FROM user_wallets)')->fetchAll(PDO::FETCH_COLUMN);
if ($usersWithoutWallet !== []) {
    $insertWallet = $pdo->prepare(
        'INSERT INTO user_wallets
            (user_id, coins_balance, diamonds_balance, created_at, updated_at)
         VALUES
            (:user_id, :coins_balance, :diamonds_balance, :created_at, :updated_at)'
    );

    foreach ($usersWithoutWallet as $userId) {
        $insertWallet->execute([
            'user_id' => (int) $userId,
            'coins_balance' => 1235,
            'diamonds_balance' => 5,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$giftsCount = (int) $pdo->query('SELECT COUNT(*) FROM gifts')->fetchColumn();
if ($giftsCount === 0) {
    $seedGifts = [
        ['name' => 'الهدية الصغيرة', 'category' => 'الهداية عادية', 'asset_path' => 'assets/images/room_gift_1.png', 'price_coins' => 10, 'display_order' => 1],
        ['name' => 'الهدية الصغيرة', 'category' => 'الهداية عادية', 'asset_path' => 'assets/images/room_gift_2.png', 'price_coins' => 10, 'display_order' => 2],
        ['name' => 'الهدية الصغيرة', 'category' => 'الهداية عادية', 'asset_path' => 'assets/images/room_gift_3.png', 'price_coins' => 10, 'display_order' => 3],
        ['name' => 'الهدية الصغيرة', 'category' => 'الهداية عادية', 'asset_path' => 'assets/images/room_gift_4.png', 'price_coins' => 10, 'display_order' => 4],
        ['name' => 'الهدية الصغيرة', 'category' => 'VIP', 'asset_path' => 'assets/images/room_gift_5.png', 'price_coins' => 20, 'display_order' => 5],
        ['name' => 'الهدية الصغيرة', 'category' => 'VIP', 'asset_path' => 'assets/images/room_gift_6.png', 'price_coins' => 25, 'display_order' => 6],
        ['name' => 'الهدية الصغيرة', 'category' => 'المحظوظ', 'asset_path' => 'assets/images/room_gift_7.png', 'price_coins' => 30, 'display_order' => 7],
        ['name' => 'الهدية الصغيرة', 'category' => 'متحرك', 'asset_path' => 'assets/images/room_gift_8.png', 'price_coins' => 40, 'display_order' => 8],
    ];

    $insertGift = $pdo->prepare(
        'INSERT INTO gifts
            (name, category, asset_path, price_coins, status, display_order, created_at, updated_at)
         VALUES
            (:name, :category, :asset_path, :price_coins, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedGifts as $gift) {
        $insertGift->execute([
            ...$gift,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$musicTracksCount = (int) $pdo->query('SELECT COUNT(*) FROM music_tracks')->fetchColumn();
if ($musicTracksCount === 0) {
    $seedTracks = [
        ['title' => 'Friends Beat 01', 'artist_name' => 'DJ Nona', 'source_type' => 'friends', 'cover_asset' => 'assets/images/profile_store_friend_nona_avatar.png', 'duration_seconds' => 192, 'display_order' => 1],
        ['title' => 'Friends Beat 02', 'artist_name' => 'Mohammed Ahmed', 'source_type' => 'friends', 'cover_asset' => 'assets/images/profile_avatar.png', 'duration_seconds' => 205, 'display_order' => 2],
        ['title' => 'Friends Beat 03', 'artist_name' => 'Sara Mohamed', 'source_type' => 'friends', 'cover_asset' => 'assets/images/live150_comment_avatar.png', 'duration_seconds' => 176, 'display_order' => 3],
        ['title' => 'WhatsApp Voice Mix', 'artist_name' => 'Support Team', 'source_type' => 'whatsapp', 'cover_asset' => 'assets/images/home_room_service.png', 'duration_seconds' => 170, 'display_order' => 4],
        ['title' => 'WhatsApp Party Loop', 'artist_name' => 'Ahmed Ali', 'source_type' => 'whatsapp', 'cover_asset' => 'assets/images/home_room_1.png', 'duration_seconds' => 214, 'display_order' => 5],
        ['title' => 'WhatsApp Chill 03', 'artist_name' => 'Nour Salem', 'source_type' => 'whatsapp', 'cover_asset' => 'assets/images/home_room_2.png', 'duration_seconds' => 188, 'display_order' => 6],
    ];

    $insertTrack = $pdo->prepare(
        'INSERT INTO music_tracks
            (title, artist_name, source_type, cover_asset, duration_seconds, status, display_order, created_at, updated_at)
         VALUES
            (:title, :artist_name, :source_type, :cover_asset, :duration_seconds, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedTracks as $track) {
        $insertTrack->execute([
            ...$track,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$transactionsCount = (int) $pdo->query('SELECT COUNT(*) FROM room_gift_transactions')->fetchColumn();
if ($transactionsCount === 0) {
    $giftIds = $pdo->query('SELECT id FROM gifts ORDER BY id ASC')->fetchAll(PDO::FETCH_COLUMN);
    $firstGiftId = (int) ($giftIds[0] ?? 1);

    $insertTransaction = $pdo->prepare(
        'INSERT INTO room_gift_transactions
            (room_id, sender_user_id, sender_name, sender_avatar_asset, gift_id, gift_name_snapshot, quantity, unit_price_coins, total_price_coins, recipient_mode, recipient_slot, created_at)
         VALUES
            (:room_id, :sender_user_id, :sender_name, :sender_avatar_asset, :gift_id, :gift_name_snapshot, :quantity, :unit_price_coins, :total_price_coins, :recipient_mode, :recipient_slot, :created_at)'
    );

    $seedTransactions = [
        ['room_id' => 1, 'sender_name' => 'Mohammed Ahmed', 'gift_name_snapshot' => 'الهدية الصغيرة', 'quantity' => 20, 'unit_price_coins' => 10, 'total_price_coins' => 200],
        ['room_id' => 1, 'sender_name' => 'Ahmed Ali', 'gift_name_snapshot' => 'الهدية الصغيرة', 'quantity' => 20, 'unit_price_coins' => 10, 'total_price_coins' => 200],
        ['room_id' => 1, 'sender_name' => 'Sara Mohamed', 'gift_name_snapshot' => 'الهدية الصغيرة', 'quantity' => 20, 'unit_price_coins' => 10, 'total_price_coins' => 200],
        ['room_id' => 1, 'sender_name' => 'Mohammed Ahmed', 'gift_name_snapshot' => 'الهدية الصغيرة', 'quantity' => 21, 'unit_price_coins' => 1, 'total_price_coins' => 21],
    ];

    foreach ($seedTransactions as $transaction) {
        $insertTransaction->execute([
            ...$transaction,
            'sender_user_id' => null,
            'sender_avatar_asset' => 'assets/images/profile_avatar.png',
            'gift_id' => $firstGiftId,
            'recipient_mode' => 'room_users',
            'recipient_slot' => null,
            'created_at' => $now,
        ]);
    }
}

echo "Migration completed successfully.\n";
