-- Hallo Party incremental update for Google auth + Agora voice rooms
-- Run this on your existing MySQL database from aaPanel / phpMyAdmin.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

ALTER TABLE `rooms`
    ADD COLUMN IF NOT EXISTS `host_user_id` INT UNSIGNED NULL AFTER `host_name`,
    ADD COLUMN IF NOT EXISTS `audio_enabled` TINYINT(1) NOT NULL DEFAULT 1 AFTER `background_asset`,
    ADD COLUMN IF NOT EXISTS `agora_channel_name` VARCHAR(120) NULL AFTER `audio_enabled`;

UPDATE `rooms`
SET `audio_enabled` = 1
WHERE `audio_enabled` IS NULL;

UPDATE `rooms`
SET `agora_channel_name` = CONCAT(
    'voice-room-',
    REPLACE(REPLACE(REPLACE(REPLACE(COALESCE(`room_code`, `id`), ' ', ''), '-', ''), '#', ''), '/', '')
)
WHERE `agora_channel_name` IS NULL OR `agora_channel_name` = '';

UPDATE `rooms` AS `r`
INNER JOIN `users` AS `u` ON `u`.`nickname` = `r`.`host_name`
SET
    `r`.`host_user_id` = COALESCE(`r`.`host_user_id`, `u`.`id`),
    `r`.`host_avatar_asset` = COALESCE(NULLIF(`u`.`avatar_asset`, ''), `r`.`host_avatar_asset`)
WHERE `r`.`host_user_id` IS NULL;

CREATE TABLE IF NOT EXISTS `room_audio_participants` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `room_id` INT UNSIGNED NOT NULL,
    `user_id` INT UNSIGNED NULL,
    `user_account` VARCHAR(190) NOT NULL,
    `display_name` VARCHAR(190) NOT NULL,
    `avatar_asset` VARCHAR(255) NULL,
    `role` VARCHAR(20) NOT NULL DEFAULT 'listener',
    `seat_number` INT NULL,
    `mic_muted` TINYINT(1) NOT NULL DEFAULT 1,
    `status` VARCHAR(20) NOT NULL DEFAULT 'joined',
    `joined_at` DATETIME NOT NULL,
    `last_seen_at` DATETIME NOT NULL,
    `left_at` DATETIME NULL,
    `updated_at` DATETIME NOT NULL,
    UNIQUE KEY `uq_room_audio_participants_room_account` (`room_id`, `user_account`),
    KEY `idx_room_audio_participants_room_status` (`room_id`, `status`),
    KEY `idx_room_audio_participants_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
