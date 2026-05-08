-- Hallo Party incremental update for create voice room
-- Apply this on an existing MySQL database when you only need the create-room schema changes.

SET NAMES utf8mb4;
SET time_zone = '+00:00';

SET @db_name := DATABASE();

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'rooms' AND COLUMN_NAME = 'creator_user_id') = 0,
  'ALTER TABLE `rooms` ADD COLUMN `creator_user_id` INT UNSIGNED NULL AFTER `host_user_id`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'rooms' AND COLUMN_NAME = 'room_type') = 0,
  'ALTER TABLE `rooms` ADD COLUMN `room_type` VARCHAR(40) NOT NULL DEFAULT ''غناء'' AFTER `creator_user_id`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'rooms' AND COLUMN_NAME = 'slogan_text') = 0,
  'ALTER TABLE `rooms` ADD COLUMN `slogan_text` VARCHAR(255) NULL AFTER `room_type`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @sql := IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA = @db_name AND TABLE_NAME = 'rooms' AND COLUMN_NAME = 'country_label') = 0,
  'ALTER TABLE `rooms` ADD COLUMN `country_label` VARCHAR(120) NOT NULL DEFAULT ''مصر'' AFTER `slogan_text`',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE `rooms`
SET `room_type` = 'غناء'
WHERE `room_type` IS NULL OR `room_type` = '';

UPDATE `rooms`
SET `slogan_text` = `subtitle`
WHERE (`slogan_text` IS NULL OR `slogan_text` = '')
  AND `subtitle` IS NOT NULL
  AND `subtitle` <> '';

UPDATE `rooms`
SET `country_label` = 'مصر'
WHERE `country_label` IS NULL OR `country_label` = '';
