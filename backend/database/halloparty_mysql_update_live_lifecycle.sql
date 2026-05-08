-- Hallo Party incremental update for real live lifecycle and viewer presence.
-- Safe to import once or more than once.

SET @halloparty_schema_name = DATABASE();

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_rooms' AND COLUMN_NAME = 'ended_at') = 0,
    'ALTER TABLE `live_rooms` ADD COLUMN `ended_at` DATETIME NULL AFTER `display_order`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND COLUMN_NAME = 'user_id') = 0,
    'ALTER TABLE `live_room_viewers` ADD COLUMN `user_id` INT UNSIGNED NULL AFTER `room_id`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND COLUMN_NAME = 'user_account') = 0,
    'ALTER TABLE `live_room_viewers` ADD COLUMN `user_account` VARCHAR(120) NULL AFTER `user_id`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND COLUMN_NAME = 'client_role') = 0,
    'ALTER TABLE `live_room_viewers` ADD COLUMN `client_role` VARCHAR(30) NOT NULL DEFAULT ''audience'' AFTER `user_account`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND COLUMN_NAME = 'is_online') = 0,
    'ALTER TABLE `live_room_viewers` ADD COLUMN `is_online` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_top_supporter`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND COLUMN_NAME = 'last_seen_at') = 0,
    'ALTER TABLE `live_room_viewers` ADD COLUMN `last_seen_at` DATETIME NULL AFTER `is_online`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND COLUMN_NAME = 'left_at') = 0,
    'ALTER TABLE `live_room_viewers` ADD COLUMN `left_at` DATETIME NULL AFTER `last_seen_at`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND COLUMN_NAME = 'updated_at') = 0,
    'ALTER TABLE `live_room_viewers` ADD COLUMN `updated_at` DATETIME NULL AFTER `created_at`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND INDEX_NAME = 'idx_live_viewers_presence') = 0,
    'CREATE INDEX `idx_live_viewers_presence` ON `live_room_viewers` (`room_id`, `is_online`, `last_seen_at`)',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_viewers' AND INDEX_NAME = 'uq_live_viewers_room_user') = 0,
    'CREATE UNIQUE INDEX `uq_live_viewers_room_user` ON `live_room_viewers` (`room_id`, `user_id`)',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

UPDATE `live_room_viewers`
SET `is_online` = 0
WHERE `is_online` IS NULL;
