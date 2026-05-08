-- Hallo Party post edit/delete/report reasons update.
-- Run this on the production MySQL database before uploading the new app build.

CREATE TABLE IF NOT EXISTS `post_report_reasons` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `reason_key` VARCHAR(120) NOT NULL UNIQUE,
  `label` VARCHAR(120) NOT NULL,
  `description` VARCHAR(255) NOT NULL DEFAULT '',
  `display_order` INT NOT NULL DEFAULT 0,
  `status` VARCHAR(20) NOT NULL DEFAULT 'active',
  `created_at` DATETIME NOT NULL,
  `updated_at` DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `post_report_reasons`
  (`reason_key`, `label`, `description`, `display_order`, `status`, `created_at`, `updated_at`)
VALUES
  ('spam', 'محتوى مزعج أو سبام', 'منشور متكرر أو دعائي أو غير حقيقي', 1, 'active', UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  ('abuse', 'إساءة أو تنمر', 'إهانة، تهديد، تنمر، أو خطاب مؤذي', 2, 'active', UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  ('adult', 'محتوى غير لائق', 'صور أو كلمات غير مناسبة للمجتمع', 3, 'active', UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  ('fraud', 'احتيال أو نصب', 'طلب أموال أو روابط مشبوهة أو انتحال', 4, 'active', UTC_TIMESTAMP(), UTC_TIMESTAMP()),
  ('other', 'سبب آخر', 'بلاغ عام يحتاج مراجعة الإدارة', 5, 'active', UTC_TIMESTAMP(), UTC_TIMESTAMP())
ON DUPLICATE KEY UPDATE
  `label` = VALUES(`label`),
  `description` = VALUES(`description`),
  `display_order` = VALUES(`display_order`),
  `status` = VALUES(`status`),
  `updated_at` = UTC_TIMESTAMP();
