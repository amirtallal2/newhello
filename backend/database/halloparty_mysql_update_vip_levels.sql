-- Hallo Party VIP levels update.
-- Safe to import once or more than once from phpMyAdmin / aaPanel.

SET @halloparty_schema_name = DATABASE();

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND COLUMN_NAME = 'level_current') = 0,
    'ALTER TABLE `users` ADD COLUMN `level_current` INT NOT NULL DEFAULT 0',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND COLUMN_NAME = 'level_next') = 0,
    'ALTER TABLE `users` ADD COLUMN `level_next` INT NOT NULL DEFAULT 1',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND COLUMN_NAME = 'level_progress_percent') = 0,
    'ALTER TABLE `users` ADD COLUMN `level_progress_percent` INT NOT NULL DEFAULT 67',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND COLUMN_NAME = 'vip_tier') = 0,
    'ALTER TABLE `users` ADD COLUMN `vip_tier` VARCHAR(40) NULL DEFAULT "VIP 0"',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND COLUMN_NAME = 'badges_count') = 0,
    'ALTER TABLE `users` ADD COLUMN `badges_count` INT NOT NULL DEFAULT 4',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

CREATE TABLE IF NOT EXISTS `vip_levels` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `tier_number` INT NOT NULL UNIQUE,
  `name` VARCHAR(80) NOT NULL,
  `subtitle` VARCHAR(160) NOT NULL DEFAULT '',
  `description` VARCHAR(255) NOT NULL DEFAULT '',
  `price_coins` INT NOT NULL DEFAULT 0,
  `duration_days` INT NOT NULL DEFAULT 30,
  `hero_asset_path` VARCHAR(500) NULL,
  `badge_asset_path` VARCHAR(500) NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `display_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vip_privileges` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `unlock_tier` INT NOT NULL DEFAULT 1,
  `title` VARCHAR(160) NOT NULL,
  `description` VARCHAR(255) NOT NULL DEFAULT '',
  `icon_asset_path` VARCHAR(500) NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `display_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  UNIQUE KEY `uq_vip_privileges_title` (`title`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_vip_subscriptions` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `level_id` INT UNSIGNED NOT NULL,
  `tier_name` VARCHAR(80) NOT NULL,
  `source` VARCHAR(20) NOT NULL DEFAULT 'self',
  `started_at` DATETIME NOT NULL,
  `expires_at` DATETIME NOT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  KEY `idx_user_vip_subscriptions_user_status` (`user_id`, `status`),
  KEY `idx_user_vip_subscriptions_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vip_transactions` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `sender_user_id` INT UNSIGNED NOT NULL,
  `recipient_user_id` INT UNSIGNED NULL,
  `recipient_name_snapshot` VARCHAR(160) NULL,
  `level_id` INT UNSIGNED NOT NULL,
  `tier_name` VARCHAR(80) NOT NULL,
  `duration_days` INT NOT NULL DEFAULT 30,
  `price_coins` INT NOT NULL DEFAULT 0,
  `action_type` VARCHAR(20) NOT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'success',
  `created_at` DATETIME NOT NULL,
  KEY `idx_vip_transactions_sender` (`sender_user_id`),
  KEY `idx_vip_transactions_recipient` (`recipient_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `vip_levels`
  (`tier_number`, `name`, `subtitle`, `description`, `price_coins`, `duration_days`, `hero_asset_path`, `badge_asset_path`, `status`, `display_order`, `created_at`, `updated_at`)
VALUES
  (1, 'VIP 1', 'بداية العضوية المميزة', 'مناسب لمن يريد تجربة مزايا VIP الأساسية.', 9999, 30, 'https://api.builder.io/api/v1/image/assets/TEMP/16e7e797fedfea9339e02eecd482319097e0fed3?width=300', 'assets/images/profile_vip_icon.png', 'active', 1, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (2, 'VIP 2', 'حضور أوضح داخل الغرف', 'مزايا إضافية للظهور والتفاعل اليومي.', 29999, 30, 'https://api.builder.io/api/v1/image/assets/TEMP/16e7e797fedfea9339e02eecd482319097e0fed3?width=300', 'assets/images/profile_vip_icon.png', 'active', 2, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (3, 'VIP 3', 'مزايا اجتماعية أقوى', 'مناسب للمستخدمين النشطين في الغرف والشات.', 79999, 30, 'https://api.builder.io/api/v1/image/assets/TEMP/16e7e797fedfea9339e02eecd482319097e0fed3?width=300', 'assets/images/profile_vip_icon.png', 'active', 3, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (4, 'VIP 4', 'تميّز داخل اللايف والغرف', 'حزمة متقدمة للهدايا والحضور.', 149999, 30, 'https://api.builder.io/api/v1/image/assets/TEMP/16e7e797fedfea9339e02eecd482319097e0fed3?width=300', 'assets/images/profile_vip_icon.png', 'active', 4, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (5, 'VIP 5', 'عضوية صفوة المستخدمين', 'أولوية ومؤثرات قوية للمستخدمين الكبار.', 299999, 30, 'https://api.builder.io/api/v1/image/assets/TEMP/16e7e797fedfea9339e02eecd482319097e0fed3?width=300', 'assets/images/profile_vip_icon.png', 'active', 5, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'VIP 6', 'القمة الذهبية', 'كل مميزات VIP مفعلة بأعلى أولوية.', 499999, 30, 'https://api.builder.io/api/v1/image/assets/TEMP/16e7e797fedfea9339e02eecd482319097e0fed3?width=300', 'assets/images/profile_vip_icon.png', 'active', 6, UTC_TIMESTAMP(), UTC_TIMESTAMP())
ON DUPLICATE KEY UPDATE `tier_number` = `tier_number`;

INSERT INTO `vip_privileges`
  (`unlock_tier`, `title`, `description`, `icon_asset_path`, `status`, `display_order`, `created_at`, `updated_at`)
VALUES
  (1, 'المزيد من اعضاء غرفة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'https://api.builder.io/api/v1/image/assets/TEMP/4479a00c94fbcbc5459e692cd68cf3be49f19557?width=110', 'active', 1, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (1, 'وسام VIP', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'https://api.builder.io/api/v1/image/assets/TEMP/ab6ee03fe23e9a26074377ac29d11b337d1c5a4e?width=110', 'active', 2, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (1, 'اطار فاخر', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'https://api.builder.io/api/v1/image/assets/TEMP/8cc2292cca020431f739ec53b3aae69ab23183df?width=110', 'active', 3, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (1, 'العرض في القمة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_aristocracy_icon.png', 'active', 4, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (1, 'هدايا حصرية', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/room_gift_icon.png', 'active', 5, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (1, 'خلفية الغرفة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_backgrounds_icon.png', 'active', 6, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (1, 'الحصول يومي علي 100 الماسة مجانا', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_wallet_diamond_small.png', 'active', 7, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (1, 'منع المتابعة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_badges_icon.png', 'active', 8, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (2, 'اخفاء حالة online', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_badges_icon.png', 'active', 9, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (2, 'رسائل ملونة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_chat_frames_item.png', 'active', 10, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (2, 'اخبار بي الدخول', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_entry_effects_icon.png', 'active', 11, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (2, 'ترقية عالية السرعة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_level_icon.png', 'active', 12, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (2, 'خصم من المتجر', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_icon.png', 'active', 13, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (3, 'اضاءة المايك', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/room_mic_level_icon.png', 'active', 14, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (3, 'قبعات الدردشة الغرفة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_chat_hats_icon.png', 'active', 15, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (3, 'غلاف الغرفة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_background_preview.png', 'active', 16, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (3, 'مؤثرات الدخول', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_entry_effects_fast_frame_item.png', 'active', 17, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (4, 'ايقونة الغرفة الارستقراطية', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_aristocracy_card.png', 'active', 18, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (4, 'ارسال الصور في الشات', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_frames_icon.png', 'active', 19, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (4, 'الحصول علي بنر حصري لك', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_frames_card.png', 'active', 20, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (4, 'الالولية في الابلاغ', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_badges_icon.png', 'active', 21, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (4, 'اخطار بي الدخول', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_entry_effects_icon.png', 'active', 22, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (5, 'خدمة العملاء', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_support_icon.png', 'active', 23, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (5, 'غير قابل للحظر', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_badges_icon.png', 'active', 24, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (5, 'اخفاء عند زيارة الغرفة', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_badges_icon.png', 'active', 25, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (5, 'خاصية عدم التتبع', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_badges_icon.png', 'active', 26, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (5, 'اعلان الغرف المجاني يوميا في الاوال', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_background_power_icon.png', 'active', 27, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'خصم عند التجديد', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_icon.png', 'active', 28, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'ضعف مكافاة المهام', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_tasks_icon.png', 'active', 29, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'ايدي غرفة مميز', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/room_mic_level_icon.png', 'active', 30, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'تاثير مقعد vip', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_vip_icon.png', 'active', 31, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'المزيد من عدد الاصدقاء والماتبعون', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_level_icon.png', 'active', 32, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'ايدي مميز', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_vip_icon.png', 'active', 33, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'رموز تعبيرية حصرية', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_svip_icon.png', 'active', 34, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'شارة ذهبية داخل الملف الشخصي', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_badges_icon.png', 'active', 35, UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  (6, 'أولوية الظهور في توصيات الغرف', 'ميزة VIP قابلة للتحكم من لوحة الأدمن.', 'assets/images/profile_store_aristocracy_icon.png', 'active', 36, UTC_TIMESTAMP(), UTC_TIMESTAMP())
ON DUPLICATE KEY UPDATE `title` = `title`;
