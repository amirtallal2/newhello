-- Hallo Party referral / invitation code update.
-- Import this file from phpMyAdmin / aaPanel after uploading the backend update.

SET NAMES utf8mb4;
SET @halloparty_schema_name = DATABASE();

CREATE TABLE IF NOT EXISTS `app_settings` (
  `setting_key` VARCHAR(120) PRIMARY KEY,
  `setting_value` TEXT NOT NULL,
  `updated_at` DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND COLUMN_NAME = 'invite_code') = 0,
    'ALTER TABLE `users` ADD COLUMN `invite_code` VARCHAR(32) NULL',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND COLUMN_NAME = 'referred_by_user_id') = 0,
    'ALTER TABLE `users` ADD COLUMN `referred_by_user_id` INT UNSIGNED NULL',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'pending_registrations' AND COLUMN_NAME = 'referral_code') = 0,
    'ALTER TABLE `pending_registrations` ADD COLUMN `referral_code` VARCHAR(32) NULL',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

UPDATE `users`
SET `invite_code` = CONCAT('HP', UPPER(LPAD(CONV(`id`, 10, 36), 6, '0')))
WHERE `invite_code` IS NULL OR `invite_code` = '';

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND INDEX_NAME = 'idx_users_invite_code') = 0,
    'CREATE UNIQUE INDEX `idx_users_invite_code` ON `users` (`invite_code`)',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE TABLE_SCHEMA = @halloparty_schema_name AND TABLE_NAME = 'users' AND INDEX_NAME = 'idx_users_referred_by') = 0,
    'CREATE INDEX `idx_users_referred_by` ON `users` (`referred_by_user_id`)',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

CREATE TABLE IF NOT EXISTS `user_referrals` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `inviter_user_id` INT UNSIGNED NOT NULL,
  `invited_user_id` INT UNSIGNED NULL,
  `invite_code_snapshot` VARCHAR(32) NOT NULL,
  `status` VARCHAR(30) NOT NULL DEFAULT 'registered',
  `signup_reward_usd` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `recharge_reward_usd` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `total_reward_usd` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `registered_at` DATETIME NULL,
  `first_recharge_at` DATETIME NULL,
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  UNIQUE KEY `uq_user_referrals_invited_user` (`invited_user_id`),
  KEY `idx_user_referrals_inviter_status` (`inviter_user_id`, `status`),
  KEY `idx_user_referrals_code` (`invite_code_snapshot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `referral_reward_transactions` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `source_user_id` INT UNSIGNED NULL,
  `reward_type` VARCHAR(40) NOT NULL,
  `amount_usd` DECIMAL(12,2) NOT NULL DEFAULT 0,
  `rate_percent` DECIMAL(5,2) NOT NULL DEFAULT 0,
  `title` VARCHAR(190) NOT NULL,
  `subtitle` VARCHAR(255) NOT NULL DEFAULT '',
  `status` VARCHAR(30) NOT NULL DEFAULT 'available',
  `context_ref` VARCHAR(120) NULL,
  `created_at` DATETIME NOT NULL,
  KEY `idx_referral_rewards_user_status` (`user_id`, `status`),
  KEY `idx_referral_rewards_source` (`source_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `app_settings` (`setting_key`, `setting_value`, `updated_at`) VALUES
  ('referral_daily_target_usd', '50', UTC_TIMESTAMP()),
  ('referral_first_withdraw_usd', '50', UTC_TIMESTAMP()),
  ('referral_first_withdraw_days', '0', UTC_TIMESTAMP()),
  ('referral_signup_reward_usd', '1', UTC_TIMESTAMP()),
  ('referral_direct_recharge_percent', '15', UTC_TIMESTAMP()),
  ('referral_indirect_recharge_percent', '5', UTC_TIMESTAMP()),
  ('referral_invite_link_base', 'https://halloparty.online/invite?code=', UTC_TIMESTAMP()),
  ('referral_header_asset', 'https://api.builder.io/api/v1/image/assets/TEMP/f1efcaf22a2d59f5c185fe2e85fe9f5de0c62ae1?width=750', UTC_TIMESTAMP()),
  ('referral_reward_card_asset', 'https://api.builder.io/api/v1/image/assets/TEMP/162d7fea0ddaab2b573d9c5341b8a35a9e02bd54?width=654', UTC_TIMESTAMP()),
  ('referral_empty_asset', 'https://api.builder.io/api/v1/image/assets/TEMP/db7ce84fd71af7a6e23fb548746556307a630c39?width=136', UTC_TIMESTAMP())
ON DUPLICATE KEY UPDATE `setting_key` = `setting_key`;
