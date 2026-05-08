-- Hallo Party clubs feature database update.
-- Import this file once in aaPanel/phpMyAdmin after backing up the database.
SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE IF NOT EXISTS `app_settings` (
  `setting_key` VARCHAR(120) PRIMARY KEY,
  `setting_value` TEXT NOT NULL,
  `updated_at` DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `clubs` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `owner_user_id` INT UNSIGNED NULL,
  `name` VARCHAR(120) NOT NULL,
  `code` VARCHAR(40) NOT NULL UNIQUE,
  `announcement_text` TEXT NULL,
  `avatar_asset` VARCHAR(255) NOT NULL,
  `members_count` INT NOT NULL DEFAULT 0,
  `rooms_count` INT NOT NULL DEFAULT 0,
  `ranking_points` INT NOT NULL DEFAULT 0,
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `creation_cost_diamonds` INT NOT NULL DEFAULT 500000,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  INDEX `idx_clubs_owner` (`owner_user_id`),
  INDEX `idx_clubs_status_rank` (`status`, `ranking_points`),
  CONSTRAINT `fk_clubs_owner_user` FOREIGN KEY (`owner_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `club_members` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `club_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NULL,
  `role` VARCHAR(20) NOT NULL DEFAULT 'member',
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `joined_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  UNIQUE KEY `uq_club_members_user` (`club_id`, `user_id`),
  INDEX `idx_club_members_user` (`user_id`),
  CONSTRAINT `fk_club_members_club` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_club_members_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `club_posts` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `club_id` INT UNSIGNED NOT NULL,
  `author_user_id` INT UNSIGNED NULL,
  `body_text` TEXT NOT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  INDEX `idx_club_posts_club` (`club_id`, `status`, `created_at`),
  CONSTRAINT `fk_club_posts_club` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_club_posts_author` FOREIGN KEY (`author_user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `app_settings` (`setting_key`, `setting_value`, `updated_at`)
VALUES ('club_creation_cost_diamonds', '500000', UTC_TIMESTAMP())
ON DUPLICATE KEY UPDATE `setting_value` = VALUES(`setting_value`), `updated_at` = VALUES(`updated_at`);

INSERT INTO `clubs`
  (`owner_user_id`, `name`, `code`, `announcement_text`, `avatar_asset`, `members_count`, `rooms_count`, `ranking_points`, `status`, `creation_cost_diamonds`, `created_at`, `updated_at`)
SELECT NULL, 'نادي ملوك هالو', 'HALLO', 'مسابقات وغرف يومية لأعضاء النادي.', 'assets/images/home_club_icon.png', 1280, 12, 89500, 'active', 500000, UTC_TIMESTAMP(), UTC_TIMESTAMP()
WHERE NOT EXISTS (SELECT 1 FROM `clubs` WHERE `code` = 'HALLO');

INSERT INTO `clubs`
  (`owner_user_id`, `name`, `code`, `announcement_text`, `avatar_asset`, `members_count`, `rooms_count`, `ranking_points`, `status`, `creation_cost_diamonds`, `created_at`, `updated_at`)
SELECT NULL, 'نادي الأصدقاء', 'FRIENDS', 'تعالوا نتجمع في غرف صوتية ولايفات يومية.', 'assets/images/profile_avatar.png', 640, 5, 43000, 'active', 500000, UTC_TIMESTAMP(), UTC_TIMESTAMP()
WHERE NOT EXISTS (SELECT 1 FROM `clubs` WHERE `code` = 'FRIENDS');

INSERT INTO `clubs`
  (`owner_user_id`, `name`, `code`, `announcement_text`, `avatar_asset`, `members_count`, `rooms_count`, `ranking_points`, `status`, `creation_cost_diamonds`, `created_at`, `updated_at`)
SELECT NULL, 'مزيكا لايف', 'MUSIC', 'غناء ومزيكا وتحديات PK طول الأسبوع.', 'assets/images/home_room_1.png', 420, 4, 28500, 'active', 500000, UTC_TIMESTAMP(), UTC_TIMESTAMP()
WHERE NOT EXISTS (SELECT 1 FROM `clubs` WHERE `code` = 'MUSIC');

INSERT INTO `club_posts` (`club_id`, `author_user_id`, `body_text`, `status`, `created_at`, `updated_at`)
SELECT `id`, NULL, `announcement_text`, 'active', UTC_TIMESTAMP(), UTC_TIMESTAMP()
FROM `clubs`
WHERE `code` IN ('HALLO', 'FRIENDS', 'MUSIC')
  AND NOT EXISTS (
    SELECT 1
    FROM `club_posts`
    WHERE `club_posts`.`club_id` = `clubs`.`id`
  );
