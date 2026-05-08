-- HalloParty update: shared posts + editable/reportable comments.
-- Run once on the live MySQL database before uploading the updated PHP files.

ALTER TABLE posts
    ADD COLUMN shared_post_id INT UNSIGNED NULL AFTER share_count;

CREATE INDEX idx_posts_shared_post_id ON posts (shared_post_id);

ALTER TABLE post_comments
    ADD COLUMN author_avatar_asset VARCHAR(255) NOT NULL DEFAULT 'assets/images/post_author_avatar.png' AFTER author_name_snapshot,
    ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'active' AFTER body_text,
    ADD COLUMN report_count INT NOT NULL DEFAULT 0 AFTER status,
    ADD COLUMN updated_at DATETIME NULL AFTER created_at;

UPDATE post_comments
SET author_avatar_asset = 'assets/images/post_author_avatar.png'
WHERE author_avatar_asset IS NULL OR author_avatar_asset = '';

UPDATE post_comments
SET status = 'active'
WHERE status IS NULL OR status = '';

UPDATE post_comments
SET updated_at = created_at
WHERE updated_at IS NULL;

CREATE INDEX idx_post_comments_post_status ON post_comments (post_id, status);

CREATE TABLE IF NOT EXISTS post_comment_reports (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    comment_id INT UNSIGNED NOT NULL,
    post_id INT UNSIGNED NOT NULL,
    reporter_user_id INT UNSIGNED NULL,
    reporter_name VARCHAR(190) NOT NULL,
    reason VARCHAR(190) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_post_comment_reports_comment FOREIGN KEY (comment_id) REFERENCES post_comments(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_comment_reports_post FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    CONSTRAINT fk_post_comment_reports_user FOREIGN KEY (reporter_user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_post_comment_reports_status ON post_comment_reports (status);
