SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `live_action_buttons` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `section_key` VARCHAR(80) NOT NULL,
  `section_title` VARCHAR(120) NOT NULL,
  `section_order` INT NOT NULL DEFAULT 0,
  `action_key` VARCHAR(120) NOT NULL,
  `label` VARCHAR(160) NOT NULL,
  `icon_kind` VARCHAR(80) NOT NULL DEFAULT 'custom',
  `icon_asset` VARCHAR(255) NOT NULL DEFAULT '',
  `behavior` VARCHAR(80) NOT NULL DEFAULT 'custom',
  `detail_title` VARCHAR(180) NOT NULL DEFAULT '',
  `detail_body` TEXT NULL,
  `requires_host` TINYINT(1) NOT NULL DEFAULT 0,
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `display_order` INT NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_live_action_key` (`action_key`),
  KEY `idx_live_action_section` (`section_key`, `section_order`, `display_order`),
  KEY `idx_live_action_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `live_room_action_events` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `room_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NULL,
  `action_button_id` INT UNSIGNED NULL,
  `action_key` VARCHAR(120) NOT NULL,
  `action_label_snapshot` VARCHAR(160) NOT NULL,
  `metadata_json` TEXT NULL,
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_live_action_events_room` (`room_id`, `created_at`),
  KEY `idx_live_action_events_action` (`action_key`, `created_at`),
  CONSTRAINT `fk_live_action_events_room` FOREIGN KEY (`room_id`) REFERENCES `live_rooms` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `live_action_buttons`
(`section_key`, `section_title`, `section_order`, `action_key`, `label`, `icon_kind`, `icon_asset`, `behavior`, `detail_title`, `detail_body`, `requires_host`, `status`, `display_order`, `created_at`, `updated_at`)
VALUES
('broadcast', 'ادارة البث', 10, 'beauty', 'جمال', 'beauty', 'assets/images/live153_beauty.png', 'beauty', 'جمال البث', 'يفعل تحسينات الصورة أثناء البث الحقيقي عبر Agora.', 1, 'active', 10, NOW(), NOW()),
('broadcast', 'ادارة البث', 10, 'sticker', 'ملصق', 'sticker', 'assets/images/live153_sticker.png', 'sticker', 'ملصقات اللايف', 'يمكنك التحكم في ملصقات وطبقات البث من لوحة التحكم.', 1, 'active', 20, NOW(), NOW()),
('broadcast', 'ادارة البث', 10, 'interface', 'واجهة', 'interface', '', 'interface', 'واجهة البث', 'تحكم في مظهر واجهة اللايف والطبقات المعروضة للمشاهدين.', 1, 'active', 30, NOW(), NOW()),
('broadcast', 'ادارة البث', 10, 'mute', 'كتم الصوت', 'mute', '', 'mute', 'كتم الصوت', 'يكتم أو يشغل صوت اللايف حسب دور المستخدم.', 0, 'active', 40, NOW(), NOW()),
('broadcast', 'ادارة البث', 10, 'headset_monitor', 'مراقب سماعة\nالاذن', 'headset', '', 'custom', 'مراقب سماعة الأذن', 'يسجل فتح أداة مراقبة الصوت ويمكن تعديل تفاصيلها من الأدمن.', 1, 'active', 50, NOW(), NOW()),
('room', 'ادارة الغرفة', 20, 'room_notice', 'نشرة الغرفة', 'announcement', '', 'notifications', 'نشرة الغرفة', 'يعرض إشعارات اللايف المرتبطة بالغرفة من لوحة التحكم.', 0, 'active', 10, NOW(), NOW()),
('room', 'ادارة الغرفة', 20, 'welcome_message', 'اعدادات رسالة\nالترحيب', 'welcome', '', 'welcome_message', 'رسالة الترحيب', 'رسالة الترحيب يتم التحكم فيها من الأدمن وتظهر للمستخدمين داخل اللايف.', 1, 'active', 20, NOW(), NOW()),
('room', 'ادارة الغرفة', 20, 'new_user', 'مستخدم جديد', 'new_user', '', 'viewers', 'المشاهدون', 'يفتح قائمة المشاهدين الحاليين بداتا حقيقية.', 0, 'active', 30, NOW(), NOW()),
('room', 'ادارة الغرفة', 20, 'room_admin', 'مسؤول الغرفة', 'admin', '', 'room_admin', 'مسؤول الغرفة', 'إدارة مسؤولين ومشرفي اللايف من لوحة التحكم.', 1, 'active', 40, NOW(), NOW()),
('room', 'ادارة الغرفة', 20, 'entry_rank', 'القيمة في ترتيب\nالدخولية', 'ranking', '', 'supporters', 'ترتيب الدخولية', 'يفتح ترتيب الداعمين والمساهمات في الجولة الحالية.', 0, 'active', 50, NOW(), NOW()),
('games', 'مركز الالعاب', 30, 'valorant_1', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 'active', 10, NOW(), NOW()),
('games', 'مركز الالعاب', 30, 'valorant_2', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 'active', 20, NOW(), NOW()),
('games', 'مركز الالعاب', 30, 'valorant_3', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 'active', 30, NOW(), NOW()),
('games', 'مركز الالعاب', 30, 'valorant_4', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 'active', 40, NOW(), NOW()),
('games', 'مركز الالعاب', 30, 'valorant_5', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 'active', 50, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  `section_title` = VALUES(`section_title`),
  `section_order` = VALUES(`section_order`),
  `label` = VALUES(`label`),
  `icon_kind` = VALUES(`icon_kind`),
  `icon_asset` = VALUES(`icon_asset`),
  `behavior` = VALUES(`behavior`),
  `detail_title` = VALUES(`detail_title`),
  `detail_body` = VALUES(`detail_body`),
  `requires_host` = VALUES(`requires_host`),
  `display_order` = VALUES(`display_order`),
  `updated_at` = NOW();
