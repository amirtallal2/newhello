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
        'CREATE TABLE IF NOT EXISTS user_follows (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            follower_user_id INTEGER NOT NULL,
            followed_user_id INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(follower_user_id, followed_user_id),
            FOREIGN KEY(follower_user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(followed_user_id) REFERENCES users(id) ON DELETE CASCADE
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
            host_user_id INTEGER NULL,
            creator_user_id INTEGER NULL,
            room_type TEXT NOT NULL DEFAULT "غناء",
            slogan_text TEXT NULL,
            country_label TEXT NOT NULL DEFAULT "مصر",
            room_code TEXT NOT NULL UNIQUE,
            card_image_asset TEXT NOT NULL,
            meta_icon_asset TEXT NOT NULL,
            host_avatar_asset TEXT NOT NULL,
            listener_count INTEGER NOT NULL DEFAULT 0,
            mic_count INTEGER NOT NULL DEFAULT 9,
            background_asset TEXT NOT NULL,
            audio_enabled INTEGER NOT NULL DEFAULT 1,
            agora_channel_name TEXT NULL,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(host_user_id) REFERENCES users(id) ON DELETE SET NULL,
            FOREIGN KEY(creator_user_id) REFERENCES users(id) ON DELETE SET NULL
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
        'CREATE TABLE IF NOT EXISTS room_audio_participants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            user_id INTEGER NULL,
            user_account TEXT NOT NULL,
            display_name TEXT NOT NULL,
            avatar_asset TEXT NULL,
            role TEXT NOT NULL DEFAULT "listener",
            seat_number INTEGER NULL,
            mic_muted INTEGER NOT NULL DEFAULT 1,
            status TEXT NOT NULL DEFAULT "joined",
            joined_at TEXT NOT NULL,
            last_seen_at TEXT NOT NULL,
            left_at TEXT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL,
            UNIQUE(room_id, user_account)
        )',
        'CREATE TABLE IF NOT EXISTS live_rooms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            host_name TEXT NOT NULL,
            host_id_label TEXT NOT NULL,
            host_user_id INTEGER NULL,
            video_enabled INTEGER NOT NULL DEFAULT 1,
            agora_channel_name TEXT NULL,
            poster_asset TEXT NOT NULL,
            background_asset TEXT NOT NULL,
            left_video_asset TEXT NOT NULL,
            right_video_asset TEXT NOT NULL,
            viewer_count INTEGER NOT NULL DEFAULT 0,
            coin_count INTEGER NOT NULL DEFAULT 0,
            battle_timer_label TEXT NOT NULL DEFAULT "11:50",
            listing_scope TEXT NOT NULL DEFAULT "live",
            contribution_diamonds_total INTEGER NOT NULL DEFAULT 0,
            contribution_sender_count INTEGER NOT NULL DEFAULT 0,
            pk_talk_permission TEXT NOT NULL DEFAULT "عند الطلب",
            pk_party_invite_permission TEXT NOT NULL DEFAULT "عند الطلب",
            pk_voice_room_invite_permission TEXT NOT NULL DEFAULT "عند الطلب",
            pk_chat_permission TEXT NOT NULL DEFAULT "عند الطلب",
            pk_battle_duration TEXT NOT NULL DEFAULT "30د",
            pk_status TEXT NOT NULL DEFAULT "idle",
            active_pk_invite_id INTEGER NULL,
            pk_guest_user_id INTEGER NULL,
            pk_guest_name TEXT NULL,
            pk_started_at TEXT NULL,
            pk_ends_at TEXT NULL,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            ended_at TEXT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS live_room_viewers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            user_id INTEGER NULL,
            user_account TEXT NULL,
            client_role TEXT NOT NULL DEFAULT "audience",
            rank_order INTEGER NOT NULL DEFAULT 1,
            viewer_name TEXT NOT NULL,
            avatar_asset TEXT NOT NULL,
            is_top_supporter INTEGER NOT NULL DEFAULT 0,
            is_online INTEGER NOT NULL DEFAULT 0,
            last_seen_at TEXT NULL,
            left_at TEXT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NULL,
            FOREIGN KEY(room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS live_room_comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            commenter_name TEXT NOT NULL,
            avatar_asset TEXT NOT NULL,
            message_text TEXT NOT NULL,
            display_order INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS live_room_notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            title_text TEXT NOT NULL,
            body_text TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS live_room_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            reporter_user_id INTEGER NULL,
            reporter_name TEXT NOT NULL,
            reason_text TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "new",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES live_rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS live_pk_invites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            sender_user_id INTEGER NULL,
            sender_name TEXT NOT NULL,
            recipient_user_id INTEGER NOT NULL,
            recipient_name_snapshot TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "sent",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES live_rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            FOREIGN KEY(recipient_user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS live_room_gift_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            sender_user_id INTEGER NULL,
            sender_name TEXT NOT NULL,
            sender_avatar_asset TEXT,
            recipient_user_id INTEGER NULL,
            recipient_name_snapshot TEXT NULL,
            gift_id INTEGER NOT NULL,
            gift_name_snapshot TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price_coins INTEGER NOT NULL,
            total_price_coins INTEGER NOT NULL,
            platform_fee_coins INTEGER NOT NULL DEFAULT 0,
            creator_earning_diamonds INTEGER NOT NULL DEFAULT 0,
            platform_commission_percent REAL NOT NULL DEFAULT 50,
            created_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES live_rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            FOREIGN KEY(gift_id) REFERENCES gifts(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS user_wallets (
            user_id INTEGER PRIMARY KEY,
            coins_balance INTEGER NOT NULL DEFAULT 1235,
            diamonds_balance INTEGER NOT NULL DEFAULT 5,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS wallet_packages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            wallet_type TEXT NOT NULL,
            amount INTEGER NOT NULL,
            bonus_amount INTEGER NOT NULL DEFAULT 0,
            price_label TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS wallet_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            wallet_type TEXT NOT NULL,
            direction TEXT NOT NULL,
            amount INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT "success",
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            context_type TEXT NOT NULL,
            context_ref TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS gifts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            asset_path TEXT NOT NULL,
            animation_path TEXT NULL,
            sound_path TEXT NULL,
            is_animated INTEGER NOT NULL DEFAULT 0,
            effect_duration_ms INTEGER NOT NULL DEFAULT 1800,
            price_coins INTEGER NOT NULL DEFAULT 10,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS store_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_key TEXT NOT NULL,
            name TEXT NOT NULL,
            preview_asset_path TEXT NOT NULL,
            dialog_icon_asset_path TEXT,
            dialog_preview_asset_path TEXT,
            price_3_days INTEGER NOT NULL DEFAULT 0,
            price_7_days INTEGER NOT NULL DEFAULT 0,
            price_15_days INTEGER NOT NULL DEFAULT 0,
            price_30_days INTEGER NOT NULL DEFAULT 0,
            discount_3_days TEXT NOT NULL DEFAULT "",
            discount_7_days TEXT NOT NULL DEFAULT "",
            discount_15_days TEXT NOT NULL DEFAULT "",
            discount_30_days TEXT NOT NULL DEFAULT "",
            currency_type TEXT NOT NULL DEFAULT "coins",
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS user_store_inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            item_id INTEGER NOT NULL,
            category_key TEXT NOT NULL,
            item_name_snapshot TEXT NOT NULL,
            preview_asset_path TEXT NOT NULL,
            dialog_preview_asset_path TEXT,
            duration_days INTEGER NOT NULL DEFAULT 7,
            status TEXT NOT NULL DEFAULT "active",
            is_equipped INTEGER NOT NULL DEFAULT 0,
            acquired_via TEXT NOT NULL DEFAULT "purchase",
            sender_name_snapshot TEXT,
            recipient_name_snapshot TEXT,
            expires_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(item_id) REFERENCES store_items(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS store_send_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_user_id INTEGER NOT NULL,
            recipient_user_id INTEGER NULL,
            recipient_name_snapshot TEXT NOT NULL,
            item_id INTEGER NOT NULL,
            item_name_snapshot TEXT NOT NULL,
            duration_days INTEGER NOT NULL DEFAULT 7,
            price_amount INTEGER NOT NULL DEFAULT 0,
            currency_type TEXT NOT NULL DEFAULT "coins",
            created_at TEXT NOT NULL,
            FOREIGN KEY(sender_user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(recipient_user_id) REFERENCES users(id) ON DELETE SET NULL,
            FOREIGN KEY(item_id) REFERENCES store_items(id) ON DELETE CASCADE
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
        'CREATE TABLE IF NOT EXISTS room_games_catalog (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            game_key TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            category_key TEXT NOT NULL,
            icon_asset TEXT NOT NULL,
            description_text TEXT NOT NULL,
            min_players INTEGER NOT NULL DEFAULT 1,
            max_players INTEGER NOT NULL DEFAULT 4,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS room_game_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            game_id INTEGER NOT NULL,
            host_user_id INTEGER NULL,
            host_name TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            player_count INTEGER NOT NULL DEFAULT 0,
            max_players INTEGER NOT NULL DEFAULT 4,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            ended_at TEXT NULL,
            FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(game_id) REFERENCES room_games_catalog(id) ON DELETE CASCADE,
            FOREIGN KEY(host_user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS room_game_session_players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            player_name TEXT NOT NULL,
            seat_number INTEGER NOT NULL DEFAULT 1,
            status TEXT NOT NULL DEFAULT "active",
            joined_at TEXT NOT NULL,
            left_at TEXT NULL,
            FOREIGN KEY(session_id) REFERENCES room_game_sessions(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS room_gift_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            room_id INTEGER NOT NULL,
            sender_user_id INTEGER NULL,
            sender_name TEXT NOT NULL,
            sender_avatar_asset TEXT,
            recipient_user_id INTEGER NULL,
            recipient_name_snapshot TEXT NULL,
            gift_id INTEGER NOT NULL,
            gift_name_snapshot TEXT NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            unit_price_coins INTEGER NOT NULL DEFAULT 10,
            total_price_coins INTEGER NOT NULL DEFAULT 10,
            platform_fee_coins INTEGER NOT NULL DEFAULT 0,
            creator_earning_diamonds INTEGER NOT NULL DEFAULT 0,
            platform_commission_percent REAL NOT NULL DEFAULT 50,
            recipient_mode TEXT NOT NULL DEFAULT "room_users",
            recipient_slot INTEGER NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            FOREIGN KEY(sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            FOREIGN KEY(gift_id) REFERENCES gifts(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS shipping_agencies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            handle TEXT NOT NULL,
            diamond_balance INTEGER NOT NULL DEFAULT 0,
            supported_country_codes TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS support_tickets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticket_code TEXT NOT NULL UNIQUE,
            user_id INTEGER NULL,
            sender_name TEXT NOT NULL,
            sender_email TEXT,
            sender_phone TEXT,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "new",
            attachment_count INTEGER NOT NULL DEFAULT 0,
            admin_note TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS support_ticket_attachments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticket_id INTEGER NOT NULL,
            file_path TEXT NOT NULL,
            original_name TEXT NOT NULL,
            mime_type TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(ticket_id) REFERENCES support_tickets(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            author_user_id INTEGER NULL,
            author_key TEXT NOT NULL,
            author_name TEXT NOT NULL,
            author_avatar_asset TEXT NOT NULL,
            body_text TEXT NOT NULL,
            image_path TEXT NULL,
            status TEXT NOT NULL DEFAULT "active",
            report_count INTEGER NOT NULL DEFAULT 0,
            like_count INTEGER NOT NULL DEFAULT 0,
            comment_count INTEGER NOT NULL DEFAULT 0,
            share_count INTEGER NOT NULL DEFAULT 0,
            shared_post_id INTEGER NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(author_user_id) REFERENCES users(id) ON DELETE SET NULL,
            FOREIGN KEY(shared_post_id) REFERENCES posts(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS post_followings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            author_key TEXT NOT NULL,
            author_name_snapshot TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(user_id, author_key),
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS post_likes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            post_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(post_id, user_id),
            FOREIGN KEY(post_id) REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS post_comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            post_id INTEGER NOT NULL,
            user_id INTEGER NULL,
            author_name_snapshot TEXT NOT NULL,
            author_avatar_asset TEXT NOT NULL DEFAULT "assets/images/post_author_avatar.png",
            body_text TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            report_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NULL,
            FOREIGN KEY(post_id) REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS post_report_reasons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reason_key TEXT NOT NULL UNIQUE,
            label TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT "",
            display_order INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT "active",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )',
        'CREATE TABLE IF NOT EXISTS post_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            post_id INTEGER NOT NULL,
            reporter_user_id INTEGER NULL,
            reporter_name TEXT NOT NULL,
            reason TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "new",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(post_id) REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY(reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS post_comment_reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            comment_id INTEGER NOT NULL,
            post_id INTEGER NOT NULL,
            reporter_user_id INTEGER NULL,
            reporter_name TEXT NOT NULL,
            reason TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "new",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(comment_id) REFERENCES post_comments(id) ON DELETE CASCADE,
            FOREIGN KEY(post_id) REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY(reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS post_notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            post_id INTEGER NOT NULL,
            actor_user_id INTEGER NULL,
            actor_name TEXT NOT NULL,
            notification_type TEXT NOT NULL,
            message TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(post_id) REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY(actor_user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS chat_threads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_user_id INTEGER NOT NULL,
            target_user_id INTEGER NULL,
            thread_key TEXT NOT NULL,
            listing_group TEXT NOT NULL DEFAULT "messages",
            thread_type TEXT NOT NULL DEFAULT "direct",
            title TEXT NOT NULL,
            preview_text TEXT NOT NULL DEFAULT "",
            avatar_asset TEXT NOT NULL,
            status_color_hex TEXT NOT NULL DEFAULT "#34A853",
            read_style TEXT NOT NULL DEFAULT "none",
            is_photo_preview INTEGER NOT NULL DEFAULT 0,
            unread_count INTEGER NOT NULL DEFAULT 0,
            is_system INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT "active",
            is_deleted INTEGER NOT NULL DEFAULT 0,
            display_order INTEGER NOT NULL DEFAULT 0,
            message_date_label TEXT NOT NULL DEFAULT "",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(owner_user_id, thread_key),
            FOREIGN KEY(owner_user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(target_user_id) REFERENCES users(id) ON DELETE SET NULL
        )',
        'CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            thread_id INTEGER NOT NULL,
            direction TEXT NOT NULL DEFAULT "incoming",
            sender_name TEXT NOT NULL,
            body_text TEXT NOT NULL,
            message_type TEXT NOT NULL DEFAULT "text",
            time_label TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE
        )',
        'CREATE TABLE IF NOT EXISTS chat_search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            label TEXT NOT NULL,
            target_thread_id INTEGER NULL,
            created_at TEXT NOT NULL,
            UNIQUE(user_id, label),
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(target_thread_id) REFERENCES chat_threads(id) ON DELETE SET NULL
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
        'CREATE TABLE IF NOT EXISTS user_follows (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            follower_user_id INT UNSIGNED NOT NULL,
            followed_user_id INT UNSIGNED NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            UNIQUE KEY uq_user_follows_pair (follower_user_id, followed_user_id),
            KEY idx_user_follows_followed_status (followed_user_id, status),
            CONSTRAINT fk_user_follows_follower FOREIGN KEY (follower_user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_user_follows_followed FOREIGN KEY (followed_user_id) REFERENCES users(id) ON DELETE CASCADE
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
            host_user_id INT UNSIGNED NULL,
            creator_user_id INT UNSIGNED NULL,
            room_type VARCHAR(40) NOT NULL DEFAULT "غناء",
            slogan_text VARCHAR(255) NULL,
            country_label VARCHAR(120) NOT NULL DEFAULT "مصر",
            room_code VARCHAR(64) NOT NULL UNIQUE,
            card_image_asset VARCHAR(255) NOT NULL,
            meta_icon_asset VARCHAR(255) NOT NULL,
            host_avatar_asset VARCHAR(255) NOT NULL,
            listener_count INT NOT NULL DEFAULT 0,
            mic_count INT NOT NULL DEFAULT 9,
            background_asset VARCHAR(255) NOT NULL,
            audio_enabled TINYINT(1) NOT NULL DEFAULT 1,
            agora_channel_name VARCHAR(120) NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_rooms_host_user FOREIGN KEY (host_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_rooms_creator_user FOREIGN KEY (creator_user_id) REFERENCES users(id) ON DELETE SET NULL
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
        'CREATE TABLE IF NOT EXISTS room_audio_participants (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NULL,
            user_account VARCHAR(190) NOT NULL,
            display_name VARCHAR(190) NOT NULL,
            avatar_asset VARCHAR(255) NULL,
            role VARCHAR(20) NOT NULL DEFAULT "listener",
            seat_number INT NULL,
            mic_muted TINYINT(1) NOT NULL DEFAULT 1,
            status VARCHAR(20) NOT NULL DEFAULT "joined",
            joined_at DATETIME NOT NULL,
            last_seen_at DATETIME NOT NULL,
            left_at DATETIME NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_room_audio_participants_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_audio_participants_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
            UNIQUE KEY uq_room_audio_participants_room_account (room_id, user_account)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS live_rooms (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(190) NOT NULL,
            host_name VARCHAR(190) NOT NULL,
            host_id_label VARCHAR(120) NOT NULL,
            host_user_id INT UNSIGNED NULL,
            video_enabled TINYINT(1) NOT NULL DEFAULT 1,
            agora_channel_name VARCHAR(120) NULL,
            poster_asset VARCHAR(255) NOT NULL,
            background_asset VARCHAR(255) NOT NULL,
            left_video_asset VARCHAR(255) NOT NULL,
            right_video_asset VARCHAR(255) NOT NULL,
            viewer_count INT NOT NULL DEFAULT 0,
            coin_count INT NOT NULL DEFAULT 0,
            battle_timer_label VARCHAR(20) NOT NULL DEFAULT "11:50",
            listing_scope VARCHAR(20) NOT NULL DEFAULT "live",
            contribution_diamonds_total INT NOT NULL DEFAULT 0,
            contribution_sender_count INT NOT NULL DEFAULT 0,
            pk_talk_permission VARCHAR(30) NOT NULL DEFAULT "عند الطلب",
            pk_party_invite_permission VARCHAR(30) NOT NULL DEFAULT "عند الطلب",
            pk_voice_room_invite_permission VARCHAR(30) NOT NULL DEFAULT "عند الطلب",
            pk_chat_permission VARCHAR(30) NOT NULL DEFAULT "عند الطلب",
            pk_battle_duration VARCHAR(10) NOT NULL DEFAULT "30د",
            pk_status VARCHAR(20) NOT NULL DEFAULT "idle",
            active_pk_invite_id INT UNSIGNED NULL,
            pk_guest_user_id INT UNSIGNED NULL,
            pk_guest_name VARCHAR(190) NULL,
            pk_started_at DATETIME NULL,
            pk_ends_at DATETIME NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            ended_at DATETIME NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS live_room_viewers (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NULL,
            user_account VARCHAR(120) NULL,
            client_role VARCHAR(30) NOT NULL DEFAULT "audience",
            rank_order INT NOT NULL DEFAULT 1,
            viewer_name VARCHAR(190) NOT NULL,
            avatar_asset VARCHAR(255) NOT NULL,
            is_top_supporter TINYINT(1) NOT NULL DEFAULT 0,
            is_online TINYINT(1) NOT NULL DEFAULT 0,
            last_seen_at DATETIME NULL,
            left_at DATETIME NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NULL,
            CONSTRAINT fk_live_viewers_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_live_viewers_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
            INDEX idx_live_viewers_presence (room_id, is_online, last_seen_at),
            UNIQUE KEY uq_live_viewers_room_user (room_id, user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS live_room_comments (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            commenter_name VARCHAR(190) NOT NULL,
            avatar_asset VARCHAR(255) NOT NULL,
            message_text TEXT NOT NULL,
            display_order INT NOT NULL DEFAULT 1,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_live_comments_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS live_room_notifications (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            title_text VARCHAR(190) NOT NULL,
            body_text TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_live_notifications_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS live_room_reports (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            reporter_user_id INT UNSIGNED NULL,
            reporter_name VARCHAR(190) NOT NULL,
            reason_text TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "new",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_live_reports_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_live_reports_user FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS live_pk_invites (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            sender_user_id INT UNSIGNED NULL,
            sender_name VARCHAR(190) NOT NULL,
            recipient_user_id INT UNSIGNED NOT NULL,
            recipient_name_snapshot VARCHAR(190) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "sent",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_live_pk_invites_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_live_pk_invites_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_live_pk_invites_recipient FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS live_room_gift_transactions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            sender_user_id INT UNSIGNED NULL,
            sender_name VARCHAR(190) NOT NULL,
            sender_avatar_asset VARCHAR(255) NULL,
            recipient_user_id INT UNSIGNED NULL,
            recipient_name_snapshot VARCHAR(190) NULL,
            gift_id INT UNSIGNED NOT NULL,
            gift_name_snapshot VARCHAR(190) NOT NULL,
            quantity INT NOT NULL,
            unit_price_coins INT NOT NULL,
            total_price_coins INT NOT NULL,
            platform_fee_coins INT NOT NULL DEFAULT 0,
            creator_earning_diamonds INT NOT NULL DEFAULT 0,
            platform_commission_percent DECIMAL(5,2) NOT NULL DEFAULT 50.00,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_live_room_gifts_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_live_room_gifts_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_live_room_gifts_gift FOREIGN KEY (gift_id) REFERENCES gifts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS user_wallets (
            user_id INT UNSIGNED PRIMARY KEY,
            coins_balance INT NOT NULL DEFAULT 1235,
            diamonds_balance INT NOT NULL DEFAULT 5,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_user_wallet_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS wallet_packages (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            wallet_type VARCHAR(20) NOT NULL,
            amount INT NOT NULL,
            bonus_amount INT NOT NULL DEFAULT 0,
            price_label VARCHAR(120) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS wallet_transactions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            wallet_type VARCHAR(20) NOT NULL,
            direction VARCHAR(20) NOT NULL,
            amount INT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "success",
            title VARCHAR(190) NOT NULL,
            subtitle VARCHAR(255) NOT NULL,
            context_type VARCHAR(50) NOT NULL,
            context_ref VARCHAR(120) NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_wallet_transactions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS gifts (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(190) NOT NULL,
            category VARCHAR(100) NOT NULL,
            asset_path VARCHAR(255) NOT NULL,
            animation_path VARCHAR(255) NULL,
            sound_path VARCHAR(255) NULL,
            is_animated TINYINT(1) NOT NULL DEFAULT 0,
            effect_duration_ms INT NOT NULL DEFAULT 1800,
            price_coins INT NOT NULL DEFAULT 10,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS store_items (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            category_key VARCHAR(50) NOT NULL,
            name VARCHAR(190) NOT NULL,
            preview_asset_path VARCHAR(255) NOT NULL,
            dialog_icon_asset_path VARCHAR(255) NULL,
            dialog_preview_asset_path VARCHAR(255) NULL,
            price_3_days INT NOT NULL DEFAULT 0,
            price_7_days INT NOT NULL DEFAULT 0,
            price_15_days INT NOT NULL DEFAULT 0,
            price_30_days INT NOT NULL DEFAULT 0,
            discount_3_days VARCHAR(30) NOT NULL DEFAULT "",
            discount_7_days VARCHAR(30) NOT NULL DEFAULT "",
            discount_15_days VARCHAR(30) NOT NULL DEFAULT "",
            discount_30_days VARCHAR(30) NOT NULL DEFAULT "",
            currency_type VARCHAR(20) NOT NULL DEFAULT "coins",
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS user_store_inventory (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            item_id INT UNSIGNED NOT NULL,
            category_key VARCHAR(50) NOT NULL,
            item_name_snapshot VARCHAR(190) NOT NULL,
            preview_asset_path VARCHAR(255) NOT NULL,
            dialog_preview_asset_path VARCHAR(255) NULL,
            duration_days INT NOT NULL DEFAULT 7,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            is_equipped TINYINT(1) NOT NULL DEFAULT 0,
            acquired_via VARCHAR(30) NOT NULL DEFAULT "purchase",
            sender_name_snapshot VARCHAR(190) NULL,
            recipient_name_snapshot VARCHAR(190) NULL,
            expires_at DATETIME NOT NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_user_store_inventory_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_user_store_inventory_item FOREIGN KEY (item_id) REFERENCES store_items(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS store_send_transactions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            sender_user_id INT UNSIGNED NOT NULL,
            recipient_user_id INT UNSIGNED NULL,
            recipient_name_snapshot VARCHAR(190) NOT NULL,
            item_id INT UNSIGNED NOT NULL,
            item_name_snapshot VARCHAR(190) NOT NULL,
            duration_days INT NOT NULL DEFAULT 7,
            price_amount INT NOT NULL DEFAULT 0,
            currency_type VARCHAR(20) NOT NULL DEFAULT "coins",
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_store_send_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_store_send_recipient FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_store_send_item FOREIGN KEY (item_id) REFERENCES store_items(id) ON DELETE CASCADE
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
        'CREATE TABLE IF NOT EXISTS room_games_catalog (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            game_key VARCHAR(80) NOT NULL UNIQUE,
            name VARCHAR(190) NOT NULL,
            category_key VARCHAR(30) NOT NULL,
            icon_asset VARCHAR(255) NOT NULL,
            description_text TEXT NOT NULL,
            min_players INT NOT NULL DEFAULT 1,
            max_players INT NOT NULL DEFAULT 4,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS room_game_sessions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            game_id INT UNSIGNED NOT NULL,
            host_user_id INT UNSIGNED NULL,
            host_name VARCHAR(190) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            player_count INT NOT NULL DEFAULT 0,
            max_players INT NOT NULL DEFAULT 4,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            ended_at DATETIME NULL,
            KEY idx_room_game_sessions_room_game (room_id, game_id, status),
            CONSTRAINT fk_room_game_sessions_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_game_sessions_game FOREIGN KEY (game_id) REFERENCES room_games_catalog(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_game_sessions_host FOREIGN KEY (host_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS room_game_session_players (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            session_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NOT NULL,
            player_name VARCHAR(190) NOT NULL,
            seat_number INT NOT NULL DEFAULT 1,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            joined_at DATETIME NOT NULL,
            left_at DATETIME NULL,
            UNIQUE KEY uq_room_game_player_active (session_id, user_id, status),
            CONSTRAINT fk_room_game_players_session FOREIGN KEY (session_id) REFERENCES room_game_sessions(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_game_players_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS room_gift_transactions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            sender_user_id INT UNSIGNED NULL,
            sender_name VARCHAR(190) NOT NULL,
            sender_avatar_asset VARCHAR(255) NULL,
            recipient_user_id INT UNSIGNED NULL,
            recipient_name_snapshot VARCHAR(190) NULL,
            gift_id INT UNSIGNED NOT NULL,
            gift_name_snapshot VARCHAR(190) NOT NULL,
            quantity INT NOT NULL DEFAULT 1,
            unit_price_coins INT NOT NULL DEFAULT 10,
            total_price_coins INT NOT NULL DEFAULT 10,
            platform_fee_coins INT NOT NULL DEFAULT 0,
            creator_earning_diamonds INT NOT NULL DEFAULT 0,
            platform_commission_percent DECIMAL(5,2) NOT NULL DEFAULT 50.00,
            recipient_mode VARCHAR(20) NOT NULL DEFAULT "room_users",
            recipient_slot INT NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_room_gifts_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
            CONSTRAINT fk_room_gifts_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_room_gifts_gift FOREIGN KEY (gift_id) REFERENCES gifts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS shipping_agencies (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(190) NOT NULL,
            handle VARCHAR(120) NOT NULL,
            diamond_balance BIGINT NOT NULL DEFAULT 0,
            supported_country_codes TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS support_tickets (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            ticket_code VARCHAR(40) NOT NULL UNIQUE,
            user_id INT UNSIGNED NULL,
            sender_name VARCHAR(190) NOT NULL,
            sender_email VARCHAR(190) NULL,
            sender_phone VARCHAR(32) NULL,
            category VARCHAR(120) NOT NULL,
            description TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "new",
            attachment_count INT NOT NULL DEFAULT 0,
            admin_note TEXT NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_support_tickets_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS support_ticket_attachments (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            ticket_id INT UNSIGNED NOT NULL,
            file_path VARCHAR(255) NOT NULL,
            original_name VARCHAR(255) NOT NULL,
            mime_type VARCHAR(120) NOT NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_support_ticket_attachments_ticket FOREIGN KEY (ticket_id) REFERENCES support_tickets(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS posts (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            author_user_id INT UNSIGNED NULL,
            author_key VARCHAR(190) NOT NULL,
            author_name VARCHAR(190) NOT NULL,
            author_avatar_asset VARCHAR(255) NOT NULL,
            body_text TEXT NOT NULL,
            image_path VARCHAR(255) NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            report_count INT NOT NULL DEFAULT 0,
            like_count INT NOT NULL DEFAULT 0,
            comment_count INT NOT NULL DEFAULT 0,
            share_count INT NOT NULL DEFAULT 0,
            shared_post_id INT UNSIGNED NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_posts_author_user FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_posts_shared_post FOREIGN KEY (shared_post_id) REFERENCES posts(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS post_followings (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            author_key VARCHAR(190) NOT NULL,
            author_name_snapshot VARCHAR(190) NOT NULL,
            created_at DATETIME NOT NULL,
            UNIQUE KEY uq_post_followings_user_author (user_id, author_key),
            CONSTRAINT fk_post_followings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS post_likes (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            post_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NOT NULL,
            created_at DATETIME NOT NULL,
            UNIQUE KEY uq_post_likes_post_user (post_id, user_id),
            CONSTRAINT fk_post_likes_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS post_comments (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            post_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NULL,
            author_name_snapshot VARCHAR(190) NOT NULL,
            author_avatar_asset VARCHAR(255) NOT NULL DEFAULT "assets/images/post_author_avatar.png",
            body_text TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            report_count INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NULL,
            CONSTRAINT fk_post_comments_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_comments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS post_report_reasons (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            reason_key VARCHAR(120) NOT NULL UNIQUE,
            label VARCHAR(120) NOT NULL,
            description VARCHAR(255) NOT NULL DEFAULT "",
            display_order INT NOT NULL DEFAULT 0,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS post_reports (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            post_id INT UNSIGNED NOT NULL,
            reporter_user_id INT UNSIGNED NULL,
            reporter_name VARCHAR(190) NOT NULL,
            reason VARCHAR(190) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "new",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_post_reports_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_reports_user FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS post_comment_reports (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            comment_id INT UNSIGNED NOT NULL,
            post_id INT UNSIGNED NOT NULL,
            reporter_user_id INT UNSIGNED NULL,
            reporter_name VARCHAR(190) NOT NULL,
            reason VARCHAR(190) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "new",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_post_comment_reports_comment FOREIGN KEY (comment_id) REFERENCES post_comments(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_comment_reports_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_comment_reports_user FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS post_notifications (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            post_id INT UNSIGNED NOT NULL,
            actor_user_id INT UNSIGNED NULL,
            actor_name VARCHAR(190) NOT NULL,
            notification_type VARCHAR(20) NOT NULL,
            message VARCHAR(255) NOT NULL,
            is_read TINYINT(1) NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_post_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_notifications_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_notifications_actor FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS chat_threads (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            owner_user_id INT UNSIGNED NOT NULL,
            target_user_id INT UNSIGNED NULL,
            thread_key VARCHAR(190) NOT NULL,
            listing_group VARCHAR(20) NOT NULL DEFAULT "messages",
            thread_type VARCHAR(30) NOT NULL DEFAULT "direct",
            title VARCHAR(190) NOT NULL,
            preview_text TEXT NOT NULL,
            avatar_asset VARCHAR(255) NOT NULL,
            status_color_hex VARCHAR(20) NOT NULL DEFAULT "#34A853",
            read_style VARCHAR(20) NOT NULL DEFAULT "none",
            is_photo_preview TINYINT(1) NOT NULL DEFAULT 0,
            unread_count INT NOT NULL DEFAULT 0,
            is_system TINYINT(1) NOT NULL DEFAULT 0,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            is_deleted TINYINT(1) NOT NULL DEFAULT 0,
            display_order INT NOT NULL DEFAULT 0,
            message_date_label VARCHAR(20) NOT NULL DEFAULT "",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            UNIQUE KEY uq_chat_threads_owner_key (owner_user_id, thread_key),
            KEY idx_chat_threads_target_user (target_user_id),
            CONSTRAINT fk_chat_threads_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_chat_threads_target_user FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS chat_messages (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            thread_id INT UNSIGNED NOT NULL,
            direction VARCHAR(20) NOT NULL DEFAULT "incoming",
            sender_name VARCHAR(190) NOT NULL,
            body_text TEXT NOT NULL,
            message_type VARCHAR(20) NOT NULL DEFAULT "text",
            time_label VARCHAR(20) NOT NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_chat_messages_thread FOREIGN KEY (thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        'CREATE TABLE IF NOT EXISTS chat_search_history (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            label VARCHAR(190) NOT NULL,
            target_thread_id INT UNSIGNED NULL,
            created_at DATETIME NOT NULL,
            UNIQUE KEY uq_chat_search_history_user_label (user_id, label),
            CONSTRAINT fk_chat_search_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_chat_search_history_thread FOREIGN KEY (target_thread_id) REFERENCES chat_threads(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
      ];

foreach ($statements as $statement) {
    $pdo->exec($statement);
}

function migrate_has_column(PDO $pdo, string $driver, string $table, string $column): bool
{
    if ($driver === 'sqlite') {
        $statement = $pdo->query('PRAGMA table_info(' . $table . ')');
        $columns = $statement === false ? [] : $statement->fetchAll(PDO::FETCH_ASSOC);

        foreach ($columns as $tableColumn) {
            if (($tableColumn['name'] ?? '') === $column) {
                return true;
            }
        }

        return false;
    }

    $statement = $pdo->prepare('SHOW COLUMNS FROM `' . $table . '` LIKE :column');
    $statement->execute(['column' => $column]);
    return $statement->fetch() !== false;
}

function migrate_has_index(PDO $pdo, string $driver, string $table, string $index): bool
{
    if ($driver === 'sqlite') {
        $statement = $pdo->query('PRAGMA index_list(' . $table . ')');
        $indexes = $statement === false ? [] : $statement->fetchAll(PDO::FETCH_ASSOC);

        foreach ($indexes as $tableIndex) {
            if (($tableIndex['name'] ?? '') === $index) {
                return true;
            }
        }

        return false;
    }

    $statement = $pdo->prepare('SHOW INDEX FROM `' . $table . '` WHERE Key_name = :index_name');
    $statement->execute(['index_name' => $index]);
    return $statement->fetch() !== false;
}

function migrate_ensure_user_agency_columns(PDO $pdo, string $driver): void
{
    $definitions = $driver === 'sqlite'
        ? [
            'agency_id' => 'INTEGER NULL',
            'agency_role' => 'TEXT NULL',
            'agency_joined_at' => 'TEXT NULL',
        ]
        : [
            'agency_id' => 'INT UNSIGNED NULL',
            'agency_role' => 'VARCHAR(30) NULL',
            'agency_joined_at' => 'DATETIME NULL',
        ];

    foreach ($definitions as $column => $definition) {
        if (migrate_has_column($pdo, $driver, 'users', $column)) {
            continue;
        }

        $pdo->exec('ALTER TABLE users ADD COLUMN ' . $column . ' ' . $definition);
    }
}

function migrate_ensure_user_social_columns(PDO $pdo, string $driver): void
{
    $definitions = $driver === 'sqlite'
        ? [
            'google_sub' => 'TEXT NULL',
            'auth_provider' => 'TEXT NULL',
        ]
        : [
            'google_sub' => 'VARCHAR(191) NULL',
            'auth_provider' => 'VARCHAR(30) NULL',
        ];

    foreach ($definitions as $column => $definition) {
        if (migrate_has_column($pdo, $driver, 'users', $column)) {
            continue;
        }

        $pdo->exec('ALTER TABLE users ADD COLUMN ' . $column . ' ' . $definition);
    }

    $indexName = 'uq_users_google_sub';
    if (migrate_has_index($pdo, $driver, 'users', $indexName)) {
        return;
    }

    if ($driver === 'sqlite') {
        $pdo->exec('CREATE UNIQUE INDEX IF NOT EXISTS ' . $indexName . ' ON users (google_sub)');
        return;
    }

    $pdo->exec('CREATE UNIQUE INDEX ' . $indexName . ' ON users (google_sub)');
}

function migrate_ensure_user_profile_columns(PDO $pdo, string $driver): void
{
    $definitions = $driver === 'sqlite'
        ? [
            'avatar_asset' => 'TEXT NULL DEFAULT "assets/images/profile_avatar.png"',
            'profile_handle' => 'TEXT NULL DEFAULT "Shark.island"',
            'signature_text' => 'TEXT NULL DEFAULT "ليس لديك المقدمة الشخصية"',
            'following_count' => 'INTEGER NOT NULL DEFAULT 50',
            'followers_count' => 'INTEGER NOT NULL DEFAULT 100',
            'friends_count' => 'INTEGER NOT NULL DEFAULT 123',
            'level_current' => 'INTEGER NOT NULL DEFAULT 0',
            'level_next' => 'INTEGER NOT NULL DEFAULT 1',
            'level_progress_percent' => 'INTEGER NOT NULL DEFAULT 67',
            'vip_tier' => 'TEXT NULL DEFAULT "VIP 0"',
            'svip_tier' => 'TEXT NULL DEFAULT "SVIP 0"',
            'badges_count' => 'INTEGER NOT NULL DEFAULT 4',
            'tasks_completed' => 'INTEGER NOT NULL DEFAULT 5',
            'tasks_total' => 'INTEGER NOT NULL DEFAULT 12',
        ]
        : [
            'avatar_asset' => 'VARCHAR(255) NULL DEFAULT "assets/images/profile_avatar.png"',
            'profile_handle' => 'VARCHAR(120) NULL DEFAULT "Shark.island"',
            'signature_text' => 'VARCHAR(255) NULL DEFAULT "ليس لديك المقدمة الشخصية"',
            'following_count' => 'INT NOT NULL DEFAULT 50',
            'followers_count' => 'INT NOT NULL DEFAULT 100',
            'friends_count' => 'INT NOT NULL DEFAULT 123',
            'level_current' => 'INT NOT NULL DEFAULT 0',
            'level_next' => 'INT NOT NULL DEFAULT 1',
            'level_progress_percent' => 'INT NOT NULL DEFAULT 67',
            'vip_tier' => 'VARCHAR(40) NULL DEFAULT "VIP 0"',
            'svip_tier' => 'VARCHAR(40) NULL DEFAULT "SVIP 0"',
            'badges_count' => 'INT NOT NULL DEFAULT 4',
            'tasks_completed' => 'INT NOT NULL DEFAULT 5',
            'tasks_total' => 'INT NOT NULL DEFAULT 12',
        ];

    foreach ($definitions as $column => $definition) {
        if (migrate_has_column($pdo, $driver, 'users', $column)) {
            continue;
        }

        $pdo->exec('ALTER TABLE users ADD COLUMN ' . $column . ' ' . $definition);
    }
}

function migrate_ensure_user_settings_table(PDO $pdo, string $driver): void
{
    $statements = $driver === 'sqlite'
        ? [
            'CREATE TABLE IF NOT EXISTS user_settings (
                user_id INTEGER PRIMARY KEY,
                private_profile INTEGER NOT NULL DEFAULT 0,
                allow_direct_messages INTEGER NOT NULL DEFAULT 1,
                show_online_status INTEGER NOT NULL DEFAULT 1,
                receive_chat_notifications INTEGER NOT NULL DEFAULT 1,
                receive_live_notifications INTEGER NOT NULL DEFAULT 1,
                receive_room_invites INTEGER NOT NULL DEFAULT 1,
                receive_party_invites INTEGER NOT NULL DEFAULT 1,
                preferred_language TEXT NOT NULL DEFAULT "ar",
                updated_at TEXT NOT NULL,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            )',
        ]
        : [
            'CREATE TABLE IF NOT EXISTS user_settings (
                user_id INT UNSIGNED PRIMARY KEY,
                private_profile TINYINT(1) NOT NULL DEFAULT 0,
                allow_direct_messages TINYINT(1) NOT NULL DEFAULT 1,
                show_online_status TINYINT(1) NOT NULL DEFAULT 1,
                receive_chat_notifications TINYINT(1) NOT NULL DEFAULT 1,
                receive_live_notifications TINYINT(1) NOT NULL DEFAULT 1,
                receive_room_invites TINYINT(1) NOT NULL DEFAULT 1,
                receive_party_invites TINYINT(1) NOT NULL DEFAULT 1,
                preferred_language VARCHAR(12) NOT NULL DEFAULT "ar",
                updated_at DATETIME NOT NULL,
                CONSTRAINT fk_user_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        ];

    foreach ($statements as $statement) {
        $pdo->exec($statement);
    }
}

function migrate_ensure_user_follow_schema(PDO $pdo, string $driver): void
{
    $statements = $driver === 'sqlite'
        ? [
            'CREATE TABLE IF NOT EXISTS user_follows (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                follower_user_id INTEGER NOT NULL,
                followed_user_id INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT "active",
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                UNIQUE(follower_user_id, followed_user_id),
                FOREIGN KEY(follower_user_id) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY(followed_user_id) REFERENCES users(id) ON DELETE CASCADE
            )',
            'CREATE INDEX IF NOT EXISTS idx_user_follows_follower_status ON user_follows (follower_user_id, status)',
            'CREATE INDEX IF NOT EXISTS idx_user_follows_followed_status ON user_follows (followed_user_id, status)',
        ]
        : [
            'CREATE TABLE IF NOT EXISTS user_follows (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                follower_user_id INT UNSIGNED NOT NULL,
                followed_user_id INT UNSIGNED NOT NULL,
                status VARCHAR(20) NOT NULL DEFAULT "active",
                created_at DATETIME NOT NULL,
                updated_at DATETIME NOT NULL,
                UNIQUE KEY uq_user_follows_pair (follower_user_id, followed_user_id),
                KEY idx_user_follows_follower_status (follower_user_id, status),
                KEY idx_user_follows_followed_status (followed_user_id, status),
                CONSTRAINT fk_user_follows_follower FOREIGN KEY (follower_user_id) REFERENCES users(id) ON DELETE CASCADE,
                CONSTRAINT fk_user_follows_followed FOREIGN KEY (followed_user_id) REFERENCES users(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        ];

    foreach ($statements as $statement) {
        $pdo->exec($statement);
    }

    $chatThreadTargetDefinition = $driver === 'sqlite'
        ? 'INTEGER NULL'
        : 'INT UNSIGNED NULL';

    if (!migrate_has_column($pdo, $driver, 'chat_threads', 'target_user_id')) {
        $pdo->exec('ALTER TABLE chat_threads ADD COLUMN target_user_id ' . $chatThreadTargetDefinition);
    }

    if ($driver === 'sqlite') {
        $pdo->exec('CREATE INDEX IF NOT EXISTS idx_chat_threads_target_user ON chat_threads (target_user_id)');
    } elseif (!migrate_has_index($pdo, $driver, 'chat_threads', 'idx_chat_threads_target_user')) {
        $pdo->exec('CREATE INDEX idx_chat_threads_target_user ON chat_threads (target_user_id)');
    }
}

function migrate_ensure_post_interaction_schema(PDO $pdo, string $driver): void
{
    $postDefinitions = $driver === 'sqlite'
        ? ['shared_post_id' => 'INTEGER NULL']
        : ['shared_post_id' => 'INT UNSIGNED NULL'];

    foreach ($postDefinitions as $column => $definition) {
        if (!migrate_has_column($pdo, $driver, 'posts', $column)) {
            $pdo->exec('ALTER TABLE posts ADD COLUMN ' . $column . ' ' . $definition);
        }
    }

    $commentDefinitions = $driver === 'sqlite'
        ? [
            'author_avatar_asset' => 'TEXT NOT NULL DEFAULT "assets/images/post_author_avatar.png"',
            'status' => 'TEXT NOT NULL DEFAULT "active"',
            'report_count' => 'INTEGER NOT NULL DEFAULT 0',
            'updated_at' => 'TEXT NULL',
        ]
        : [
            'author_avatar_asset' => 'VARCHAR(255) NOT NULL DEFAULT "assets/images/post_author_avatar.png"',
            'status' => 'VARCHAR(20) NOT NULL DEFAULT "active"',
            'report_count' => 'INT NOT NULL DEFAULT 0',
            'updated_at' => 'DATETIME NULL',
        ];

    foreach ($commentDefinitions as $column => $definition) {
        if (!migrate_has_column($pdo, $driver, 'post_comments', $column)) {
            $pdo->exec('ALTER TABLE post_comments ADD COLUMN ' . $column . ' ' . $definition);
        }
    }

    $pdo->exec(
        'UPDATE post_comments
         SET author_avatar_asset = "assets/images/post_author_avatar.png"
         WHERE author_avatar_asset IS NULL OR author_avatar_asset = ""'
    );
    $pdo->exec(
        'UPDATE post_comments
         SET status = "active"
         WHERE status IS NULL OR status = ""'
    );
    $pdo->exec(
        'UPDATE post_comments
         SET updated_at = created_at
         WHERE updated_at IS NULL OR updated_at = ""'
    );

    $statements = $driver === 'sqlite'
        ? [
            'CREATE TABLE IF NOT EXISTS post_comment_reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                comment_id INTEGER NOT NULL,
                post_id INTEGER NOT NULL,
                reporter_user_id INTEGER NULL,
                reporter_name TEXT NOT NULL,
                reason TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT "new",
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(comment_id) REFERENCES post_comments(id) ON DELETE CASCADE,
                FOREIGN KEY(post_id) REFERENCES posts(id) ON DELETE CASCADE,
                FOREIGN KEY(reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
            )',
            'CREATE INDEX IF NOT EXISTS idx_posts_shared_post_id ON posts (shared_post_id)',
            'CREATE INDEX IF NOT EXISTS idx_post_comments_post_status ON post_comments (post_id, status)',
            'CREATE INDEX IF NOT EXISTS idx_post_comment_reports_status ON post_comment_reports (status)',
        ]
        : [
            'CREATE TABLE IF NOT EXISTS post_comment_reports (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                comment_id INT UNSIGNED NOT NULL,
                post_id INT UNSIGNED NOT NULL,
                reporter_user_id INT UNSIGNED NULL,
                reporter_name VARCHAR(190) NOT NULL,
                reason VARCHAR(190) NOT NULL,
                status VARCHAR(20) NOT NULL DEFAULT "new",
                created_at DATETIME NOT NULL,
                updated_at DATETIME NOT NULL,
                CONSTRAINT fk_post_comment_reports_comment FOREIGN KEY (comment_id) REFERENCES post_comments(id) ON DELETE CASCADE,
                CONSTRAINT fk_post_comment_reports_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
                CONSTRAINT fk_post_comment_reports_user FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        ];

    foreach ($statements as $statement) {
        $pdo->exec($statement);
    }

    if ($driver !== 'sqlite') {
        if (!migrate_has_index($pdo, $driver, 'posts', 'idx_posts_shared_post_id')) {
            $pdo->exec('CREATE INDEX idx_posts_shared_post_id ON posts (shared_post_id)');
        }

        if (!migrate_has_index($pdo, $driver, 'post_comments', 'idx_post_comments_post_status')) {
            $pdo->exec('CREATE INDEX idx_post_comments_post_status ON post_comments (post_id, status)');
        }

        if (!migrate_has_index($pdo, $driver, 'post_comment_reports', 'idx_post_comment_reports_status')) {
            $pdo->exec('CREATE INDEX idx_post_comment_reports_status ON post_comment_reports (status)');
        }
    }
}

function migrate_ensure_room_audio_schema(PDO $pdo, string $driver): void
{
    $roomDefinitions = $driver === 'sqlite'
        ? [
            'host_user_id' => 'INTEGER NULL',
            'audio_enabled' => 'INTEGER NOT NULL DEFAULT 1',
            'agora_channel_name' => 'TEXT NULL',
        ]
        : [
            'host_user_id' => 'INT UNSIGNED NULL',
            'audio_enabled' => 'TINYINT(1) NOT NULL DEFAULT 1',
            'agora_channel_name' => 'VARCHAR(120) NULL',
        ];

    foreach ($roomDefinitions as $column => $definition) {
        if (migrate_has_column($pdo, $driver, 'rooms', $column)) {
            continue;
        }

        $pdo->exec('ALTER TABLE rooms ADD COLUMN ' . $column . ' ' . $definition);
    }

    $statements = $driver === 'sqlite'
        ? [
            'CREATE TABLE IF NOT EXISTS room_audio_participants (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                room_id INTEGER NOT NULL,
                user_id INTEGER NULL,
                user_account TEXT NOT NULL,
                display_name TEXT NOT NULL,
                avatar_asset TEXT NULL,
                role TEXT NOT NULL DEFAULT "listener",
                seat_number INTEGER NULL,
                mic_muted INTEGER NOT NULL DEFAULT 1,
                status TEXT NOT NULL DEFAULT "joined",
                joined_at TEXT NOT NULL,
                last_seen_at TEXT NOT NULL,
                left_at TEXT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(room_id) REFERENCES rooms(id) ON DELETE CASCADE,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL,
                UNIQUE(room_id, user_account)
            )',
        ]
        : [
            'CREATE TABLE IF NOT EXISTS room_audio_participants (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                room_id INT UNSIGNED NOT NULL,
                user_id INT UNSIGNED NULL,
                user_account VARCHAR(190) NOT NULL,
                display_name VARCHAR(190) NOT NULL,
                avatar_asset VARCHAR(255) NULL,
                role VARCHAR(20) NOT NULL DEFAULT "listener",
                seat_number INT NULL,
                mic_muted TINYINT(1) NOT NULL DEFAULT 1,
                status VARCHAR(20) NOT NULL DEFAULT "joined",
                joined_at DATETIME NOT NULL,
                last_seen_at DATETIME NOT NULL,
                left_at DATETIME NULL,
                updated_at DATETIME NOT NULL,
                CONSTRAINT fk_room_audio_participants_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
                CONSTRAINT fk_room_audio_participants_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
                UNIQUE KEY uq_room_audio_participants_room_account (room_id, user_account)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        ];

    foreach ($statements as $statement) {
        $pdo->exec($statement);
    }
}

function migrate_ensure_live_rtc_schema(PDO $pdo, string $driver): void
{
    $definitions = $driver === 'sqlite'
        ? [
            'host_user_id' => 'INTEGER NULL',
            'video_enabled' => 'INTEGER NOT NULL DEFAULT 1',
            'agora_channel_name' => 'TEXT NULL',
            'ended_at' => 'TEXT NULL',
            'pk_status' => 'TEXT NOT NULL DEFAULT "idle"',
            'active_pk_invite_id' => 'INTEGER NULL',
            'pk_guest_user_id' => 'INTEGER NULL',
            'pk_guest_name' => 'TEXT NULL',
            'pk_started_at' => 'TEXT NULL',
            'pk_ends_at' => 'TEXT NULL',
        ]
        : [
            'host_user_id' => 'INT UNSIGNED NULL',
            'video_enabled' => 'TINYINT(1) NOT NULL DEFAULT 1',
            'agora_channel_name' => 'VARCHAR(120) NULL',
            'ended_at' => 'DATETIME NULL',
            'pk_status' => 'VARCHAR(20) NOT NULL DEFAULT "idle"',
            'active_pk_invite_id' => 'INT UNSIGNED NULL',
            'pk_guest_user_id' => 'INT UNSIGNED NULL',
            'pk_guest_name' => 'VARCHAR(190) NULL',
            'pk_started_at' => 'DATETIME NULL',
            'pk_ends_at' => 'DATETIME NULL',
        ];

    foreach ($definitions as $column => $definition) {
        if (migrate_has_column($pdo, $driver, 'live_rooms', $column)) {
            continue;
        }

        $pdo->exec('ALTER TABLE live_rooms ADD COLUMN ' . $column . ' ' . $definition);
    }

    $pdo->exec(
        "UPDATE live_rooms
         SET agora_channel_name = " . ($driver === 'sqlite'
            ? "'live-room-' || id"
            : "CONCAT('live-room-', id)") . "
         WHERE agora_channel_name IS NULL OR agora_channel_name = ''"
    );

    $viewerDefinitions = $driver === 'sqlite'
        ? [
            'user_id' => 'INTEGER NULL',
            'user_account' => 'TEXT NULL',
            'client_role' => 'TEXT NOT NULL DEFAULT "audience"',
            'is_online' => 'INTEGER NOT NULL DEFAULT 0',
            'last_seen_at' => 'TEXT NULL',
            'left_at' => 'TEXT NULL',
            'updated_at' => 'TEXT NULL',
        ]
        : [
            'user_id' => 'INT UNSIGNED NULL',
            'user_account' => 'VARCHAR(120) NULL',
            'client_role' => 'VARCHAR(30) NOT NULL DEFAULT "audience"',
            'is_online' => 'TINYINT(1) NOT NULL DEFAULT 0',
            'last_seen_at' => 'DATETIME NULL',
            'left_at' => 'DATETIME NULL',
            'updated_at' => 'DATETIME NULL',
        ];

    foreach ($viewerDefinitions as $column => $definition) {
        if (migrate_has_column($pdo, $driver, 'live_room_viewers', $column)) {
            continue;
        }

        $pdo->exec('ALTER TABLE live_room_viewers ADD COLUMN ' . $column . ' ' . $definition);
    }
}

function migrate_ensure_gift_media_schema(PDO $pdo, string $driver): void
{
    $definitions = $driver === 'sqlite'
        ? [
            'animation_path' => 'TEXT NULL',
            'sound_path' => 'TEXT NULL',
            'is_animated' => 'INTEGER NOT NULL DEFAULT 0',
            'effect_duration_ms' => 'INTEGER NOT NULL DEFAULT 1800',
        ]
        : [
            'animation_path' => 'VARCHAR(255) NULL',
            'sound_path' => 'VARCHAR(255) NULL',
            'is_animated' => 'TINYINT(1) NOT NULL DEFAULT 0',
            'effect_duration_ms' => 'INT NOT NULL DEFAULT 1800',
        ];

    foreach ($definitions as $column => $definition) {
        if (migrate_has_column($pdo, $driver, 'gifts', $column)) {
            continue;
        }

        $pdo->exec('ALTER TABLE gifts ADD COLUMN ' . $column . ' ' . $definition);
    }

    $pdo->exec(
        'UPDATE gifts
         SET is_animated = CASE WHEN category = "متحرك" THEN 1 ELSE COALESCE(is_animated, 0) END,
             effect_duration_ms = CASE WHEN effect_duration_ms IS NULL OR effect_duration_ms < 600 THEN 1800 ELSE effect_duration_ms END
         WHERE is_animated IS NULL OR effect_duration_ms IS NULL OR effect_duration_ms < 600 OR category = "متحرك"'
    );
}

function migrate_ensure_gift_monetization_schema(PDO $pdo, string $driver): void
{
    if ($driver === 'sqlite') {
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS app_settings (
                setting_key TEXT PRIMARY KEY,
                setting_value TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )'
        );
    } else {
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS app_settings (
                setting_key VARCHAR(120) PRIMARY KEY,
                setting_value TEXT NOT NULL,
                updated_at DATETIME NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
        );
    }

    $definitions = $driver === 'sqlite'
        ? [
            'recipient_user_id' => 'INTEGER NULL',
            'recipient_name_snapshot' => 'TEXT NULL',
            'platform_fee_coins' => 'INTEGER NOT NULL DEFAULT 0',
            'creator_earning_diamonds' => 'INTEGER NOT NULL DEFAULT 0',
            'platform_commission_percent' => 'REAL NOT NULL DEFAULT 50',
        ]
        : [
            'recipient_user_id' => 'INT UNSIGNED NULL',
            'recipient_name_snapshot' => 'VARCHAR(190) NULL',
            'platform_fee_coins' => 'INT NOT NULL DEFAULT 0',
            'creator_earning_diamonds' => 'INT NOT NULL DEFAULT 0',
            'platform_commission_percent' => 'DECIMAL(5,2) NOT NULL DEFAULT 50.00',
        ];

    foreach (['room_gift_transactions', 'live_room_gift_transactions'] as $table) {
        foreach ($definitions as $column => $definition) {
            if (migrate_has_column($pdo, $driver, $table, $column)) {
                continue;
            }

            $pdo->exec('ALTER TABLE ' . $table . ' ADD COLUMN ' . $column . ' ' . $definition);
        }
    }

    $now = gmdate('Y-m-d H:i:s');
    if ($driver === 'sqlite') {
        $statement = $pdo->prepare(
            'INSERT INTO app_settings (setting_key, setting_value, updated_at)
             VALUES (:setting_key, :setting_value, :updated_at)
             ON CONFLICT(setting_key) DO NOTHING'
        );
    } else {
        $statement = $pdo->prepare(
            'INSERT IGNORE INTO app_settings (setting_key, setting_value, updated_at)
             VALUES (:setting_key, :setting_value, :updated_at)'
        );
    }
    $statement->execute([
        'setting_key' => 'gift_platform_commission_percent',
        'setting_value' => '50',
        'updated_at' => $now,
    ]);
}

function migrate_ensure_room_creation_columns(PDO $pdo, string $driver): void
{
    $definitions = $driver === 'sqlite'
        ? [
            'creator_user_id' => 'INTEGER NULL',
            'room_type' => 'TEXT NOT NULL DEFAULT "غناء"',
            'slogan_text' => 'TEXT NULL',
            'country_label' => 'TEXT NOT NULL DEFAULT "مصر"',
        ]
        : [
            'creator_user_id' => 'INT UNSIGNED NULL',
            'room_type' => 'VARCHAR(40) NOT NULL DEFAULT "غناء"',
            'slogan_text' => 'VARCHAR(255) NULL',
            'country_label' => 'VARCHAR(120) NOT NULL DEFAULT "مصر"',
        ];

    foreach ($definitions as $column => $definition) {
        if (migrate_has_column($pdo, $driver, 'rooms', $column)) {
            continue;
        }

        $pdo->exec('ALTER TABLE rooms ADD COLUMN ' . $column . ' ' . $definition);
    }
}

function migrate_ensure_agency_tables(PDO $pdo, string $driver): void
{
    $statements = $driver === 'sqlite'
        ? [
            'CREATE TABLE IF NOT EXISTS agencies (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                owner_user_id INTEGER NULL,
                name TEXT NOT NULL,
                invitation_code TEXT NOT NULL UNIQUE,
                country TEXT NOT NULL,
                phone TEXT NOT NULL,
                address TEXT NOT NULL,
                avatar_path TEXT,
                front_id_path TEXT,
                back_id_path TEXT,
                status TEXT NOT NULL DEFAULT "active",
                member_count INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(owner_user_id) REFERENCES users(id) ON DELETE SET NULL
            )',
            'CREATE TABLE IF NOT EXISTS agency_open_requests (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                request_code TEXT NOT NULL UNIQUE,
                user_id INTEGER NULL,
                agency_name TEXT NOT NULL,
                country TEXT NOT NULL,
                phone TEXT NOT NULL,
                address TEXT NOT NULL,
                avatar_path TEXT,
                front_id_path TEXT,
                back_id_path TEXT,
                status TEXT NOT NULL DEFAULT "new",
                admin_note TEXT,
                agency_id INTEGER NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL,
                FOREIGN KEY(agency_id) REFERENCES agencies(id) ON DELETE SET NULL
            )',
            'CREATE TABLE IF NOT EXISTS agency_join_requests (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                request_code TEXT NOT NULL UNIQUE,
                user_id INTEGER NULL,
                agency_id INTEGER NULL,
                invitation_code TEXT NOT NULL,
                agency_name_snapshot TEXT,
                agency_type TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT "new",
                admin_note TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL,
                FOREIGN KEY(agency_id) REFERENCES agencies(id) ON DELETE SET NULL
            )',
        ]
        : [
            'CREATE TABLE IF NOT EXISTS agencies (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                owner_user_id INT UNSIGNED NULL,
                name VARCHAR(190) NOT NULL,
                invitation_code VARCHAR(120) NOT NULL UNIQUE,
                country VARCHAR(120) NOT NULL,
                phone VARCHAR(80) NOT NULL,
                address VARCHAR(255) NOT NULL,
                avatar_path VARCHAR(255) NULL,
                front_id_path VARCHAR(255) NULL,
                back_id_path VARCHAR(255) NULL,
                status VARCHAR(30) NOT NULL DEFAULT "active",
                member_count INT NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL,
                updated_at DATETIME NOT NULL,
                CONSTRAINT fk_agencies_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
            'CREATE TABLE IF NOT EXISTS agency_open_requests (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                request_code VARCHAR(120) NOT NULL UNIQUE,
                user_id INT UNSIGNED NULL,
                agency_name VARCHAR(190) NOT NULL,
                country VARCHAR(120) NOT NULL,
                phone VARCHAR(80) NOT NULL,
                address VARCHAR(255) NOT NULL,
                avatar_path VARCHAR(255) NULL,
                front_id_path VARCHAR(255) NULL,
                back_id_path VARCHAR(255) NULL,
                status VARCHAR(30) NOT NULL DEFAULT "new",
                admin_note TEXT NULL,
                agency_id INT UNSIGNED NULL,
                created_at DATETIME NOT NULL,
                updated_at DATETIME NOT NULL,
                CONSTRAINT fk_agency_open_requests_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
                CONSTRAINT fk_agency_open_requests_agency FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE SET NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
            'CREATE TABLE IF NOT EXISTS agency_join_requests (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                request_code VARCHAR(120) NOT NULL UNIQUE,
                user_id INT UNSIGNED NULL,
                agency_id INT UNSIGNED NULL,
                invitation_code VARCHAR(120) NOT NULL,
                agency_name_snapshot VARCHAR(190) NULL,
                agency_type VARCHAR(60) NOT NULL,
                status VARCHAR(30) NOT NULL DEFAULT "new",
                admin_note TEXT NULL,
                created_at DATETIME NOT NULL,
                updated_at DATETIME NOT NULL,
                CONSTRAINT fk_agency_join_requests_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
                CONSTRAINT fk_agency_join_requests_agency FOREIGN KEY (agency_id) REFERENCES agencies(id) ON DELETE SET NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
        ];

    foreach ($statements as $statement) {
        $pdo->exec($statement);
    }
}

migrate_ensure_user_agency_columns($pdo, $driver);
migrate_ensure_user_social_columns($pdo, $driver);
migrate_ensure_user_profile_columns($pdo, $driver);
migrate_ensure_user_settings_table($pdo, $driver);
migrate_ensure_user_follow_schema($pdo, $driver);
migrate_ensure_post_interaction_schema($pdo, $driver);
migrate_ensure_room_audio_schema($pdo, $driver);
migrate_ensure_live_rtc_schema($pdo, $driver);
migrate_ensure_gift_media_schema($pdo, $driver);
migrate_ensure_gift_monetization_schema($pdo, $driver);
migrate_ensure_room_creation_columns($pdo, $driver);
migrate_ensure_agency_tables($pdo, $driver);

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
            'room_type' => 'دردشة',
            'slogan_text' => 'ابحث عن شخص يمكنه الدردشه معي هالحين',
            'country_label' => 'مصر',
            'host_name' => 'محمد أحمد',
            'room_code' => '1512345412',
            'card_image_asset' => 'assets/images/home_room_service.png',
            'meta_icon_asset' => 'assets/images/home_pin_icon.png',
            'host_avatar_asset' => 'assets/images/profile_avatar.png',
            'listener_count' => 30,
            'mic_count' => 9,
            'background_asset' => 'assets/images/room_background.jpg',
            'audio_enabled' => 1,
            'agora_channel_name' => 'voice-room-1512345412',
            'display_order' => 1,
        ],
        [
            'card_title' => 'خدمة العملاء',
            'room_title' => 'غرفة الدعم المباشر',
            'subtitle' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'room_type' => 'دردشة',
            'slogan_text' => 'ابحث عن شخص يمكنه الدردشه معي هالحين',
            'country_label' => 'مصر',
            'host_name' => 'محمد أحمد',
            'room_code' => '1512345413',
            'card_image_asset' => 'assets/images/home_room_service.png',
            'meta_icon_asset' => 'assets/images/home_pin_icon.png',
            'host_avatar_asset' => 'assets/images/profile_avatar.png',
            'listener_count' => 30,
            'mic_count' => 9,
            'background_asset' => 'assets/images/room_background.jpg',
            'audio_enabled' => 1,
            'agora_channel_name' => 'voice-room-1512345413',
            'display_order' => 2,
        ],
        [
            'card_title' => 'وكالة ولاد الملوك',
            'room_title' => 'وكالة ولاد الملوك',
            'subtitle' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'room_type' => 'عائلة',
            'slogan_text' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'country_label' => 'مصر',
            'host_name' => 'محمد أحمد',
            'room_code' => '1512345414',
            'card_image_asset' => 'assets/images/home_room_1.png',
            'meta_icon_asset' => 'assets/images/home_egypt_flag.png',
            'host_avatar_asset' => 'assets/images/profile_avatar.png',
            'listener_count' => 30,
            'mic_count' => 9,
            'background_asset' => 'assets/images/room_background.jpg',
            'audio_enabled' => 1,
            'agora_channel_name' => 'voice-room-1512345414',
            'display_order' => 3,
        ],
        [
            'card_title' => 'وكالة ولاد الملوك',
            'room_title' => 'وكالة ولاد الملوك',
            'subtitle' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'room_type' => 'عائلة',
            'slogan_text' => 'اهلا وسهلا بكم في روم مصر ام الدنيا',
            'country_label' => 'مصر',
            'host_name' => 'محمد أحمد',
            'room_code' => '1512345415',
            'card_image_asset' => 'assets/images/home_room_2.png',
            'meta_icon_asset' => 'assets/images/home_egypt_flag.png',
            'host_avatar_asset' => 'assets/images/profile_avatar.png',
            'listener_count' => 30,
            'mic_count' => 9,
            'background_asset' => 'assets/images/room_background.jpg',
            'audio_enabled' => 1,
            'agora_channel_name' => 'voice-room-1512345415',
            'display_order' => 4,
        ],
    ];

    $insertRoom = $pdo->prepare(
        'INSERT INTO rooms
            (card_title, room_title, subtitle, host_name, host_user_id, creator_user_id, room_type, slogan_text, country_label, room_code, card_image_asset, meta_icon_asset, host_avatar_asset, listener_count, mic_count, background_asset, audio_enabled, agora_channel_name, status, display_order, created_at, updated_at)
         VALUES
            (:card_title, :room_title, :subtitle, :host_name, :host_user_id, :creator_user_id, :room_type, :slogan_text, :country_label, :room_code, :card_image_asset, :meta_icon_asset, :host_avatar_asset, :listener_count, :mic_count, :background_asset, :audio_enabled, :agora_channel_name, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedRooms as $room) {
        $insertRoom->execute([
            ...$room,
            'host_user_id' => null,
            'creator_user_id' => null,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$liveRoomsCount = (int) $pdo->query('SELECT COUNT(*) FROM live_rooms')->fetchColumn();
if ($liveRoomsCount === 0) {
    $seedLiveRooms = [
        [
            'title' => 'مداهم 777',
            'host_name' => 'Mohamed Ahmed',
            'host_id_label' => 'ID:1512345412',
            'poster_asset' => 'assets/images/home149_card1.png',
            'listing_scope' => 'live',
            'viewer_count' => 393,
            'coin_count' => 214,
            'display_order' => 1,
        ],
        [
            'title' => 'هاي عاملين ايه',
            'host_name' => 'Sara Mohamed',
            'host_id_label' => 'ID:1512345413',
            'poster_asset' => 'assets/images/home149_card2.png',
            'listing_scope' => 'friends',
            'viewer_count' => 188,
            'coin_count' => 84,
            'display_order' => 2,
        ],
        [
            'title' => 'مساء الخير يا جماعة',
            'host_name' => 'Nour Salem',
            'host_id_label' => 'ID:1512345414',
            'poster_asset' => 'assets/images/home149_card3.png',
            'listing_scope' => 'newest',
            'viewer_count' => 126,
            'coin_count' => 45,
            'display_order' => 3,
        ],
        [
            'title' => 'لايف بنات مصر',
            'host_name' => 'Nona Mohamed',
            'host_id_label' => 'ID:1512345415',
            'poster_asset' => 'assets/images/home149_card4.png',
            'listing_scope' => 'friends',
            'viewer_count' => 210,
            'coin_count' => 120,
            'display_order' => 4,
        ],
        [
            'title' => 'سهرة اليوم',
            'host_name' => 'Ahmed Ali',
            'host_id_label' => 'ID:1512345416',
            'poster_asset' => 'assets/images/home149_card7.png',
            'listing_scope' => 'live',
            'viewer_count' => 95,
            'coin_count' => 38,
            'display_order' => 5,
        ],
        [
            'title' => 'نجوم اللايف',
            'host_name' => 'Yara Mohamed',
            'host_id_label' => 'ID:1512345417',
            'poster_asset' => 'assets/images/home149_card8.png',
            'listing_scope' => 'newest',
            'viewer_count' => 241,
            'coin_count' => 133,
            'display_order' => 6,
        ],
    ];

    $insertLiveRoom = $pdo->prepare(
        'INSERT INTO live_rooms
            (title, host_name, host_id_label, host_user_id, video_enabled, agora_channel_name, poster_asset, background_asset, left_video_asset, right_video_asset, viewer_count, coin_count, battle_timer_label, listing_scope, contribution_diamonds_total, contribution_sender_count, pk_talk_permission, pk_party_invite_permission, pk_voice_room_invite_permission, pk_chat_permission, pk_battle_duration, status, display_order, ended_at, created_at, updated_at)
         VALUES
            (:title, :host_name, :host_id_label, :host_user_id, :video_enabled, :agora_channel_name, :poster_asset, :background_asset, :left_video_asset, :right_video_asset, :viewer_count, :coin_count, :battle_timer_label, :listing_scope, :contribution_diamonds_total, :contribution_sender_count, :pk_talk_permission, :pk_party_invite_permission, :pk_voice_room_invite_permission, :pk_chat_permission, :pk_battle_duration, :status, :display_order, :ended_at, :created_at, :updated_at)'
    );

    foreach ($seedLiveRooms as $room) {
        $insertLiveRoom->execute([
            ...$room,
            'host_user_id' => null,
            'video_enabled' => 1,
            'agora_channel_name' => 'live-room-' . $room['display_order'],
            'background_asset' => 'assets/images/live150_background.png',
            'left_video_asset' => 'assets/images/live150_video_left.png',
            'right_video_asset' => 'assets/images/live150_video_right.png',
            'battle_timer_label' => '11:50',
            'contribution_diamonds_total' => 100,
            'contribution_sender_count' => 100,
            'pk_talk_permission' => 'عند الطلب',
            'pk_party_invite_permission' => 'عند الطلب',
            'pk_voice_room_invite_permission' => 'عند الطلب',
            'pk_chat_permission' => 'عند الطلب',
            'pk_battle_duration' => '30د',
            'status' => 'active',
            'ended_at' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$liveViewerCount = (int) $pdo->query('SELECT COUNT(*) FROM live_room_viewers')->fetchColumn();
if ($liveViewerCount === 0) {
    $seedLiveViewers = [
        ['room_id' => 1, 'rank_order' => 1, 'viewer_name' => 'Mohammed Ahmed', 'is_top_supporter' => 1],
        ['room_id' => 1, 'rank_order' => 2, 'viewer_name' => 'Sara Mohamed', 'is_top_supporter' => 0],
        ['room_id' => 1, 'rank_order' => 3, 'viewer_name' => 'Nona Mohamed', 'is_top_supporter' => 0],
        ['room_id' => 1, 'rank_order' => 4, 'viewer_name' => 'Yara Mohamed', 'is_top_supporter' => 0],
        ['room_id' => 2, 'rank_order' => 1, 'viewer_name' => 'Mohammed Ahmed', 'is_top_supporter' => 1],
        ['room_id' => 2, 'rank_order' => 2, 'viewer_name' => 'Ahmed Ali', 'is_top_supporter' => 0],
    ];

    $insertViewer = $pdo->prepare(
        'INSERT INTO live_room_viewers
            (room_id, user_id, user_account, client_role, rank_order, viewer_name, avatar_asset, is_top_supporter, is_online, last_seen_at, left_at, created_at, updated_at)
         VALUES
            (:room_id, :user_id, :user_account, :client_role, :rank_order, :viewer_name, :avatar_asset, :is_top_supporter, :is_online, :last_seen_at, :left_at, :created_at, :updated_at)'
    );

    foreach ($seedLiveViewers as $viewer) {
        $insertViewer->execute([
            ...$viewer,
            'user_id' => null,
            'user_account' => null,
            'client_role' => 'audience',
            'avatar_asset' => 'assets/images/live150_comment_avatar.png',
            'is_online' => 0,
            'last_seen_at' => null,
            'left_at' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$liveCommentsCount = (int) $pdo->query('SELECT COUNT(*) FROM live_room_comments')->fetchColumn();
if ($liveCommentsCount === 0) {
    $seedLiveComments = [
        ['room_id' => 1, 'commenter_name' => 'Mohamed Ahmed', 'message_text' => 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات', 'display_order' => 1],
        ['room_id' => 1, 'commenter_name' => 'Sara Mohamed', 'message_text' => 'لايف جميل جدا استمروا', 'display_order' => 2],
        ['room_id' => 1, 'commenter_name' => 'Nona Mohamed', 'message_text' => 'احلي بنات واحلي جو', 'display_order' => 3],
        ['room_id' => 1, 'commenter_name' => 'Yara Mohamed', 'message_text' => 'مساء الخير عليكم', 'display_order' => 4],
        ['room_id' => 2, 'commenter_name' => 'Mohamed Ahmed', 'message_text' => 'هاي عاملين ايه', 'display_order' => 1],
        ['room_id' => 2, 'commenter_name' => 'Ahmed Ali', 'message_text' => 'منورين اللايف', 'display_order' => 2],
    ];

    $insertComment = $pdo->prepare(
        'INSERT INTO live_room_comments
            (room_id, commenter_name, avatar_asset, message_text, display_order, created_at)
         VALUES
            (:room_id, :commenter_name, :avatar_asset, :message_text, :display_order, :created_at)'
    );

    foreach ($seedLiveComments as $comment) {
        $insertComment->execute([
            ...$comment,
            'avatar_asset' => 'assets/images/live150_comment_avatar.png',
            'created_at' => $now,
        ]);
    }
}

$liveNotificationsCount = (int) $pdo->query('SELECT COUNT(*) FROM live_room_notifications')->fetchColumn();
if ($liveNotificationsCount === 0) {
    $seedLiveNotifications = [
        ['room_id' => 1, 'title_text' => 'اعلان الجولة', 'body_text' => 'ابدأوا التفاعل الآن والجولة الحالية مفتوحة لمدة 15 دقيقة.', 'display_order' => 1],
        ['room_id' => 1, 'title_text' => 'تنبيه اداري', 'body_text' => 'يمنع نشر أي محتوى مخالف داخل الدردشة المباشرة.', 'display_order' => 2],
        ['room_id' => 2, 'title_text' => 'ترحيب', 'body_text' => 'أهلًا بكل المشاهدين الجدد في اللايف الحالي.', 'display_order' => 1],
    ];

    $insertLiveNotification = $pdo->prepare(
        'INSERT INTO live_room_notifications
            (room_id, title_text, body_text, status, display_order, created_at, updated_at)
         VALUES
            (:room_id, :title_text, :body_text, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedLiveNotifications as $notification) {
        $insertLiveNotification->execute([
            ...$notification,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$demoUsers = [
    [
        'email' => 'yara.store@voicelive.local',
        'phone' => '201000000101',
        'nickname' => 'Yara Mohamed',
        'gender' => 'woman',
        'country' => 'Egypt',
        'birthdate' => '1996-04-10',
    ],
    [
        'email' => 'nona.store@voicelive.local',
        'phone' => '201000000102',
        'nickname' => 'Nona Mohamed',
        'gender' => 'woman',
        'country' => 'Egypt',
        'birthdate' => '1997-06-18',
    ],
    [
        'email' => 'mohamed.store@voicelive.local',
        'phone' => '201000000103',
        'nickname' => 'Mohamed Ahmed',
        'gender' => 'man',
        'country' => 'Egypt',
        'birthdate' => '1995-02-03',
    ],
];

$findDemoUser = $pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
$insertDemoUser = $pdo->prepare(
    'INSERT INTO users
        (email, phone, password_hash, nickname, birthdate, gender, country, status, email_verified_at, phone_verified_at, created_at, updated_at)
     VALUES
        (:email, :phone, :password_hash, :nickname, :birthdate, :gender, :country, :status, :email_verified_at, :phone_verified_at, :created_at, :updated_at)'
);

foreach ($demoUsers as $demoUser) {
    $findDemoUser->execute(['email' => $demoUser['email']]);
    if ($findDemoUser->fetch() !== false) {
        continue;
    }

    $insertDemoUser->execute([
        ...$demoUser,
        'password_hash' => password_hash('secret123', PASSWORD_DEFAULT),
        'status' => 'active',
        'email_verified_at' => $now,
        'phone_verified_at' => $now,
        'created_at' => $now,
        'updated_at' => $now,
    ]);
}

$pdo->exec(
    "UPDATE users
     SET avatar_asset = COALESCE(avatar_asset, 'assets/images/profile_avatar.png'),
         profile_handle = COALESCE(profile_handle, 'Shark.island'),
         signature_text = COALESCE(signature_text, 'ليس لديك المقدمة الشخصية'),
         following_count = COALESCE(following_count, 50),
         followers_count = COALESCE(followers_count, 100),
         friends_count = COALESCE(friends_count, 123),
         level_current = COALESCE(level_current, 0),
         level_next = COALESCE(level_next, 1),
         level_progress_percent = COALESCE(level_progress_percent, 67),
         vip_tier = COALESCE(vip_tier, 'VIP 0'),
         svip_tier = COALESCE(svip_tier, 'SVIP 0'),
         badges_count = COALESCE(badges_count, 4),
         tasks_completed = COALESCE(tasks_completed, 5),
         tasks_total = COALESCE(tasks_total, 12)"
);

$usersWithoutSettings = $pdo->query('SELECT id FROM users WHERE id NOT IN (SELECT user_id FROM user_settings)')->fetchAll(PDO::FETCH_COLUMN);
if ($usersWithoutSettings !== []) {
    $insertSettings = $pdo->prepare(
        'INSERT INTO user_settings
            (user_id, private_profile, allow_direct_messages, show_online_status, receive_chat_notifications, receive_live_notifications, receive_room_invites, receive_party_invites, preferred_language, updated_at)
         VALUES
            (:user_id, :private_profile, :allow_direct_messages, :show_online_status, :receive_chat_notifications, :receive_live_notifications, :receive_room_invites, :receive_party_invites, :preferred_language, :updated_at)'
    );

    foreach ($usersWithoutSettings as $settingsUserId) {
        $insertSettings->execute([
            'user_id' => (int) $settingsUserId,
            'private_profile' => 0,
            'allow_direct_messages' => 1,
            'show_online_status' => 1,
            'receive_chat_notifications' => 1,
            'receive_live_notifications' => 1,
            'receive_room_invites' => 1,
            'receive_party_invites' => 1,
            'preferred_language' => 'ar',
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

$defaultHostStatement = $pdo->prepare(
    "SELECT id, nickname, avatar_asset
     FROM users
     WHERE email = 'mohamed.store@voicelive.local'
     LIMIT 1"
);
$defaultHostStatement->execute();
$defaultHost = $defaultHostStatement->fetch();

if ($defaultHost !== false) {
    $roomHostStatement = $pdo->prepare(
        'UPDATE rooms
         SET host_user_id = COALESCE(host_user_id, :host_user_id),
             creator_user_id = COALESCE(creator_user_id, :creator_user_id),
             room_type = COALESCE(NULLIF(room_type, \'\'), :room_type),
             slogan_text = COALESCE(NULLIF(slogan_text, \'\'), subtitle),
             country_label = COALESCE(NULLIF(country_label, \'\'), :country_label),
             host_name = COALESCE(NULLIF(host_name, \'\'), :host_name),
             host_avatar_asset = COALESCE(NULLIF(host_avatar_asset, \'\'), :host_avatar_asset),
             audio_enabled = COALESCE(audio_enabled, 1),
             agora_channel_name = COALESCE(agora_channel_name, :agora_channel_name),
             updated_at = :updated_at
         WHERE id = :id'
    );

    $roomsForHost = $pdo->query('SELECT id, room_code FROM rooms')->fetchAll();
    foreach ($roomsForHost as $hostRoom) {
        $roomCode = preg_replace('/[^a-zA-Z0-9]/', '', (string) ($hostRoom['room_code'] ?? '')) ?: (string) $hostRoom['id'];
        $roomHostStatement->execute([
            'host_user_id' => (int) $defaultHost['id'],
            'creator_user_id' => (int) $defaultHost['id'],
            'room_type' => 'غناء',
            'country_label' => 'مصر',
            'host_name' => (string) ($defaultHost['nickname'] ?? 'Mohamed Ahmed'),
            'host_avatar_asset' => (string) ($defaultHost['avatar_asset'] ?? 'assets/images/profile_avatar.png'),
            'agora_channel_name' => 'voice-room-' . $roomCode,
            'updated_at' => $now,
            'id' => (int) $hostRoom['id'],
        ]);
    }
}

$agencyUsers = [];
$agencyUsersStatement = $pdo->query(
    "SELECT id, email, nickname
     FROM users
     WHERE email IN ('mohamed.store@voicelive.local', 'yara.store@voicelive.local', 'nona.store@voicelive.local')"
);
if ($agencyUsersStatement !== false) {
    foreach ($agencyUsersStatement->fetchAll(PDO::FETCH_ASSOC) as $agencyUser) {
        $agencyUsers[(string) $agencyUser['email']] = $agencyUser;
    }
}

$seedFollowPair = static function (string $followerEmail, string $followedEmail) use ($pdo, $agencyUsers, $now): void {
    $follower = $agencyUsers[$followerEmail] ?? null;
    $followed = $agencyUsers[$followedEmail] ?? null;

    if ($follower === null || $followed === null) {
        return;
    }

    $followerId = (int) $follower['id'];
    $followedId = (int) $followed['id'];

    if ($followerId < 1 || $followedId < 1 || $followerId === $followedId) {
        return;
    }

    $existingFollow = $pdo->prepare(
        'SELECT id
         FROM user_follows
         WHERE follower_user_id = :follower_user_id
           AND followed_user_id = :followed_user_id
         LIMIT 1'
    );
    $existingFollow->execute([
        'follower_user_id' => $followerId,
        'followed_user_id' => $followedId,
    ]);
    $row = $existingFollow->fetch();

    if ($row === false) {
        $insertFollow = $pdo->prepare(
            'INSERT INTO user_follows
                (follower_user_id, followed_user_id, status, created_at, updated_at)
             VALUES
                (:follower_user_id, :followed_user_id, :status, :created_at, :updated_at)'
        );
        $insertFollow->execute([
            'follower_user_id' => $followerId,
            'followed_user_id' => $followedId,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
        return;
    }

    $updateFollow = $pdo->prepare(
        'UPDATE user_follows
         SET status = :status,
             updated_at = :updated_at
         WHERE id = :id'
    );
    $updateFollow->execute([
        'status' => 'active',
        'updated_at' => $now,
        'id' => (int) $row['id'],
    ]);
};

$seedFollowPair('mohamed.store@voicelive.local', 'yara.store@voicelive.local');
$seedFollowPair('yara.store@voicelive.local', 'mohamed.store@voicelive.local');
$seedFollowPair('mohamed.store@voicelive.local', 'nona.store@voicelive.local');
$seedFollowPair('nona.store@voicelive.local', 'mohamed.store@voicelive.local');
$seedFollowPair('yara.store@voicelive.local', 'nona.store@voicelive.local');

$syncUserSocialCounters = $pdo->prepare(
    'UPDATE users
     SET following_count = (
            SELECT COUNT(*)
            FROM user_follows
            WHERE follower_user_id = :following_user_id
              AND status = "active"
         ),
         followers_count = (
            SELECT COUNT(*)
            FROM user_follows
            WHERE followed_user_id = :followers_user_id
              AND status = "active"
         ),
         friends_count = (
            SELECT COUNT(*)
            FROM user_follows outgoing
            INNER JOIN user_follows incoming
                ON incoming.follower_user_id = outgoing.followed_user_id
               AND incoming.followed_user_id = outgoing.follower_user_id
               AND incoming.status = "active"
            WHERE outgoing.follower_user_id = :friends_user_id
              AND outgoing.status = "active"
         )
     WHERE id = :id'
);
foreach ($pdo->query('SELECT id FROM users')->fetchAll(PDO::FETCH_COLUMN) as $socialUserId) {
    $syncUserSocialCounters->execute([
        'following_user_id' => (int) $socialUserId,
        'followers_user_id' => (int) $socialUserId,
        'friends_user_id' => (int) $socialUserId,
        'id' => (int) $socialUserId,
    ]);
}

$liveHostSync = $pdo->prepare(
    'UPDATE live_rooms
     SET host_user_id = :host_user_id,
         updated_at = :updated_at
     WHERE host_name = :host_name
       AND (host_user_id IS NULL OR host_user_id = 0)'
);
foreach ($agencyUsers as $agencyUser) {
    $liveHostSync->execute([
        'host_user_id' => (int) $agencyUser['id'],
        'updated_at' => $now,
        'host_name' => (string) ($agencyUser['nickname'] ?? ''),
    ]);
}

$agenciesCount = (int) $pdo->query('SELECT COUNT(*) FROM agencies')->fetchColumn();
$seedAgencyId = null;
if ($agenciesCount === 0 && isset($agencyUsers['mohamed.store@voicelive.local'])) {
    $insertAgency = $pdo->prepare(
        'INSERT INTO agencies
            (owner_user_id, name, invitation_code, country, phone, address, avatar_path, front_id_path, back_id_path, status, member_count, created_at, updated_at)
         VALUES
            (:owner_user_id, :name, :invitation_code, :country, :phone, :address, :avatar_path, :front_id_path, :back_id_path, :status, :member_count, :created_at, :updated_at)'
    );
    $insertAgency->execute([
        'owner_user_id' => (int) $agencyUsers['mohamed.store@voicelive.local']['id'],
        'name' => 'وكالة النخبة',
        'invitation_code' => 'VL-AGY-2026',
        'country' => 'مصر',
        'phone' => '201011223344',
        'address' => 'القاهرة - مدينة نصر',
        'avatar_path' => null,
        'front_id_path' => null,
        'back_id_path' => null,
        'status' => 'active',
        'member_count' => 1,
        'created_at' => $now,
        'updated_at' => $now,
    ]);
    $seedAgencyId = (int) $pdo->lastInsertId();

    $assignOwner = $pdo->prepare(
        'UPDATE users
         SET agency_id = :agency_id,
             agency_role = :agency_role,
             agency_joined_at = :agency_joined_at,
             updated_at = :updated_at
         WHERE id = :id'
    );
    $assignOwner->execute([
        'agency_id' => $seedAgencyId,
        'agency_role' => 'owner',
        'agency_joined_at' => $now,
        'updated_at' => $now,
        'id' => (int) $agencyUsers['mohamed.store@voicelive.local']['id'],
    ]);
} else {
    $seedAgencyLookup = $pdo->query('SELECT id FROM agencies ORDER BY id ASC LIMIT 1');
    if ($seedAgencyLookup !== false) {
        $seedAgencyId = (int) ($seedAgencyLookup->fetchColumn() ?: 0);
    }
}

$agencyOpenRequestsCount = (int) $pdo->query('SELECT COUNT(*) FROM agency_open_requests')->fetchColumn();
if ($agencyOpenRequestsCount === 0 && isset($agencyUsers['yara.store@voicelive.local'])) {
    $insertOpenRequest = $pdo->prepare(
        'INSERT INTO agency_open_requests
            (request_code, user_id, agency_name, country, phone, address, avatar_path, front_id_path, back_id_path, status, admin_note, agency_id, created_at, updated_at)
         VALUES
            (:request_code, :user_id, :agency_name, :country, :phone, :address, :avatar_path, :front_id_path, :back_id_path, :status, :admin_note, :agency_id, :created_at, :updated_at)'
    );
    $insertOpenRequest->execute([
        'request_code' => 'AOR-000001',
        'user_id' => (int) $agencyUsers['yara.store@voicelive.local']['id'],
        'agency_name' => 'وكالة يارا',
        'country' => 'مصر',
        'phone' => '201022334455',
        'address' => 'الإسكندرية - سموحة',
        'avatar_path' => null,
        'front_id_path' => null,
        'back_id_path' => null,
        'status' => 'new',
        'admin_note' => null,
        'agency_id' => null,
        'created_at' => $now,
        'updated_at' => $now,
    ]);
}

$agencyJoinRequestsCount = (int) $pdo->query('SELECT COUNT(*) FROM agency_join_requests')->fetchColumn();
if ($agencyJoinRequestsCount === 0 && isset($agencyUsers['nona.store@voicelive.local']) && $seedAgencyId !== null && $seedAgencyId > 0) {
    $insertJoinRequest = $pdo->prepare(
        'INSERT INTO agency_join_requests
            (request_code, user_id, agency_id, invitation_code, agency_name_snapshot, agency_type, status, admin_note, created_at, updated_at)
         VALUES
            (:request_code, :user_id, :agency_id, :invitation_code, :agency_name_snapshot, :agency_type, :status, :admin_note, :created_at, :updated_at)'
    );
    $insertJoinRequest->execute([
        'request_code' => 'AJR-000001',
        'user_id' => (int) $agencyUsers['nona.store@voicelive.local']['id'],
        'agency_id' => $seedAgencyId,
        'invitation_code' => 'VL-AGY-2026',
        'agency_name_snapshot' => 'وكالة النخبة',
        'agency_type' => 'لايف وشات',
        'status' => 'new',
        'admin_note' => null,
        'created_at' => $now,
        'updated_at' => $now,
    ]);
}

$walletPackagesCount = (int) $pdo->query('SELECT COUNT(*) FROM wallet_packages')->fetchColumn();
if ($walletPackagesCount === 0) {
    $seedWalletPackages = [
        ['wallet_type' => 'diamonds', 'amount' => 30990, 'bonus_amount' => 0, 'price_label' => '2,894,99 ج.م', 'display_order' => 1],
        ['wallet_type' => 'diamonds', 'amount' => 6090, 'bonus_amount' => 0, 'price_label' => '578,99 ج.م', 'display_order' => 2],
        ['wallet_type' => 'diamonds', 'amount' => 600, 'bonus_amount' => 300, 'price_label' => '57,99 ج.م', 'display_order' => 3],
        ['wallet_type' => 'diamonds', 'amount' => 122990, 'bonus_amount' => 1000, 'price_label' => '11,536,99 ج.م', 'display_order' => 4],
        ['wallet_type' => 'diamonds', 'amount' => 61990, 'bonus_amount' => 0, 'price_label' => '5,736,99 ج.م', 'display_order' => 5],
        ['wallet_type' => 'coins', 'amount' => 5000, 'bonus_amount' => 0, 'price_label' => '500', 'display_order' => 6],
        ['wallet_type' => 'coins', 'amount' => 1000, 'bonus_amount' => 0, 'price_label' => '100', 'display_order' => 7],
        ['wallet_type' => 'coins', 'amount' => 100, 'bonus_amount' => 0, 'price_label' => '10', 'display_order' => 8],
        ['wallet_type' => 'coins', 'amount' => 5000000, 'bonus_amount' => 0, 'price_label' => '500000', 'display_order' => 9],
        ['wallet_type' => 'coins', 'amount' => 100000, 'bonus_amount' => 0, 'price_label' => '10000', 'display_order' => 10],
        ['wallet_type' => 'coins', 'amount' => 10000, 'bonus_amount' => 0, 'price_label' => '1000', 'display_order' => 11],
    ];

    $insertWalletPackage = $pdo->prepare(
        'INSERT INTO wallet_packages
            (wallet_type, amount, bonus_amount, price_label, status, display_order, created_at, updated_at)
         VALUES
            (:wallet_type, :amount, :bonus_amount, :price_label, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedWalletPackages as $package) {
        $insertWalletPackage->execute([
            ...$package,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$giftsCount = (int) $pdo->query('SELECT COUNT(*) FROM gifts')->fetchColumn();
if ($giftsCount === 0) {
    $seedGifts = [
        ['name' => 'الهدية الصغيرة', 'category' => 'الهداية عادية', 'asset_path' => 'assets/images/room_gift_1.png', 'animation_path' => null, 'sound_path' => null, 'is_animated' => 0, 'effect_duration_ms' => 1800, 'price_coins' => 10, 'display_order' => 1],
        ['name' => 'الهدية الصغيرة', 'category' => 'الهداية عادية', 'asset_path' => 'assets/images/room_gift_2.png', 'animation_path' => null, 'sound_path' => null, 'is_animated' => 0, 'effect_duration_ms' => 1800, 'price_coins' => 10, 'display_order' => 2],
        ['name' => 'الهدية الصغيرة', 'category' => 'الهداية عادية', 'asset_path' => 'assets/images/room_gift_3.png', 'animation_path' => null, 'sound_path' => null, 'is_animated' => 0, 'effect_duration_ms' => 1800, 'price_coins' => 10, 'display_order' => 3],
        ['name' => 'الهدية الصغيرة', 'category' => 'الهداية عادية', 'asset_path' => 'assets/images/room_gift_4.png', 'animation_path' => null, 'sound_path' => null, 'is_animated' => 0, 'effect_duration_ms' => 1800, 'price_coins' => 10, 'display_order' => 4],
        ['name' => 'الهدية الصغيرة', 'category' => 'VIP', 'asset_path' => 'assets/images/room_gift_5.png', 'animation_path' => null, 'sound_path' => null, 'is_animated' => 0, 'effect_duration_ms' => 1800, 'price_coins' => 20, 'display_order' => 5],
        ['name' => 'الهدية الصغيرة', 'category' => 'VIP', 'asset_path' => 'assets/images/room_gift_6.png', 'animation_path' => null, 'sound_path' => null, 'is_animated' => 0, 'effect_duration_ms' => 1800, 'price_coins' => 25, 'display_order' => 6],
        ['name' => 'الهدية الصغيرة', 'category' => 'المحظوظ', 'asset_path' => 'assets/images/room_gift_7.png', 'animation_path' => null, 'sound_path' => null, 'is_animated' => 0, 'effect_duration_ms' => 1800, 'price_coins' => 30, 'display_order' => 7],
        ['name' => 'الهدية الصغيرة', 'category' => 'متحرك', 'asset_path' => 'assets/images/room_gift_8.png', 'animation_path' => 'assets/images/room_gift_8.png', 'sound_path' => null, 'is_animated' => 1, 'effect_duration_ms' => 2200, 'price_coins' => 40, 'display_order' => 8],
    ];

    $insertGift = $pdo->prepare(
        'INSERT INTO gifts
            (name, category, asset_path, animation_path, sound_path, is_animated, effect_duration_ms, price_coins, status, display_order, created_at, updated_at)
         VALUES
            (:name, :category, :asset_path, :animation_path, :sound_path, :is_animated, :effect_duration_ms, :price_coins, :status, :display_order, :created_at, :updated_at)'
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

$storeItemsCount = (int) $pdo->query('SELECT COUNT(*) FROM store_items')->fetchColumn();
if ($storeItemsCount === 0) {
    $seedStoreItems = [
        ['category_key' => 'frames', 'name' => 'الاطار القوي', 'preview_asset_path' => 'assets/images/profile_store_frames_preview_overlay.png', 'dialog_icon_asset_path' => 'assets/images/profile_store_frames_dialog_icon.png', 'dialog_preview_asset_path' => null, 'display_order' => 1],
        ['category_key' => 'frames', 'name' => 'الاطار الملكي', 'preview_asset_path' => 'assets/images/profile_store_frames_preview_overlay.png', 'dialog_icon_asset_path' => 'assets/images/profile_store_frames_dialog_icon.png', 'dialog_preview_asset_path' => null, 'display_order' => 2],
        ['category_key' => 'frames', 'name' => 'اطار الماس', 'preview_asset_path' => 'assets/images/profile_store_frames_preview_overlay.png', 'dialog_icon_asset_path' => 'assets/images/profile_store_frames_dialog_icon.png', 'dialog_preview_asset_path' => null, 'display_order' => 3],
        ['category_key' => 'animated_frames', 'name' => 'رسم ادوات', 'preview_asset_path' => 'assets/images/profile_store_animated_frames_item.png', 'dialog_icon_asset_path' => 'assets/images/profile_store_animated_frames_dialog_icon.png', 'dialog_preview_asset_path' => 'assets/images/profile_store_animated_frames_dialog_preview.png', 'display_order' => 4],
        ['category_key' => 'animated_frames', 'name' => 'رسم ادوات', 'preview_asset_path' => 'assets/images/profile_store_animated_frames_item.png', 'dialog_icon_asset_path' => 'assets/images/profile_store_animated_frames_dialog_icon.png', 'dialog_preview_asset_path' => 'assets/images/profile_store_animated_frames_dialog_preview.png', 'display_order' => 5],
        ['category_key' => 'backgrounds', 'name' => 'خلفية روم ذهبية', 'preview_asset_path' => 'assets/images/profile_store_background_preview.png', 'dialog_icon_asset_path' => null, 'dialog_preview_asset_path' => null, 'display_order' => 6],
        ['category_key' => 'backgrounds', 'name' => 'خلفية روم ملكية', 'preview_asset_path' => 'assets/images/profile_store_background_preview.png', 'dialog_icon_asset_path' => null, 'dialog_preview_asset_path' => null, 'display_order' => 7],
        ['category_key' => 'chat_frames', 'name' => 'اطار محادثة فاخر', 'preview_asset_path' => 'assets/images/profile_store_chat_frames_item.png', 'dialog_icon_asset_path' => null, 'dialog_preview_asset_path' => null, 'display_order' => 8],
        ['category_key' => 'chat_frames', 'name' => 'اطار محادثة فضي', 'preview_asset_path' => 'assets/images/profile_store_chat_frames_item.png', 'dialog_icon_asset_path' => null, 'dialog_preview_asset_path' => null, 'display_order' => 9],
        ['category_key' => 'entry_effects', 'name' => 'الاطار المتحرك السريع', 'preview_asset_path' => 'assets/images/profile_store_entry_effects_fast_frame_item.png', 'dialog_icon_asset_path' => 'assets/images/profile_store_entry_effects_fast_frame_dialog_icon.png', 'dialog_preview_asset_path' => 'assets/images/profile_store_entry_effects_fast_frame_dialog_preview.png', 'display_order' => 10],
        ['category_key' => 'entry_effects', 'name' => 'الاطار المتحرك السريع', 'preview_asset_path' => 'assets/images/profile_store_entry_effects_fast_frame_item.png', 'dialog_icon_asset_path' => 'assets/images/profile_store_entry_effects_fast_frame_dialog_icon.png', 'dialog_preview_asset_path' => 'assets/images/profile_store_entry_effects_fast_frame_dialog_preview.png', 'display_order' => 11],
    ];

    $insertStoreItem = $pdo->prepare(
        'INSERT INTO store_items
            (category_key, name, preview_asset_path, dialog_icon_asset_path, dialog_preview_asset_path, price_3_days, price_7_days, price_15_days, price_30_days, discount_3_days, discount_7_days, discount_15_days, discount_30_days, currency_type, status, display_order, created_at, updated_at)
         VALUES
            (:category_key, :name, :preview_asset_path, :dialog_icon_asset_path, :dialog_preview_asset_path, :price_3_days, :price_7_days, :price_15_days, :price_30_days, :discount_3_days, :discount_7_days, :discount_15_days, :discount_30_days, :currency_type, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedStoreItems as $item) {
        $insertStoreItem->execute([
            ...$item,
            'price_3_days' => 90,
            'price_7_days' => 180,
            'price_15_days' => 330,
            'price_30_days' => 540,
            'discount_3_days' => '10% Off',
            'discount_7_days' => '22% Off',
            'discount_15_days' => '27% Off',
            'discount_30_days' => '27% Off',
            'currency_type' => 'coins',
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

$roomGamesCatalogCount = (int) $pdo->query('SELECT COUNT(*) FROM room_games_catalog')->fetchColumn();
if ($roomGamesCatalogCount === 0) {
    $seedRoomGames = [
        [
            'game_key' => 'wheel_of_fortune',
            'name' => 'عجلة الحظ',
            'category_key' => 'luck',
            'icon_asset' => 'assets/images/room_game_wheel_icon.png',
            'description_text' => 'لعبة سريعة داخل الغرفة لاختيار الفائز بالحظ بين الأعضاء.',
            'min_players' => 1,
            'max_players' => 8,
            'display_order' => 1,
        ],
        [
            'game_key' => 'ludo',
            'name' => 'لودو',
            'category_key' => 'board',
            'icon_asset' => 'assets/images/room_game_ludo_icon.png',
            'description_text' => 'جلسة لودو جماعية خفيفة بين أعضاء الغرفة.',
            'min_players' => 2,
            'max_players' => 4,
            'display_order' => 2,
        ],
        [
            'game_key' => 'domino',
            'name' => 'دومينو',
            'category_key' => 'board',
            'icon_asset' => 'assets/images/room_game_domino_icon.png',
            'description_text' => 'لعبة دومينو داخل الغرفة مع إمكانية انضمام عدة لاعبين.',
            'min_players' => 2,
            'max_players' => 4,
            'display_order' => 3,
        ],
    ];

    $insertRoomGame = $pdo->prepare(
        'INSERT INTO room_games_catalog
            (game_key, name, category_key, icon_asset, description_text, min_players, max_players, status, display_order, created_at, updated_at)
         VALUES
            (:game_key, :name, :category_key, :icon_asset, :description_text, :min_players, :max_players, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedRoomGames as $game) {
        $insertRoomGame->execute([
            ...$game,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$liveGiftTransactionsCount = (int) $pdo->query('SELECT COUNT(*) FROM live_room_gift_transactions')->fetchColumn();
if ($liveGiftTransactionsCount === 0) {
    $giftIds = $pdo->query('SELECT id FROM gifts ORDER BY id ASC')->fetchAll(PDO::FETCH_COLUMN);
    $firstGiftId = (int) ($giftIds[0] ?? 1);
    $insertLiveGiftTransaction = $pdo->prepare(
        'INSERT INTO live_room_gift_transactions
            (room_id, sender_user_id, sender_name, sender_avatar_asset, gift_id, gift_name_snapshot, quantity, unit_price_coins, total_price_coins, created_at)
         VALUES
            (:room_id, :sender_user_id, :sender_name, :sender_avatar_asset, :gift_id, :gift_name_snapshot, :quantity, :unit_price_coins, :total_price_coins, :created_at)'
    );

    $demoUserRows = $pdo->query(
        "SELECT id, nickname, email FROM users WHERE email IN ('mohamed.store@voicelive.local', 'yara.store@voicelive.local', 'nona.store@voicelive.local')"
    )->fetchAll();
    $demoUserMap = [];
    foreach ($demoUserRows as $userRow) {
        $key = (string) ($userRow['email'] ?? '');
        $demoUserMap[$key] = $userRow;
    }

    $seedLiveGiftTransactions = [
        ['room_id' => 1, 'user_email' => 'mohamed.store@voicelive.local', 'quantity' => 10, 'unit_price_coins' => 10],
        ['room_id' => 1, 'user_email' => 'yara.store@voicelive.local', 'quantity' => 8, 'unit_price_coins' => 10],
        ['room_id' => 1, 'user_email' => 'nona.store@voicelive.local', 'quantity' => 5, 'unit_price_coins' => 10],
    ];

    foreach ($seedLiveGiftTransactions as $transaction) {
        $userRow = $demoUserMap[$transaction['user_email']] ?? null;
        $quantity = (int) $transaction['quantity'];
        $unitPriceCoins = (int) $transaction['unit_price_coins'];
        $insertLiveGiftTransaction->execute([
            'room_id' => (int) $transaction['room_id'],
            'sender_user_id' => isset($userRow['id']) ? (int) $userRow['id'] : null,
            'sender_name' => (string) ($userRow['nickname'] ?? 'Mohammed Ahmed'),
            'sender_avatar_asset' => 'assets/images/profile_avatar.png',
            'gift_id' => $firstGiftId,
            'gift_name_snapshot' => 'الهدية الصغيرة',
            'quantity' => $quantity,
            'unit_price_coins' => $unitPriceCoins,
            'total_price_coins' => $quantity * $unitPriceCoins,
            'created_at' => $now,
        ]);
    }

    $liveContributionTotals = $pdo->query(
        'SELECT room_id,
                COALESCE(SUM(total_price_coins), 0) AS total_diamonds,
                COUNT(DISTINCT sender_name) AS sender_count
         FROM live_room_gift_transactions
         GROUP BY room_id'
    )->fetchAll();
    $updateLiveRoomContribution = $pdo->prepare(
        'UPDATE live_rooms
         SET contribution_diamonds_total = :contribution_diamonds_total,
             contribution_sender_count = :contribution_sender_count,
             updated_at = :updated_at
         WHERE id = :id'
    );
    foreach ($liveContributionTotals as $totalRow) {
        $updateLiveRoomContribution->execute([
            'contribution_diamonds_total' => (int) $totalRow['total_diamonds'],
            'contribution_sender_count' => (int) $totalRow['sender_count'],
            'updated_at' => $now,
            'id' => (int) $totalRow['room_id'],
        ]);
    }
}

$liveReportsCount = (int) $pdo->query('SELECT COUNT(*) FROM live_room_reports')->fetchColumn();
if ($liveReportsCount === 0) {
    $reportUserRows = $pdo->query(
        "SELECT id, nickname, email FROM users WHERE email IN ('yara.store@voicelive.local', 'nona.store@voicelive.local')"
    )->fetchAll();
    $reportUserMap = [];
    foreach ($reportUserRows as $userRow) {
        $reportUserMap[(string) $userRow['email']] = $userRow;
    }

    $insertLiveReport = $pdo->prepare(
        'INSERT INTO live_room_reports
            (room_id, reporter_user_id, reporter_name, reason_text, status, created_at, updated_at)
         VALUES
            (:room_id, :reporter_user_id, :reporter_name, :reason_text, :status, :created_at, :updated_at)'
    );

    $seedLiveReports = [
        ['room_id' => 1, 'user_email' => 'yara.store@voicelive.local', 'reason_text' => 'محتوى غير مناسب داخل الدردشة.', 'status' => 'new'],
        ['room_id' => 2, 'user_email' => 'nona.store@voicelive.local', 'reason_text' => 'صوت مزعج ومخالف للتعليمات.', 'status' => 'reviewed'],
    ];

    foreach ($seedLiveReports as $report) {
        $userRow = $reportUserMap[$report['user_email']] ?? null;
        $insertLiveReport->execute([
            'room_id' => (int) $report['room_id'],
            'reporter_user_id' => isset($userRow['id']) ? (int) $userRow['id'] : null,
            'reporter_name' => (string) ($userRow['nickname'] ?? 'User Report'),
            'reason_text' => (string) $report['reason_text'],
            'status' => (string) $report['status'],
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$livePkInvitesCount = (int) $pdo->query('SELECT COUNT(*) FROM live_pk_invites')->fetchColumn();
if ($livePkInvitesCount === 0) {
    $pkUserRows = $pdo->query(
        "SELECT id, nickname, email FROM users WHERE email IN ('mohamed.store@voicelive.local', 'yara.store@voicelive.local', 'nona.store@voicelive.local')"
    )->fetchAll();
    $pkUserMap = [];
    foreach ($pkUserRows as $userRow) {
        $pkUserMap[(string) $userRow['email']] = $userRow;
    }

    $insertPkInvite = $pdo->prepare(
        'INSERT INTO live_pk_invites
            (room_id, sender_user_id, sender_name, recipient_user_id, recipient_name_snapshot, status, created_at, updated_at)
         VALUES
            (:room_id, :sender_user_id, :sender_name, :recipient_user_id, :recipient_name_snapshot, :status, :created_at, :updated_at)'
    );

    $seedPkInvites = [
        [
            'room_id' => 1,
            'sender_email' => 'mohamed.store@voicelive.local',
            'recipient_email' => 'yara.store@voicelive.local',
            'status' => 'sent',
        ],
        [
            'room_id' => 1,
            'sender_email' => 'mohamed.store@voicelive.local',
            'recipient_email' => 'nona.store@voicelive.local',
            'status' => 'accepted',
        ],
    ];

    foreach ($seedPkInvites as $invite) {
        $sender = $pkUserMap[$invite['sender_email']] ?? null;
        $recipient = $pkUserMap[$invite['recipient_email']] ?? null;
        if ($recipient === null) {
            continue;
        }

        $insertPkInvite->execute([
            'room_id' => (int) $invite['room_id'],
            'sender_user_id' => isset($sender['id']) ? (int) $sender['id'] : null,
            'sender_name' => (string) ($sender['nickname'] ?? 'Mohammed Ahmed'),
            'recipient_user_id' => (int) $recipient['id'],
            'recipient_name_snapshot' => (string) ($recipient['nickname'] ?? $recipient['email']),
            'status' => (string) $invite['status'],
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

$shippingAgenciesCount = (int) $pdo->query('SELECT COUNT(*) FROM shipping_agencies')->fetchColumn();
if ($shippingAgenciesCount === 0) {
    $seedShippingAgencies = [
        [
            'name' => 'Mohamed Ahmed',
            'handle' => '@ ابو احمد',
            'diamond_balance' => 30500000,
            'supported_country_codes' => json_encode(['at', 'az', 'ae'], JSON_UNESCAPED_UNICODE),
            'display_order' => 1,
        ],
        [
            'name' => 'Sara Mohamed',
            'handle' => '@ سارة',
            'diamond_balance' => 17200000,
            'supported_country_codes' => json_encode(['ae', 'az'], JSON_UNESCAPED_UNICODE),
            'display_order' => 2,
        ],
        [
            'name' => 'Nour Salem',
            'handle' => '@ نور',
            'diamond_balance' => 8900000,
            'supported_country_codes' => json_encode(['at', 'ae'], JSON_UNESCAPED_UNICODE),
            'display_order' => 3,
        ],
    ];

    $insertAgency = $pdo->prepare(
        'INSERT INTO shipping_agencies
            (name, handle, diamond_balance, supported_country_codes, status, display_order, created_at, updated_at)
         VALUES
            (:name, :handle, :diamond_balance, :supported_country_codes, :status, :display_order, :created_at, :updated_at)'
    );

    foreach ($seedShippingAgencies as $agency) {
        $insertAgency->execute([
            ...$agency,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$supportTicketsCount = (int) $pdo->query('SELECT COUNT(*) FROM support_tickets')->fetchColumn();
if ($supportTicketsCount === 0) {
    $insertTicket = $pdo->prepare(
        'INSERT INTO support_tickets
            (ticket_code, user_id, sender_name, sender_email, sender_phone, category, description, status, attachment_count, admin_note, created_at, updated_at)
         VALUES
            (:ticket_code, :user_id, :sender_name, :sender_email, :sender_phone, :category, :description, :status, :attachment_count, :admin_note, :created_at, :updated_at)'
    );

    $seedTickets = [
        [
            'ticket_code' => 'SUP-000001',
            'user_id' => null,
            'sender_name' => 'Mohamed Ahmed',
            'sender_email' => 'mohamed@example.com',
            'sender_phone' => '01012345678',
            'category' => 'اعادة الشحن',
            'description' => 'تم خصم الرصيد ولم تصلني العملات داخل التطبيق حتى الآن.',
            'status' => 'new',
            'attachment_count' => 0,
            'admin_note' => null,
        ],
        [
            'ticket_code' => 'SUP-000002',
            'user_id' => null,
            'sender_name' => 'Sara Mohamed',
            'sender_email' => 'sara@example.com',
            'sender_phone' => '01076543210',
            'category' => 'مشكلة تطبيق',
            'description' => 'التطبيق يغلق عند فتح شاشة المحفظة على بعض الأجهزة.',
            'status' => 'in_progress',
            'attachment_count' => 0,
            'admin_note' => 'جارٍ مراجعة السجلات وإعادة الاختبار.',
        ],
    ];

    foreach ($seedTickets as $ticket) {
        $insertTicket->execute([
            ...$ticket,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$postReportReasonsCount = (int) $pdo->query('SELECT COUNT(*) FROM post_report_reasons')->fetchColumn();
if ($postReportReasonsCount === 0) {
    $insertReason = $pdo->prepare(
        'INSERT INTO post_report_reasons
            (reason_key, label, description, display_order, status, created_at, updated_at)
         VALUES
            (:reason_key, :label, :description, :display_order, :status, :created_at, :updated_at)'
    );

    $seedReasons = [
        ['reason_key' => 'spam', 'label' => 'محتوى مزعج أو سبام', 'description' => 'منشور متكرر أو دعائي أو غير حقيقي', 'display_order' => 1],
        ['reason_key' => 'abuse', 'label' => 'إساءة أو تنمر', 'description' => 'إهانة، تهديد، تنمر، أو خطاب مؤذي', 'display_order' => 2],
        ['reason_key' => 'adult', 'label' => 'محتوى غير لائق', 'description' => 'صور أو كلمات غير مناسبة للمجتمع', 'display_order' => 3],
        ['reason_key' => 'fraud', 'label' => 'احتيال أو نصب', 'description' => 'طلب أموال أو روابط مشبوهة أو انتحال', 'display_order' => 4],
        ['reason_key' => 'other', 'label' => 'سبب آخر', 'description' => 'بلاغ عام يحتاج مراجعة الإدارة', 'display_order' => 5],
    ];

    foreach ($seedReasons as $reason) {
        $insertReason->execute([
            ...$reason,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }
}

$postsCount = (int) $pdo->query('SELECT COUNT(*) FROM posts')->fetchColumn();
if ($postsCount === 0) {
    $seedPosts = [
        [
            'author_key' => 'seed:asmaa',
            'author_name' => 'اسماء فتحي',
            'body_text' => "لا تعود الايام الي فاتت ولا تنتظر احد 💔\nلا تعود الايام الي فاتت ولا تنتظر احد 💔\nلا تعود الايام الي فاتت ولا تنتظر احد 💔",
            'comment_count' => 1,
            'display_offset_hours' => 12,
        ],
        [
            'author_key' => 'seed:nour',
            'author_name' => 'نور سالم',
            'body_text' => "من اجمل اللحظات ان تجد من يفهمك بدون شرح.\nمن اجمل اللحظات ان تجد من يفهمك بدون شرح.",
            'comment_count' => 0,
            'display_offset_hours' => 18,
        ],
        [
            'author_key' => 'seed:mohamed',
            'author_name' => 'محمد احمد',
            'body_text' => "لا تزال البداية ممكنة مهما تأخر الوقت.\nلا تزال البداية ممكنة مهما تأخر الوقت.",
            'comment_count' => 2,
            'display_offset_hours' => 36,
        ],
    ];

    $insertPost = $pdo->prepare(
        'INSERT INTO posts
            (author_user_id, author_key, author_name, author_avatar_asset, body_text, image_path, status, report_count, like_count, comment_count, share_count, shared_post_id, created_at, updated_at)
         VALUES
            (:author_user_id, :author_key, :author_name, :author_avatar_asset, :body_text, :image_path, :status, :report_count, :like_count, :comment_count, :share_count, :shared_post_id, :created_at, :updated_at)'
    );

    foreach ($seedPosts as $post) {
        $createdAt = gmdate('Y-m-d H:i:s', time() - ((int) $post['display_offset_hours'] * 3600));
        $insertPost->execute([
            'author_user_id' => null,
            'author_key' => $post['author_key'],
            'author_name' => $post['author_name'],
            'author_avatar_asset' => 'assets/images/post_author_avatar.png',
            'body_text' => $post['body_text'],
            'image_path' => null,
            'status' => 'active',
            'report_count' => 0,
            'like_count' => 0,
            'comment_count' => (int) $post['comment_count'],
            'share_count' => 0,
            'shared_post_id' => null,
            'created_at' => $createdAt,
            'updated_at' => $createdAt,
        ]);

        $postId = (int) $pdo->lastInsertId();
        $insertComment = $pdo->prepare(
            'INSERT INTO post_comments
                (post_id, user_id, author_name_snapshot, author_avatar_asset, body_text, status, report_count, created_at, updated_at)
             VALUES
                (:post_id, :user_id, :author_name_snapshot, :author_avatar_asset, :body_text, :status, :report_count, :created_at, :updated_at)'
        );
        for ($commentIndex = 0; $commentIndex < (int) $post['comment_count']; $commentIndex++) {
            $insertComment->execute([
                'post_id' => $postId,
                'user_id' => null,
                'author_name_snapshot' => $commentIndex === 0 ? 'محمد احمد' : 'سارة محمد',
                'author_avatar_asset' => 'assets/images/post_author_avatar.png',
                'body_text' => $commentIndex === 0 ? 'منشور جميل جدا.' : 'كلام حقيقي.',
                'status' => 'active',
                'report_count' => 0,
                'created_at' => $createdAt,
                'updated_at' => $createdAt,
            ]);
        }
    }
}

echo "Migration completed successfully.\n";
