SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `live_pk_taps` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `room_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NULL,
  `side` VARCHAR(20) NOT NULL,
  `tap_count` INT NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_live_pk_taps_room_side` (`room_id`, `side`, `created_at`),
  KEY `idx_live_pk_taps_user` (`user_id`, `created_at`),
  CONSTRAINT `fk_live_pk_taps_room` FOREIGN KEY (`room_id`) REFERENCES `live_rooms` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
