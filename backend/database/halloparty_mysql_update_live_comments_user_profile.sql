-- HalloParty update: make live comments open real user profiles.
-- Run this once on the production MySQL database.

ALTER TABLE `live_room_comments`
  ADD COLUMN IF NOT EXISTS `commenter_user_id` INT UNSIGNED NULL AFTER `room_id`;

UPDATE `live_room_comments` comments
INNER JOIN `users` matched_user
  ON matched_user.nickname = comments.commenter_name
SET comments.commenter_user_id = matched_user.id,
    comments.avatar_asset = matched_user.avatar_asset
WHERE comments.commenter_user_id IS NULL;
