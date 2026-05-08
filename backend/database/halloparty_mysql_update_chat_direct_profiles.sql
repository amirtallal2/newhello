-- HalloParty update: direct chat profiles.
-- Run this once on the production MySQL database.

ALTER TABLE `chat_threads`
  ADD COLUMN IF NOT EXISTS `target_user_id` INT UNSIGNED NULL AFTER `owner_user_id`;
