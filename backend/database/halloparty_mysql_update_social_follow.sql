-- Hallo Party social follow/friendship update.
-- Run this once after uploading the backend files.

CREATE TABLE IF NOT EXISTS `user_follows` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `follower_user_id` INT UNSIGNED NOT NULL,
  `followed_user_id` INT UNSIGNED NOT NULL,
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL,
  UNIQUE KEY `uq_user_follows_pair` (`follower_user_id`, `followed_user_id`),
  KEY `idx_user_follows_follower_status` (`follower_user_id`, `status`),
  KEY `idx_user_follows_followed_status` (`followed_user_id`, `status`),
  CONSTRAINT `fk_user_follows_follower` FOREIGN KEY (`follower_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_user_follows_followed` FOREIGN KEY (`followed_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

ALTER TABLE `chat_threads`
  ADD COLUMN IF NOT EXISTS `target_user_id` INT UNSIGNED NULL AFTER `owner_user_id`;

INSERT INTO `user_follows`
  (`follower_user_id`, `followed_user_id`, `status`, `created_at`, `updated_at`)
SELECT follower.id, followed.id, 'active', NOW(), NOW()
FROM `users` follower
JOIN `users` followed
WHERE follower.email = 'mohamed.store@voicelive.local'
  AND followed.email = 'yara.store@voicelive.local'
ON DUPLICATE KEY UPDATE `status` = 'active', `updated_at` = NOW();

INSERT INTO `user_follows`
  (`follower_user_id`, `followed_user_id`, `status`, `created_at`, `updated_at`)
SELECT follower.id, followed.id, 'active', NOW(), NOW()
FROM `users` follower
JOIN `users` followed
WHERE follower.email = 'yara.store@voicelive.local'
  AND followed.email = 'mohamed.store@voicelive.local'
ON DUPLICATE KEY UPDATE `status` = 'active', `updated_at` = NOW();

INSERT INTO `user_follows`
  (`follower_user_id`, `followed_user_id`, `status`, `created_at`, `updated_at`)
SELECT follower.id, followed.id, 'active', NOW(), NOW()
FROM `users` follower
JOIN `users` followed
WHERE follower.email = 'mohamed.store@voicelive.local'
  AND followed.email = 'nona.store@voicelive.local'
ON DUPLICATE KEY UPDATE `status` = 'active', `updated_at` = NOW();

INSERT INTO `user_follows`
  (`follower_user_id`, `followed_user_id`, `status`, `created_at`, `updated_at`)
SELECT follower.id, followed.id, 'active', NOW(), NOW()
FROM `users` follower
JOIN `users` followed
WHERE follower.email = 'nona.store@voicelive.local'
  AND followed.email = 'mohamed.store@voicelive.local'
ON DUPLICATE KEY UPDATE `status` = 'active', `updated_at` = NOW();

INSERT INTO `user_follows`
  (`follower_user_id`, `followed_user_id`, `status`, `created_at`, `updated_at`)
SELECT follower.id, followed.id, 'active', NOW(), NOW()
FROM `users` follower
JOIN `users` followed
WHERE follower.email = 'yara.store@voicelive.local'
  AND followed.email = 'nona.store@voicelive.local'
ON DUPLICATE KEY UPDATE `status` = 'active', `updated_at` = NOW();

UPDATE `users` user_row
SET
  `following_count` = (
    SELECT COUNT(*)
    FROM `user_follows`
    WHERE `follower_user_id` = user_row.id
      AND `status` = 'active'
  ),
  `followers_count` = (
    SELECT COUNT(*)
    FROM `user_follows`
    WHERE `followed_user_id` = user_row.id
      AND `status` = 'active'
  ),
  `friends_count` = (
    SELECT COUNT(*)
    FROM `user_follows` outgoing
    INNER JOIN `user_follows` incoming
      ON incoming.follower_user_id = outgoing.followed_user_id
     AND incoming.followed_user_id = outgoing.follower_user_id
     AND incoming.status = 'active'
    WHERE outgoing.follower_user_id = user_row.id
      AND outgoing.status = 'active'
  );

UPDATE `live_rooms` live_room
INNER JOIN `users` host_user
  ON host_user.nickname = live_room.host_name
SET live_room.host_user_id = host_user.id
WHERE live_room.host_user_id IS NULL
   OR live_room.host_user_id = 0;
