-- Hallo Party gift monetization update.
-- Safe to import once or more than once.

SET @halloparty_schema_name = DATABASE();

CREATE TABLE IF NOT EXISTS `app_settings` (
  `setting_key` VARCHAR(120) PRIMARY KEY,
  `setting_value` TEXT NOT NULL,
  `updated_at` DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `app_settings` (`setting_key`, `setting_value`, `updated_at`)
VALUES ('gift_platform_commission_percent', '50', UTC_TIMESTAMP())
ON DUPLICATE KEY UPDATE `setting_key` = `setting_key`;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'room_gift_transactions' AND COLUMN_NAME = 'recipient_user_id') = 0,
    'ALTER TABLE `room_gift_transactions` ADD COLUMN `recipient_user_id` INT UNSIGNED NULL AFTER `sender_avatar_asset`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'room_gift_transactions' AND COLUMN_NAME = 'recipient_name_snapshot') = 0,
    'ALTER TABLE `room_gift_transactions` ADD COLUMN `recipient_name_snapshot` VARCHAR(190) NULL AFTER `recipient_user_id`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'room_gift_transactions' AND COLUMN_NAME = 'platform_fee_coins') = 0,
    'ALTER TABLE `room_gift_transactions` ADD COLUMN `platform_fee_coins` INT NOT NULL DEFAULT 0 AFTER `total_price_coins`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'room_gift_transactions' AND COLUMN_NAME = 'creator_earning_diamonds') = 0,
    'ALTER TABLE `room_gift_transactions` ADD COLUMN `creator_earning_diamonds` INT NOT NULL DEFAULT 0 AFTER `platform_fee_coins`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'room_gift_transactions' AND COLUMN_NAME = 'platform_commission_percent') = 0,
    'ALTER TABLE `room_gift_transactions` ADD COLUMN `platform_commission_percent` DECIMAL(5,2) NOT NULL DEFAULT 50.00 AFTER `creator_earning_diamonds`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_gift_transactions' AND COLUMN_NAME = 'recipient_user_id') = 0,
    'ALTER TABLE `live_room_gift_transactions` ADD COLUMN `recipient_user_id` INT UNSIGNED NULL AFTER `sender_avatar_asset`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_gift_transactions' AND COLUMN_NAME = 'recipient_name_snapshot') = 0,
    'ALTER TABLE `live_room_gift_transactions` ADD COLUMN `recipient_name_snapshot` VARCHAR(190) NULL AFTER `recipient_user_id`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_gift_transactions' AND COLUMN_NAME = 'platform_fee_coins') = 0,
    'ALTER TABLE `live_room_gift_transactions` ADD COLUMN `platform_fee_coins` INT NOT NULL DEFAULT 0 AFTER `total_price_coins`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_gift_transactions' AND COLUMN_NAME = 'creator_earning_diamonds') = 0,
    'ALTER TABLE `live_room_gift_transactions` ADD COLUMN `creator_earning_diamonds` INT NOT NULL DEFAULT 0 AFTER `platform_fee_coins`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'live_room_gift_transactions' AND COLUMN_NAME = 'platform_commission_percent') = 0,
    'ALTER TABLE `live_room_gift_transactions` ADD COLUMN `platform_commission_percent` DECIMAL(5,2) NOT NULL DEFAULT 50.00 AFTER `creator_earning_diamonds`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;
