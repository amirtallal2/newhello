-- Hallo Party incremental update for real Agora live video rooms
-- Safe to import once or more than once.

SET @halloparty_schema_name = DATABASE();

SET @halloparty_sql = IF(
    (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = @halloparty_schema_name
       AND TABLE_NAME = 'live_rooms'
       AND COLUMN_NAME = 'host_user_id') = 0,
    'ALTER TABLE `live_rooms` ADD COLUMN `host_user_id` INT UNSIGNED NULL AFTER `host_id_label`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = @halloparty_schema_name
       AND TABLE_NAME = 'live_rooms'
       AND COLUMN_NAME = 'video_enabled') = 0,
    'ALTER TABLE `live_rooms` ADD COLUMN `video_enabled` TINYINT(1) NOT NULL DEFAULT 1 AFTER `host_user_id`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = @halloparty_schema_name
       AND TABLE_NAME = 'live_rooms'
       AND COLUMN_NAME = 'agora_channel_name') = 0,
    'ALTER TABLE `live_rooms` ADD COLUMN `agora_channel_name` VARCHAR(120) NULL AFTER `video_enabled`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

UPDATE `live_rooms`
SET `video_enabled` = 1
WHERE `video_enabled` IS NULL;

UPDATE `live_rooms`
SET `agora_channel_name` = CONCAT('live-room-', `id`)
WHERE `agora_channel_name` IS NULL OR `agora_channel_name` = '';
