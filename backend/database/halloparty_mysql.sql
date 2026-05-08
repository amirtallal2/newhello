-- HalloParty bootstrap SQL for MySQL 8+
-- Import this file into an empty utf8mb4 database from aaPanel/phpMyAdmin.
SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;

-- Schema
CREATE TABLE IF NOT EXISTS admins (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(120) NOT NULL,
            email VARCHAR(190) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            role VARCHAR(50) NOT NULL DEFAULT "super_admin",
            is_active TINYINT(1) NOT NULL DEFAULT 1,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS app_settings (
            setting_key VARCHAR(120) PRIMARY KEY,
            setting_value TEXT NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS users (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS auth_tokens (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            token_name VARCHAR(50) NOT NULL,
            token_hash CHAR(64) NOT NULL UNIQUE,
            last_used_at DATETIME NULL,
            expires_at DATETIME NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_auth_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS pending_registrations (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS password_reset_tokens (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            email_snapshot VARCHAR(190) NOT NULL,
            reset_token CHAR(64) NOT NULL UNIQUE,
            reset_code VARCHAR(10) NOT NULL,
            expires_at DATETIME NOT NULL,
            used_at DATETIME NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_password_reset_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS rooms (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS room_seat_requests (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS room_audio_participants (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS live_rooms (
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
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS live_room_viewers (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            rank_order INT NOT NULL DEFAULT 1,
            viewer_name VARCHAR(190) NOT NULL,
            avatar_asset VARCHAR(255) NOT NULL,
            is_top_supporter TINYINT(1) NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_live_viewers_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS live_room_comments (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            commenter_user_id INT UNSIGNED NULL,
            commenter_name VARCHAR(190) NOT NULL,
            avatar_asset VARCHAR(255) NOT NULL,
            message_text TEXT NOT NULL,
            display_order INT NOT NULL DEFAULT 1,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_live_comments_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS live_room_notifications (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            room_id INT UNSIGNED NOT NULL,
            title_text VARCHAR(190) NOT NULL,
            body_text TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_live_notifications_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS live_room_reports (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS live_pk_invites (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS live_room_gift_transactions (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS user_wallets (
            user_id INT UNSIGNED PRIMARY KEY,
            coins_balance INT NOT NULL DEFAULT 1235,
            diamonds_balance INT NOT NULL DEFAULT 5,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_user_wallet_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS wallet_packages (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            wallet_type VARCHAR(20) NOT NULL,
            amount INT NOT NULL,
            bonus_amount INT NOT NULL DEFAULT 0,
            price_label VARCHAR(120) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS wallet_transactions (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS gifts (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS store_items (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS user_store_inventory (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS store_send_transactions (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS music_tracks (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS room_music_playlist_entries (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS room_games_catalog (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS room_game_sessions (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS room_game_session_players (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS room_gift_transactions (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS shipping_agencies (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(190) NOT NULL,
            handle VARCHAR(120) NOT NULL,
            diamond_balance BIGINT NOT NULL DEFAULT 0,
            supported_country_codes TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS support_tickets (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS support_ticket_attachments (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            ticket_id INT UNSIGNED NOT NULL,
            file_path VARCHAR(255) NOT NULL,
            original_name VARCHAR(255) NOT NULL,
            mime_type VARCHAR(120) NOT NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_support_ticket_attachments_ticket FOREIGN KEY (ticket_id) REFERENCES support_tickets(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS posts (
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
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            CONSTRAINT fk_posts_author_user FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS post_followings (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            author_key VARCHAR(190) NOT NULL,
            author_name_snapshot VARCHAR(190) NOT NULL,
            created_at DATETIME NOT NULL,
            UNIQUE KEY uq_post_followings_user_author (user_id, author_key),
            CONSTRAINT fk_post_followings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS post_likes (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            post_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NOT NULL,
            created_at DATETIME NOT NULL,
            UNIQUE KEY uq_post_likes_post_user (post_id, user_id),
            CONSTRAINT fk_post_likes_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS post_comments (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            post_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NULL,
            author_name_snapshot VARCHAR(190) NOT NULL,
            body_text TEXT NOT NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_post_comments_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
            CONSTRAINT fk_post_comments_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS post_reports (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS post_notifications (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS chat_threads (
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
            CONSTRAINT fk_chat_threads_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS chat_messages (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            thread_id INT UNSIGNED NOT NULL,
            direction VARCHAR(20) NOT NULL DEFAULT "incoming",
            sender_name VARCHAR(190) NOT NULL,
            body_text TEXT NOT NULL,
            message_type VARCHAR(20) NOT NULL DEFAULT "text",
            attachment_path VARCHAR(255) NULL,
            attachment_mime_type VARCHAR(120) NULL,
            attachment_name VARCHAR(190) NULL,
            time_label VARCHAR(20) NOT NULL,
            created_at DATETIME NOT NULL,
            CONSTRAINT fk_chat_messages_thread FOREIGN KEY (thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS chat_gift_transactions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            thread_id INT UNSIGNED NOT NULL,
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
            created_at DATETIME NOT NULL,
            INDEX idx_chat_gifts_thread (thread_id),
            INDEX idx_chat_gifts_sender (sender_user_id),
            INDEX idx_chat_gifts_recipient (recipient_user_id),
            CONSTRAINT fk_chat_gifts_thread FOREIGN KEY (thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE,
            CONSTRAINT fk_chat_gifts_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_chat_gifts_recipient FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE SET NULL,
            CONSTRAINT fk_chat_gifts_gift FOREIGN KEY (gift_id) REFERENCES gifts(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS chat_search_history (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            label VARCHAR(190) NOT NULL,
            target_thread_id INT UNSIGNED NULL,
            created_at DATETIME NOT NULL,
            UNIQUE KEY uq_chat_search_history_user_label (user_id, label),
            CONSTRAINT fk_chat_search_history_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            CONSTRAINT fk_chat_search_history_thread FOREIGN KEY (target_thread_id) REFERENCES chat_threads(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS user_settings (
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS room_audio_participants (
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS agencies (
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS agency_open_requests (
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS agency_join_requests (
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
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Post-create user columns
ALTER TABLE users ADD COLUMN agency_id INT UNSIGNED NULL;
ALTER TABLE users ADD COLUMN agency_role VARCHAR(30) NULL;
ALTER TABLE users ADD COLUMN agency_joined_at DATETIME NULL;
ALTER TABLE users ADD COLUMN google_sub VARCHAR(191) NULL;
ALTER TABLE users ADD COLUMN auth_provider VARCHAR(30) NULL;
CREATE UNIQUE INDEX uq_users_google_sub ON users (google_sub);
ALTER TABLE users ADD COLUMN avatar_asset VARCHAR(255) NULL DEFAULT 'assets/images/profile_avatar.png';
ALTER TABLE users ADD COLUMN profile_handle VARCHAR(120) NULL DEFAULT 'Shark.island';
ALTER TABLE users ADD COLUMN signature_text VARCHAR(255) NULL DEFAULT 'ليس لديك المقدمة الشخصية';
ALTER TABLE users ADD COLUMN following_count INT NOT NULL DEFAULT 50;
ALTER TABLE users ADD COLUMN followers_count INT NOT NULL DEFAULT 100;
ALTER TABLE users ADD COLUMN friends_count INT NOT NULL DEFAULT 123;
ALTER TABLE users ADD COLUMN level_current INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN level_next INT NOT NULL DEFAULT 1;
ALTER TABLE users ADD COLUMN level_progress_percent INT NOT NULL DEFAULT 67;
ALTER TABLE users ADD COLUMN vip_tier VARCHAR(40) NULL DEFAULT 'VIP 0';
ALTER TABLE users ADD COLUMN svip_tier VARCHAR(40) NULL DEFAULT 'SVIP 0';
ALTER TABLE users ADD COLUMN badges_count INT NOT NULL DEFAULT 4;
ALTER TABLE users ADD COLUMN tasks_completed INT NOT NULL DEFAULT 5;
ALTER TABLE users ADD COLUMN tasks_total INT NOT NULL DEFAULT 12;

-- Seed data
-- Data for table `admins`
INSERT INTO `admins` (`id`, `name`, `email`, `password_hash`, `role`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Super Admin', 'admin@voicelive.local', '$2y$12$ruZVxpodIVICMazLRrA6uufm2PUg5ITAsapjBBqS7hOmoDY48L2Zu', 'super_admin', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `app_settings`
INSERT INTO `app_settings` (`setting_key`, `setting_value`, `updated_at`) VALUES
('gift_platform_commission_percent', '50', '2026-05-03 12:38:48');

-- Data for table `users`
INSERT INTO `users` (`id`, `email`, `phone`, `password_hash`, `nickname`, `birthdate`, `gender`, `country`, `status`, `email_verified_at`, `phone_verified_at`, `created_at`, `updated_at`, `agency_id`, `agency_role`, `agency_joined_at`, `google_sub`, `auth_provider`, `avatar_asset`, `profile_handle`, `signature_text`, `following_count`, `followers_count`, `friends_count`, `level_current`, `level_next`, `level_progress_percent`, `vip_tier`, `svip_tier`, `badges_count`, `tasks_completed`, `tasks_total`) VALUES
(1, 'yara.store@voicelive.local', '201000000101', '$2y$12$8aWz2Hq0sPw/WME.7br6JOHbTu.f2iVdX8ux3HdfFJevqfZcFu2zS', 'Yara Mohamed', '1996-04-10', 'woman', 'Egypt', 'active', '2026-05-03 12:38:48', '2026-05-03 12:38:48', '2026-05-03 12:38:48', '2026-05-03 12:38:48', NULL, NULL, NULL, NULL, NULL, 'assets/images/profile_avatar.png', 'Shark.island', 'ليس لديك المقدمة الشخصية', 50, 100, 123, 0, 1, 67, 'VIP 0', 'SVIP 0', 4, 5, 12),
(2, 'nona.store@voicelive.local', '201000000102', '$2y$12$FLUODXaNBzvHzWha5pZAeOyL6.j7m91hPA4Ip4B0YqIvV.bPOeErW', 'Nona Mohamed', '1997-06-18', 'woman', 'Egypt', 'active', '2026-05-03 12:38:48', '2026-05-03 12:38:48', '2026-05-03 12:38:48', '2026-05-03 12:38:48', NULL, NULL, NULL, NULL, NULL, 'assets/images/profile_avatar.png', 'Shark.island', 'ليس لديك المقدمة الشخصية', 50, 100, 123, 0, 1, 67, 'VIP 0', 'SVIP 0', 4, 5, 12),
(3, 'mohamed.store@voicelive.local', '201000000103', '$2y$12$cljYOrQDYBigQpvYXChHBe1mLA.C10FwhoZOy64Yf8L6YbQrG7bxe', 'Mohamed Ahmed', '1995-02-03', 'man', 'Egypt', 'active', '2026-05-03 12:38:48', '2026-05-03 12:38:48', '2026-05-03 12:38:48', '2026-05-03 12:38:48', 1, 'owner', '2026-05-03 12:38:48', NULL, NULL, 'assets/images/profile_avatar.png', 'Shark.island', 'ليس لديك المقدمة الشخصية', 50, 100, 123, 0, 1, 67, 'VIP 0', 'SVIP 0', 4, 5, 12);

-- Data for table `rooms`
INSERT INTO `rooms` (`id`, `card_title`, `room_title`, `subtitle`, `host_name`, `host_user_id`, `creator_user_id`, `room_type`, `slogan_text`, `country_label`, `room_code`, `card_image_asset`, `meta_icon_asset`, `host_avatar_asset`, `listener_count`, `mic_count`, `background_asset`, `audio_enabled`, `agora_channel_name`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 'الشكاوي والاقتراحات', 'أريد أن أسمع صوتك', 'اهلا وسهلا بكم في روم مصر ام الدنيا', 'محمد أحمد', 3, 3, 'دردشة', 'ابحث عن شخص يمكنه الدردشه معي هالحين', 'مصر', '1512345412', 'assets/images/home_room_service.png', 'assets/images/home_pin_icon.png', 'assets/images/profile_avatar.png', 30, 9, 'assets/images/room_background.jpg', 1, 'voice-room-1512345412', 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'خدمة العملاء', 'غرفة الدعم المباشر', 'اهلا وسهلا بكم في روم مصر ام الدنيا', 'محمد أحمد', 3, 3, 'دردشة', 'ابحث عن شخص يمكنه الدردشه معي هالحين', 'مصر', '1512345413', 'assets/images/home_room_service.png', 'assets/images/home_pin_icon.png', 'assets/images/profile_avatar.png', 30, 9, 'assets/images/room_background.jpg', 1, 'voice-room-1512345413', 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 'وكالة ولاد الملوك', 'وكالة ولاد الملوك', 'اهلا وسهلا بكم في روم مصر ام الدنيا', 'محمد أحمد', 3, 3, 'عائلة', 'اهلا وسهلا بكم في روم مصر ام الدنيا', 'مصر', '1512345414', 'assets/images/home_room_1.png', 'assets/images/home_egypt_flag.png', 'assets/images/profile_avatar.png', 30, 9, 'assets/images/room_background.jpg', 1, 'voice-room-1512345414', 'active', 3, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(4, 'وكالة ولاد الملوك', 'وكالة ولاد الملوك', 'اهلا وسهلا بكم في روم مصر ام الدنيا', 'محمد أحمد', 3, 3, 'عائلة', 'اهلا وسهلا بكم في روم مصر ام الدنيا', 'مصر', '1512345415', 'assets/images/home_room_2.png', 'assets/images/home_egypt_flag.png', 'assets/images/profile_avatar.png', 30, 9, 'assets/images/room_background.jpg', 1, 'voice-room-1512345415', 'active', 4, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `live_rooms`
INSERT INTO `live_rooms` (`id`, `title`, `host_name`, `host_id_label`, `host_user_id`, `video_enabled`, `agora_channel_name`, `poster_asset`, `background_asset`, `left_video_asset`, `right_video_asset`, `viewer_count`, `coin_count`, `battle_timer_label`, `listing_scope`, `contribution_diamonds_total`, `contribution_sender_count`, `pk_talk_permission`, `pk_party_invite_permission`, `pk_voice_room_invite_permission`, `pk_chat_permission`, `pk_battle_duration`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 'مداهم 777', 'Mohamed Ahmed', 'ID:1512345412', NULL, 1, 'live-room-1', 'assets/images/home149_card1.png', 'assets/images/live150_background.png', 'assets/images/live150_video_left.png', 'assets/images/live150_video_right.png', 393, 214, '11:50', 'live', 230, 3, 'عند الطلب', 'عند الطلب', 'عند الطلب', 'عند الطلب', '30د', 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'هاي عاملين ايه', 'Sara Mohamed', 'ID:1512345413', NULL, 1, 'live-room-2', 'assets/images/home149_card2.png', 'assets/images/live150_background.png', 'assets/images/live150_video_left.png', 'assets/images/live150_video_right.png', 188, 84, '11:50', 'friends', 100, 100, 'عند الطلب', 'عند الطلب', 'عند الطلب', 'عند الطلب', '30د', 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 'مساء الخير يا جماعة', 'Nour Salem', 'ID:1512345414', NULL, 1, 'live-room-3', 'assets/images/home149_card3.png', 'assets/images/live150_background.png', 'assets/images/live150_video_left.png', 'assets/images/live150_video_right.png', 126, 45, '11:50', 'newest', 100, 100, 'عند الطلب', 'عند الطلب', 'عند الطلب', 'عند الطلب', '30د', 'active', 3, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(4, 'لايف بنات مصر', 'Nona Mohamed', 'ID:1512345415', NULL, 1, 'live-room-4', 'assets/images/home149_card4.png', 'assets/images/live150_background.png', 'assets/images/live150_video_left.png', 'assets/images/live150_video_right.png', 210, 120, '11:50', 'friends', 100, 100, 'عند الطلب', 'عند الطلب', 'عند الطلب', 'عند الطلب', '30د', 'active', 4, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(5, 'سهرة اليوم', 'Ahmed Ali', 'ID:1512345416', NULL, 1, 'live-room-5', 'assets/images/home149_card7.png', 'assets/images/live150_background.png', 'assets/images/live150_video_left.png', 'assets/images/live150_video_right.png', 95, 38, '11:50', 'live', 100, 100, 'عند الطلب', 'عند الطلب', 'عند الطلب', 'عند الطلب', '30د', 'active', 5, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(6, 'نجوم اللايف', 'Yara Mohamed', 'ID:1512345417', NULL, 1, 'live-room-6', 'assets/images/home149_card8.png', 'assets/images/live150_background.png', 'assets/images/live150_video_left.png', 'assets/images/live150_video_right.png', 241, 133, '11:50', 'newest', 100, 100, 'عند الطلب', 'عند الطلب', 'عند الطلب', 'عند الطلب', '30د', 'active', 6, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `live_room_viewers`
INSERT INTO `live_room_viewers` (`id`, `room_id`, `rank_order`, `viewer_name`, `avatar_asset`, `is_top_supporter`, `created_at`) VALUES
(1, 1, 1, 'Mohammed Ahmed', 'assets/images/live150_comment_avatar.png', 1, '2026-05-03 12:38:48'),
(2, 1, 2, 'Sara Mohamed', 'assets/images/live150_comment_avatar.png', 0, '2026-05-03 12:38:48'),
(3, 1, 3, 'Nona Mohamed', 'assets/images/live150_comment_avatar.png', 0, '2026-05-03 12:38:48'),
(4, 1, 4, 'Yara Mohamed', 'assets/images/live150_comment_avatar.png', 0, '2026-05-03 12:38:48'),
(5, 2, 1, 'Mohammed Ahmed', 'assets/images/live150_comment_avatar.png', 1, '2026-05-03 12:38:48'),
(6, 2, 2, 'Ahmed Ali', 'assets/images/live150_comment_avatar.png', 0, '2026-05-03 12:38:48');

-- Data for table `live_room_comments`
INSERT INTO `live_room_comments` (`id`, `room_id`, `commenter_user_id`, `commenter_name`, `avatar_asset`, `message_text`, `display_order`, `created_at`) VALUES
(1, 1, 3, 'Mohamed Ahmed', 'assets/images/profile_avatar.png', 'الله واكبر ماشاء الله ايه الجمال والحلاوة دي كلها يابنات', 1, '2026-05-03 12:38:48'),
(2, 1, NULL, 'Sara Mohamed', 'assets/images/live150_comment_avatar.png', 'لايف جميل جدا استمروا', 2, '2026-05-03 12:38:48'),
(3, 1, 2, 'Nona Mohamed', 'assets/images/profile_avatar.png', 'احلي بنات واحلي جو', 3, '2026-05-03 12:38:48'),
(4, 1, 1, 'Yara Mohamed', 'assets/images/profile_avatar.png', 'مساء الخير عليكم', 4, '2026-05-03 12:38:48'),
(5, 2, 3, 'Mohamed Ahmed', 'assets/images/profile_avatar.png', 'هاي عاملين ايه', 1, '2026-05-03 12:38:48'),
(6, 2, NULL, 'Ahmed Ali', 'assets/images/live150_comment_avatar.png', 'منورين اللايف', 2, '2026-05-03 12:38:48');

-- Data for table `live_room_notifications`
INSERT INTO `live_room_notifications` (`id`, `room_id`, `title_text`, `body_text`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 1, 'اعلان الجولة', 'ابدأوا التفاعل الآن والجولة الحالية مفتوحة لمدة 15 دقيقة.', 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 1, 'تنبيه اداري', 'يمنع نشر أي محتوى مخالف داخل الدردشة المباشرة.', 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 2, 'ترحيب', 'أهلًا بكل المشاهدين الجدد في اللايف الحالي.', 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `live_room_reports`
INSERT INTO `live_room_reports` (`id`, `room_id`, `reporter_user_id`, `reporter_name`, `reason_text`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'Yara Mohamed', 'محتوى غير مناسب داخل الدردشة.', 'new', '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 2, 2, 'Nona Mohamed', 'صوت مزعج ومخالف للتعليمات.', 'reviewed', '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `live_pk_invites`
INSERT INTO `live_pk_invites` (`id`, `room_id`, `sender_user_id`, `sender_name`, `recipient_user_id`, `recipient_name_snapshot`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 3, 'Mohamed Ahmed', 1, 'Yara Mohamed', 'sent', '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 1, 3, 'Mohamed Ahmed', 2, 'Nona Mohamed', 'accepted', '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `live_room_gift_transactions`
INSERT INTO `live_room_gift_transactions` (`id`, `room_id`, `sender_user_id`, `sender_name`, `sender_avatar_asset`, `gift_id`, `gift_name_snapshot`, `quantity`, `unit_price_coins`, `total_price_coins`, `created_at`) VALUES
(1, 1, 3, 'Mohamed Ahmed', 'assets/images/profile_avatar.png', 1, 'الهدية الصغيرة', 10, 10, 100, '2026-05-03 12:38:48'),
(2, 1, 1, 'Yara Mohamed', 'assets/images/profile_avatar.png', 1, 'الهدية الصغيرة', 8, 10, 80, '2026-05-03 12:38:48'),
(3, 1, 2, 'Nona Mohamed', 'assets/images/profile_avatar.png', 1, 'الهدية الصغيرة', 5, 10, 50, '2026-05-03 12:38:48');

-- Data for table `user_wallets`
INSERT INTO `user_wallets` (`user_id`, `coins_balance`, `diamonds_balance`, `created_at`, `updated_at`) VALUES
(1, 1235, 5, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 1235, 5, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 1235, 5, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `wallet_packages`
INSERT INTO `wallet_packages` (`id`, `wallet_type`, `amount`, `bonus_amount`, `price_label`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 'diamonds', 30990, 0, '2,894,99 ج.م', 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'diamonds', 6090, 0, '578,99 ج.م', 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 'diamonds', 600, 300, '57,99 ج.م', 'active', 3, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(4, 'diamonds', 122990, 1000, '11,536,99 ج.م', 'active', 4, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(5, 'diamonds', 61990, 0, '5,736,99 ج.م', 'active', 5, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(6, 'coins', 5000, 0, '500', 'active', 6, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(7, 'coins', 1000, 0, '100', 'active', 7, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(8, 'coins', 100, 0, '10', 'active', 8, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(9, 'coins', 5000000, 0, '500000', 'active', 9, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(10, 'coins', 100000, 0, '10000', 'active', 10, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(11, 'coins', 10000, 0, '1000', 'active', 11, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `gifts`
INSERT INTO `gifts` (`id`, `name`, `category`, `asset_path`, `animation_path`, `sound_path`, `is_animated`, `effect_duration_ms`, `price_coins`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 'الهدية الصغيرة', 'الهداية عادية', 'assets/images/room_gift_1.png', NULL, NULL, 0, 1800, 10, 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'الهدية الصغيرة', 'الهداية عادية', 'assets/images/room_gift_2.png', NULL, NULL, 0, 1800, 10, 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 'الهدية الصغيرة', 'الهداية عادية', 'assets/images/room_gift_3.png', NULL, NULL, 0, 1800, 10, 'active', 3, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(4, 'الهدية الصغيرة', 'الهداية عادية', 'assets/images/room_gift_4.png', NULL, NULL, 0, 1800, 10, 'active', 4, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(5, 'الهدية الصغيرة', 'VIP', 'assets/images/room_gift_5.png', NULL, NULL, 0, 1800, 20, 'active', 5, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(6, 'الهدية الصغيرة', 'VIP', 'assets/images/room_gift_6.png', NULL, NULL, 0, 1800, 25, 'active', 6, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(7, 'الهدية الصغيرة', 'المحظوظ', 'assets/images/room_gift_7.png', NULL, NULL, 0, 1800, 30, 'active', 7, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(8, 'الهدية الصغيرة', 'متحرك', 'assets/images/room_gift_8.png', 'assets/images/room_gift_8.png', NULL, 1, 2200, 40, 'active', 8, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `store_items`
INSERT INTO `store_items` (`id`, `category_key`, `name`, `preview_asset_path`, `dialog_icon_asset_path`, `dialog_preview_asset_path`, `price_3_days`, `price_7_days`, `price_15_days`, `price_30_days`, `discount_3_days`, `discount_7_days`, `discount_15_days`, `discount_30_days`, `currency_type`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 'frames', 'الاطار القوي', 'assets/images/profile_store_frames_preview_overlay.png', 'assets/images/profile_store_frames_dialog_icon.png', NULL, 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'frames', 'الاطار الملكي', 'assets/images/profile_store_frames_preview_overlay.png', 'assets/images/profile_store_frames_dialog_icon.png', NULL, 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 'frames', 'اطار الماس', 'assets/images/profile_store_frames_preview_overlay.png', 'assets/images/profile_store_frames_dialog_icon.png', NULL, 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 3, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(4, 'animated_frames', 'رسم ادوات', 'assets/images/profile_store_animated_frames_item.png', 'assets/images/profile_store_animated_frames_dialog_icon.png', 'assets/images/profile_store_animated_frames_dialog_preview.png', 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 4, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(5, 'animated_frames', 'رسم ادوات', 'assets/images/profile_store_animated_frames_item.png', 'assets/images/profile_store_animated_frames_dialog_icon.png', 'assets/images/profile_store_animated_frames_dialog_preview.png', 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 5, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(6, 'backgrounds', 'خلفية روم ذهبية', 'assets/images/profile_store_background_preview.png', NULL, NULL, 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 6, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(7, 'backgrounds', 'خلفية روم ملكية', 'assets/images/profile_store_background_preview.png', NULL, NULL, 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 7, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(8, 'chat_frames', 'اطار محادثة فاخر', 'assets/images/profile_store_chat_frames_item.png', NULL, NULL, 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 8, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(9, 'chat_frames', 'اطار محادثة فضي', 'assets/images/profile_store_chat_frames_item.png', NULL, NULL, 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 9, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(10, 'entry_effects', 'الاطار المتحرك السريع', 'assets/images/profile_store_entry_effects_fast_frame_item.png', 'assets/images/profile_store_entry_effects_fast_frame_dialog_icon.png', 'assets/images/profile_store_entry_effects_fast_frame_dialog_preview.png', 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 10, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(11, 'entry_effects', 'الاطار المتحرك السريع', 'assets/images/profile_store_entry_effects_fast_frame_item.png', 'assets/images/profile_store_entry_effects_fast_frame_dialog_icon.png', 'assets/images/profile_store_entry_effects_fast_frame_dialog_preview.png', 90, 180, 330, 540, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 11, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(12, 'aristocracy', 'شارة الاستقراطية', 'assets/images/profile_store_aristocracy_icon.png', 'assets/images/profile_store_aristocracy_icon.png', 'assets/images/profile_store_aristocracy_icon.png', 120, 240, 450, 720, '10% Off', '22% Off', '27% Off', '27% Off', 'coins', 'active', 12, '2026-05-07 00:00:00', '2026-05-07 00:00:00');

-- Data for table `music_tracks`
INSERT INTO `music_tracks` (`id`, `title`, `artist_name`, `source_type`, `cover_asset`, `duration_seconds`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 'Friends Beat 01', 'DJ Nona', 'friends', 'assets/images/profile_store_friend_nona_avatar.png', 192, 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'Friends Beat 02', 'Mohammed Ahmed', 'friends', 'assets/images/profile_avatar.png', 205, 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 'Friends Beat 03', 'Sara Mohamed', 'friends', 'assets/images/live150_comment_avatar.png', 176, 'active', 3, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(4, 'WhatsApp Voice Mix', 'Support Team', 'whatsapp', 'assets/images/home_room_service.png', 170, 'active', 4, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(5, 'WhatsApp Party Loop', 'Ahmed Ali', 'whatsapp', 'assets/images/home_room_1.png', 214, 'active', 5, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(6, 'WhatsApp Chill 03', 'Nour Salem', 'whatsapp', 'assets/images/home_room_2.png', 188, 'active', 6, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `room_games_catalog`
INSERT INTO `room_games_catalog` (`id`, `game_key`, `name`, `category_key`, `icon_asset`, `description_text`, `min_players`, `max_players`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 'wheel_of_fortune', 'عجلة الحظ', 'luck', 'assets/images/room_game_wheel_icon.png', 'لعبة سريعة داخل الغرفة لاختيار الفائز بالحظ بين الأعضاء.', 1, 8, 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'ludo', 'لودو', 'board', 'assets/images/room_game_ludo_icon.png', 'جلسة لودو جماعية خفيفة بين أعضاء الغرفة.', 2, 4, 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 'domino', 'دومينو', 'board', 'assets/images/room_game_domino_icon.png', 'لعبة دومينو داخل الغرفة مع إمكانية انضمام عدة لاعبين.', 2, 4, 'active', 3, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `room_gift_transactions`
INSERT INTO `room_gift_transactions` (`id`, `room_id`, `sender_user_id`, `sender_name`, `sender_avatar_asset`, `gift_id`, `gift_name_snapshot`, `quantity`, `unit_price_coins`, `total_price_coins`, `recipient_mode`, `recipient_slot`, `created_at`) VALUES
(1, 1, NULL, 'Mohammed Ahmed', 'assets/images/profile_avatar.png', 1, 'الهدية الصغيرة', 20, 10, 200, 'room_users', NULL, '2026-05-03 12:38:48'),
(2, 1, NULL, 'Ahmed Ali', 'assets/images/profile_avatar.png', 1, 'الهدية الصغيرة', 20, 10, 200, 'room_users', NULL, '2026-05-03 12:38:48'),
(3, 1, NULL, 'Sara Mohamed', 'assets/images/profile_avatar.png', 1, 'الهدية الصغيرة', 20, 10, 200, 'room_users', NULL, '2026-05-03 12:38:48'),
(4, 1, NULL, 'Mohammed Ahmed', 'assets/images/profile_avatar.png', 1, 'الهدية الصغيرة', 21, 1, 21, 'room_users', NULL, '2026-05-03 12:38:48');

-- Data for table `shipping_agencies`
INSERT INTO `shipping_agencies` (`id`, `name`, `handle`, `diamond_balance`, `supported_country_codes`, `status`, `display_order`, `created_at`, `updated_at`) VALUES
(1, 'Mohamed Ahmed', '@ ابو احمد', 30500000, '["at","az","ae"]', 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'Sara Mohamed', '@ سارة', 17200000, '["ae","az"]', 'active', 2, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(3, 'Nour Salem', '@ نور', 8900000, '["at","ae"]', 'active', 3, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `support_tickets`
INSERT INTO `support_tickets` (`id`, `ticket_code`, `user_id`, `sender_name`, `sender_email`, `sender_phone`, `category`, `description`, `status`, `attachment_count`, `admin_note`, `created_at`, `updated_at`) VALUES
(1, 'SUP-000001', NULL, 'Mohamed Ahmed', 'mohamed@example.com', '01012345678', 'اعادة الشحن', 'تم خصم الرصيد ولم تصلني العملات داخل التطبيق حتى الآن.', 'new', 0, NULL, '2026-05-03 12:38:48', '2026-05-03 12:38:48'),
(2, 'SUP-000002', NULL, 'Sara Mohamed', 'sara@example.com', '01076543210', 'مشكلة تطبيق', 'التطبيق يغلق عند فتح شاشة المحفظة على بعض الأجهزة.', 'in_progress', 0, 'جارٍ مراجعة السجلات وإعادة الاختبار.', '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `posts`
INSERT INTO `posts` (`id`, `author_user_id`, `author_key`, `author_name`, `author_avatar_asset`, `body_text`, `image_path`, `status`, `report_count`, `like_count`, `comment_count`, `share_count`, `created_at`, `updated_at`) VALUES
(1, NULL, 'seed:asmaa', 'اسماء فتحي', 'assets/images/post_author_avatar.png', 'لا تعود الايام الي فاتت ولا تنتظر احد 💔
لا تعود الايام الي فاتت ولا تنتظر احد 💔
لا تعود الايام الي فاتت ولا تنتظر احد 💔', NULL, 'active', 0, 0, 1, 0, '2026-05-03 00:38:48', '2026-05-03 00:38:48'),
(2, NULL, 'seed:nour', 'نور سالم', 'assets/images/post_author_avatar.png', 'من اجمل اللحظات ان تجد من يفهمك بدون شرح.
من اجمل اللحظات ان تجد من يفهمك بدون شرح.', NULL, 'active', 0, 0, 0, 0, '2026-05-02 18:38:48', '2026-05-02 18:38:48'),
(3, NULL, 'seed:mohamed', 'محمد احمد', 'assets/images/post_author_avatar.png', 'لا تزال البداية ممكنة مهما تأخر الوقت.
لا تزال البداية ممكنة مهما تأخر الوقت.', NULL, 'active', 0, 0, 2, 0, '2026-05-02 00:38:48', '2026-05-02 00:38:48');

-- Data for table `post_comments`
INSERT INTO `post_comments` (`id`, `post_id`, `user_id`, `author_name_snapshot`, `body_text`, `created_at`) VALUES
(1, 1, NULL, 'محمد احمد', 'منشور جميل جدا.', '2026-05-03 00:38:48'),
(2, 3, NULL, 'محمد احمد', 'منشور جميل جدا.', '2026-05-02 00:38:48'),
(3, 3, NULL, 'سارة محمد', 'كلام حقيقي.', '2026-05-02 00:38:48');

-- Data for table `user_settings`
INSERT INTO `user_settings` (`user_id`, `private_profile`, `allow_direct_messages`, `show_online_status`, `receive_chat_notifications`, `receive_live_notifications`, `receive_room_invites`, `receive_party_invites`, `preferred_language`, `updated_at`) VALUES
(1, 0, 1, 1, 1, 1, 1, 1, 'ar', '2026-05-03 12:38:48'),
(2, 0, 1, 1, 1, 1, 1, 1, 'ar', '2026-05-03 12:38:48'),
(3, 0, 1, 1, 1, 1, 1, 1, 'ar', '2026-05-03 12:38:48');

-- Data for table `agencies`
INSERT INTO `agencies` (`id`, `owner_user_id`, `name`, `invitation_code`, `country`, `phone`, `address`, `avatar_path`, `front_id_path`, `back_id_path`, `status`, `member_count`, `created_at`, `updated_at`) VALUES
(1, 3, 'وكالة النخبة', 'VL-AGY-2026', 'مصر', '201011223344', 'القاهرة - مدينة نصر', NULL, NULL, NULL, 'active', 1, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `agency_open_requests`
INSERT INTO `agency_open_requests` (`id`, `request_code`, `user_id`, `agency_name`, `country`, `phone`, `address`, `avatar_path`, `front_id_path`, `back_id_path`, `status`, `admin_note`, `agency_id`, `created_at`, `updated_at`) VALUES
(1, 'AOR-000001', 1, 'وكالة يارا', 'مصر', '201022334455', 'الإسكندرية - سموحة', NULL, NULL, NULL, 'new', NULL, NULL, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

-- Data for table `agency_join_requests`
INSERT INTO `agency_join_requests` (`id`, `request_code`, `user_id`, `agency_id`, `invitation_code`, `agency_name_snapshot`, `agency_type`, `status`, `admin_note`, `created_at`, `updated_at`) VALUES
(1, 'AJR-000001', 2, 1, 'VL-AGY-2026', 'وكالة النخبة', 'لايف وشات', 'new', NULL, '2026-05-03 12:38:48', '2026-05-03 12:38:48');

SET UNIQUE_CHECKS = 1;
SET FOREIGN_KEY_CHECKS = 1;
