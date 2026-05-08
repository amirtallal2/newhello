-- Hallo Party live/voice gifts media update.
-- Safe to import once or more than once.

SET @halloparty_schema_name = DATABASE();

SET @halloparty_sql = IF(
    (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = @halloparty_schema_name
       AND TABLE_NAME = 'gifts'
       AND COLUMN_NAME = 'animation_path') = 0,
    'ALTER TABLE `gifts` ADD COLUMN `animation_path` VARCHAR(255) NULL AFTER `asset_path`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = @halloparty_schema_name
       AND TABLE_NAME = 'gifts'
       AND COLUMN_NAME = 'sound_path') = 0,
    'ALTER TABLE `gifts` ADD COLUMN `sound_path` VARCHAR(255) NULL AFTER `animation_path`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = @halloparty_schema_name
       AND TABLE_NAME = 'gifts'
       AND COLUMN_NAME = 'is_animated') = 0,
    'ALTER TABLE `gifts` ADD COLUMN `is_animated` TINYINT(1) NOT NULL DEFAULT 0 AFTER `sound_path`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

SET @halloparty_sql = IF(
    (SELECT COUNT(*)
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = @halloparty_schema_name
       AND TABLE_NAME = 'gifts'
       AND COLUMN_NAME = 'effect_duration_ms') = 0,
    'ALTER TABLE `gifts` ADD COLUMN `effect_duration_ms` INT NOT NULL DEFAULT 1800 AFTER `is_animated`',
    'SELECT 1'
);
PREPARE halloparty_stmt FROM @halloparty_sql;
EXECUTE halloparty_stmt;
DEALLOCATE PREPARE halloparty_stmt;

UPDATE `gifts`
SET
  `is_animated` = CASE WHEN `category` = 'متحرك' THEN 1 ELSE `is_animated` END,
  `animation_path` = CASE
    WHEN `category` = 'متحرك' AND (`animation_path` IS NULL OR `animation_path` = '') THEN `asset_path`
    ELSE `animation_path`
  END,
  `effect_duration_ms` = CASE
    WHEN `effect_duration_ms` IS NULL OR `effect_duration_ms` < 600 THEN 1800
    ELSE `effect_duration_ms`
  END
WHERE `category` = 'متحرك'
   OR `effect_duration_ms` IS NULL
   OR `effect_duration_ms` < 600;
