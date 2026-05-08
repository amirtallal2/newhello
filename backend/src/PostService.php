<?php

declare(strict_types=1);

final class PostService
{
    private const POST_STATUS_OPTIONS = ['active', 'hidden'];
    private const REPORT_STATUS_OPTIONS = ['new', 'reviewed', 'resolved', 'rejected'];
    private const NOTIFICATION_TYPES = ['like', 'comment', 'share'];

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function feed(bool $friendsOnly, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];

        $this->ensureDefaultFollowings($userId);

        $sql = 'SELECT posts.*,
                       shared_posts.author_name AS shared_author_name,
                       shared_posts.author_avatar_asset AS shared_author_avatar_asset,
                       shared_posts.body_text AS shared_body_text,
                       shared_posts.image_path AS shared_image_path,
                       post_followings.id AS following_id,
                       author_follow.id AS author_following_id,
                       post_likes.id AS like_id
                FROM posts
                LEFT JOIN posts shared_posts
                    ON shared_posts.id = posts.shared_post_id
                LEFT JOIN post_followings
                    ON post_followings.author_key = posts.author_key
                   AND post_followings.user_id = :viewer_id
                LEFT JOIN user_follows author_follow
                    ON author_follow.followed_user_id = posts.author_user_id
                   AND author_follow.follower_user_id = :viewer_id
                   AND author_follow.status = "active"
                LEFT JOIN post_likes
                    ON post_likes.post_id = posts.id
                   AND post_likes.user_id = :viewer_id
                WHERE posts.status = :status';

        if ($friendsOnly) {
            $sql .= ' AND (
                author_follow.id IS NOT NULL
                OR post_followings.id IS NOT NULL
                OR posts.author_user_id = :friends_viewer_id
            )';
        }

        $sql .= ' ORDER BY posts.created_at DESC, posts.id DESC';

        $statement = $this->pdo->prepare($sql);
        $params = [
            'viewer_id' => $userId,
            'status' => 'active',
        ];

        if ($friendsOnly) {
            $params['friends_viewer_id'] = $userId;
        }

        $statement->execute($params);

        $posts = [];
        foreach ($statement->fetchAll() as $row) {
            $posts[] = $this->mapFeedPost($row, $userId);
        }

        return [
            'notification_count' => $this->countUnreadNotifications($userId),
            'posts' => $posts,
        ];
    }

    public function createPost(
        string $bodyText,
        ?array $imageDraft,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $bodyText = trim($bodyText);

        $imagePath = null;
        if ($imageDraft !== null) {
            $imagePath = $this->storeImageDraft($imageDraft);
        }

        if (($bodyText === '' && $imagePath === null) || mb_strlen($bodyText) > 1000) {
            throw new ApiException('Invalid post content.', 422);
        }

        $now = $this->now();
        $statement = $this->pdo->prepare(
            'INSERT INTO posts
                (author_user_id, author_key, author_name, author_avatar_asset, body_text, image_path, status, report_count, like_count, comment_count, share_count, shared_post_id, created_at, updated_at)
             VALUES
                (:author_user_id, :author_key, :author_name, :author_avatar_asset, :body_text, :image_path, :status, :report_count, :like_count, :comment_count, :share_count, :shared_post_id, :created_at, :updated_at)'
        );
        $statement->execute([
            'author_user_id' => (int) $user['id'],
            'author_key' => $this->authorKeyForUserId((int) $user['id']),
            'author_name' => $this->displayNameForUser($user),
            'author_avatar_asset' => $this->avatarForUser($user),
            'body_text' => $bodyText,
            'image_path' => $imagePath,
            'status' => 'active',
            'report_count' => 0,
            'like_count' => 0,
            'comment_count' => 0,
            'share_count' => 0,
            'shared_post_id' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return $this->feedPostById((int) $this->pdo->lastInsertId(), (int) $user['id']);
    }

    public function updatePost(
        int $postId,
        string $bodyText,
        ?array $imageDraft,
        bool $removeImage,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $post = $this->requirePost($postId);
        $this->assertOwnPost($post, (int) $user['id']);

        $bodyText = trim($bodyText);
        $imagePath = $post['image_path'] !== null ? (string) $post['image_path'] : null;

        if ($imageDraft !== null) {
            $imagePath = $this->storeImageDraft($imageDraft);
        } elseif ($removeImage) {
            $imagePath = null;
        }

        if (($bodyText === '' && $imagePath === null) || mb_strlen($bodyText) > 1000) {
            throw new ApiException('Invalid post content.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE posts
             SET body_text = :body_text,
                 image_path = :image_path,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'body_text' => $bodyText,
            'image_path' => $imagePath,
            'updated_at' => $this->now(),
            'id' => $postId,
        ]);

        return $this->feedPostById($postId, (int) $user['id']);
    }

    public function deletePost(int $postId, ?string $authorizationHeader): void
    {
        $user = $this->requireUser($authorizationHeader);
        $post = $this->requirePost($postId);
        $this->assertOwnPost($post, (int) $user['id']);

        $statement = $this->pdo->prepare(
            'UPDATE posts
             SET status = "hidden",
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'updated_at' => $this->now(),
            'id' => $postId,
        ]);
    }

    public function listReportReasons(): array
    {
        $statement = $this->pdo->query(
            'SELECT *
             FROM post_report_reasons
             WHERE status = "active"
             ORDER BY display_order ASC, id ASC'
        );

        return array_map(
            fn (array $reason): array => $this->mapReportReason($reason),
            $statement->fetchAll()
        );
    }

    public function toggleFollowByPost(int $postId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];
        $post = $this->requirePost($postId);

        if ((int) ($post['author_user_id'] ?? 0) === $userId) {
            return [
                'author_key' => (string) $post['author_key'],
                'author_user_id' => (int) ($post['author_user_id'] ?? 0),
                'is_followed' => false,
                'can_follow' => false,
            ];
        }

        $authorUserId = isset($post['author_user_id']) && $post['author_user_id'] !== null
            ? (int) $post['author_user_id']
            : 0;

        if ($authorUserId > 0 && class_exists(SocialService::class)) {
            $social = new SocialService($this->pdo);
            $socialResult = $social->toggleFollow($authorUserId, $authorizationHeader);
            $relationship = $socialResult['relationship'] ?? [];

            return [
                'author_key' => (string) $post['author_key'],
                'author_user_id' => $authorUserId,
                'is_followed' => ($relationship['is_following'] ?? false) === true,
                'is_friend' => ($relationship['is_friend'] ?? false) === true,
                'relationship' => $relationship,
                'can_follow' => true,
            ];
        }

        $existing = $this->pdo->prepare(
            'SELECT id FROM post_followings WHERE user_id = :user_id AND author_key = :author_key LIMIT 1'
        );
        $existing->execute([
            'user_id' => $userId,
            'author_key' => (string) $post['author_key'],
        ]);
        $row = $existing->fetch();

        if ($row === false) {
            $insert = $this->pdo->prepare(
                'INSERT INTO post_followings
                    (user_id, author_key, author_name_snapshot, created_at)
                 VALUES
                    (:user_id, :author_key, :author_name_snapshot, :created_at)'
            );
            $insert->execute([
                'user_id' => $userId,
                'author_key' => (string) $post['author_key'],
                'author_name_snapshot' => (string) $post['author_name'],
                'created_at' => $this->now(),
            ]);
            $isFollowed = true;
        } else {
            $delete = $this->pdo->prepare('DELETE FROM post_followings WHERE id = :id');
            $delete->execute(['id' => (int) $row['id']]);
            $isFollowed = false;
        }

        return [
            'author_key' => (string) $post['author_key'],
            'author_user_id' => $authorUserId > 0 ? $authorUserId : null,
            'is_followed' => $isFollowed,
            'can_follow' => true,
        ];
    }

    public function toggleLike(int $postId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $post = $this->requirePost($postId);
        $userId = (int) $user['id'];
        $now = $this->now();

        $this->pdo->beginTransaction();

        try {
            $existing = $this->pdo->prepare(
                'SELECT id FROM post_likes WHERE post_id = :post_id AND user_id = :user_id LIMIT 1'
            );
            $existing->execute([
                'post_id' => $postId,
                'user_id' => $userId,
            ]);
            $row = $existing->fetch();

            if ($row === false) {
                $insert = $this->pdo->prepare(
                    'INSERT INTO post_likes (post_id, user_id, created_at)
                     VALUES (:post_id, :user_id, :created_at)'
                );
                $insert->execute([
                    'post_id' => $postId,
                    'user_id' => $userId,
                    'created_at' => $now,
                ]);

                $this->incrementPostCounter($postId, 'like_count', 1);
                $this->createNotification(
                    $post,
                    $user,
                    'like',
                    sprintf('%s أعجب بمنشورك', $this->displayNameForUser($user))
                );
            } else {
                $delete = $this->pdo->prepare('DELETE FROM post_likes WHERE id = :id');
                $delete->execute(['id' => (int) $row['id']]);
                $this->incrementPostCounter($postId, 'like_count', -1);
            }

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->feedPostById($postId, $userId);
    }

    public function listComments(int $postId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $this->requirePost($postId);

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM post_comments
             WHERE post_id = :post_id
               AND status = "active"
             ORDER BY created_at ASC, id ASC'
        );
        $statement->execute(['post_id' => $postId]);

        $comments = [];
        foreach ($statement->fetchAll() as $comment) {
            $comments[] = $this->mapComment($comment, (int) $user['id']);
        }

        return [
            'composer_name' => $this->displayNameForUser($user),
            'comments' => $comments,
        ];
    }

    public function addComment(
        int $postId,
        string $bodyText,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $post = $this->requirePost($postId);
        $bodyText = trim($bodyText);

        if ($bodyText === '' || mb_strlen($bodyText) > 300) {
            throw new ApiException('Invalid comment content.', 422);
        }

        $now = $this->now();
        $this->pdo->beginTransaction();

        try {
            $insert = $this->pdo->prepare(
                'INSERT INTO post_comments
                    (post_id, user_id, author_name_snapshot, author_avatar_asset, body_text, status, report_count, created_at, updated_at)
                 VALUES
                    (:post_id, :user_id, :author_name_snapshot, :author_avatar_asset, :body_text, :status, :report_count, :created_at, :updated_at)'
            );
            $insert->execute([
                'post_id' => $postId,
                'user_id' => (int) $user['id'],
                'author_name_snapshot' => $this->displayNameForUser($user),
                'author_avatar_asset' => $this->avatarForUser($user),
                'body_text' => $bodyText,
                'status' => 'active',
                'report_count' => 0,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $this->incrementPostCounter($postId, 'comment_count', 1);
            $this->createNotification(
                $post,
                $user,
                'comment',
                sprintf('%s علّق على منشورك', $this->displayNameForUser($user))
            );

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->listComments($postId, $authorizationHeader);
    }

    public function updateComment(
        int $postId,
        int $commentId,
        string $bodyText,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $comment = $this->requireComment($postId, $commentId);
        $this->assertOwnComment($comment, (int) $user['id']);

        $bodyText = trim($bodyText);
        if ($bodyText === '' || mb_strlen($bodyText) > 300) {
            throw new ApiException('Invalid comment content.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE post_comments
             SET body_text = :body_text,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'body_text' => $bodyText,
            'updated_at' => $this->now(),
            'id' => $commentId,
        ]);

        return $this->listComments($postId, $authorizationHeader);
    }

    public function deleteComment(
        int $postId,
        int $commentId,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $comment = $this->requireComment($postId, $commentId);
        $this->assertOwnComment($comment, (int) $user['id']);

        $this->pdo->beginTransaction();

        try {
            $statement = $this->pdo->prepare(
                'UPDATE post_comments
                 SET status = "hidden",
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'updated_at' => $this->now(),
                'id' => $commentId,
            ]);

            $this->incrementPostCounter($postId, 'comment_count', -1);
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->listComments($postId, $authorizationHeader);
    }

    public function reportComment(
        int $postId,
        int $commentId,
        string $reason,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $comment = $this->requireComment($postId, $commentId);
        $reason = $this->resolveReportReasonLabel($reason);
        $userId = (int) $user['id'];

        if ((int) ($comment['user_id'] ?? 0) === $userId) {
            throw new ApiException('You cannot report your own comment.', 422);
        }

        $existing = $this->pdo->prepare(
            'SELECT id
             FROM post_comment_reports
             WHERE comment_id = :comment_id
               AND reporter_user_id = :reporter_user_id
               AND status IN ("new", "reviewed")
             LIMIT 1'
        );
        $existing->execute([
            'comment_id' => $commentId,
            'reporter_user_id' => $userId,
        ]);

        if ($existing->fetch() !== false) {
            throw new ApiException('تم إرسال بلاغك بالفعل.', 422);
        }

        $now = $this->now();
        $this->pdo->beginTransaction();

        try {
            $insert = $this->pdo->prepare(
                'INSERT INTO post_comment_reports
                    (comment_id, post_id, reporter_user_id, reporter_name, reason, status, created_at, updated_at)
                 VALUES
                    (:comment_id, :post_id, :reporter_user_id, :reporter_name, :reason, :status, :created_at, :updated_at)'
            );
            $insert->execute([
                'comment_id' => $commentId,
                'post_id' => $postId,
                'reporter_user_id' => $userId,
                'reporter_name' => $this->displayNameForUser($user),
                'reason' => $reason,
                'status' => 'new',
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $statement = $this->pdo->prepare(
                'UPDATE post_comments
                 SET report_count = report_count + 1,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'updated_at' => $now,
                'id' => $commentId,
            ]);

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'comment_id' => $commentId,
            'report_count' => ((int) ($comment['report_count'] ?? 0)) + 1,
        ];
    }

    public function sharePost(int $postId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $post = $this->requirePost($postId);
        $now = $this->now();

        $this->pdo->beginTransaction();
        $sharedPostId = 0;

        try {
            $this->incrementPostCounter($postId, 'share_count', 1);
            $insert = $this->pdo->prepare(
                'INSERT INTO posts
                    (author_user_id, author_key, author_name, author_avatar_asset, body_text, image_path, status, report_count, like_count, comment_count, share_count, shared_post_id, created_at, updated_at)
                 VALUES
                    (:author_user_id, :author_key, :author_name, :author_avatar_asset, :body_text, :image_path, :status, :report_count, :like_count, :comment_count, :share_count, :shared_post_id, :created_at, :updated_at)'
            );
            $insert->execute([
                'author_user_id' => (int) $user['id'],
                'author_key' => $this->authorKeyForUserId((int) $user['id']),
                'author_name' => $this->displayNameForUser($user),
                'author_avatar_asset' => $this->avatarForUser($user),
                'body_text' => (string) $post['body_text'],
                'image_path' => $post['image_path'] !== null ? (string) $post['image_path'] : null,
                'status' => 'active',
                'report_count' => 0,
                'like_count' => 0,
                'comment_count' => 0,
                'share_count' => 0,
                'shared_post_id' => $postId,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            $sharedPostId = (int) $this->pdo->lastInsertId();
            $this->createNotification(
                $post,
                $user,
                'share',
                sprintf('%s شارك منشورك', $this->displayNameForUser($user))
            );
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->feedPostById($sharedPostId, (int) $user['id']);
    }

    public function reportPost(
        int $postId,
        string $reason,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $post = $this->requirePost($postId);
        $reason = $this->resolveReportReasonLabel($reason);
        $userId = (int) $user['id'];

        $existing = $this->pdo->prepare(
            'SELECT id
             FROM post_reports
             WHERE post_id = :post_id
               AND reporter_user_id = :reporter_user_id
               AND status IN ("new", "reviewed")
             LIMIT 1'
        );
        $existing->execute([
            'post_id' => $postId,
            'reporter_user_id' => $userId,
        ]);

        if ($existing->fetch() !== false) {
            throw new ApiException('تم إرسال بلاغك بالفعل.', 422);
        }

        $now = $this->now();
        $this->pdo->beginTransaction();

        try {
            $insert = $this->pdo->prepare(
                'INSERT INTO post_reports
                    (post_id, reporter_user_id, reporter_name, reason, status, created_at, updated_at)
                 VALUES
                    (:post_id, :reporter_user_id, :reporter_name, :reason, :status, :created_at, :updated_at)'
            );
            $insert->execute([
                'post_id' => $postId,
                'reporter_user_id' => $userId,
                'reporter_name' => $this->displayNameForUser($user),
                'reason' => $reason,
                'status' => 'new',
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $this->incrementPostCounter($postId, 'report_count', 1);
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'post_id' => $postId,
            'report_count' => ((int) $post['report_count']) + 1,
        ];
    }

    public function listNotifications(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM post_notifications
             WHERE user_id = :user_id
             ORDER BY created_at DESC, id DESC
             LIMIT 30'
        );
        $statement->execute(['user_id' => $userId]);

        $notifications = [];
        foreach ($statement->fetchAll() as $notification) {
            $notifications[] = $this->mapNotification($notification);
        }

        return [
            'unread_count' => $this->countUnreadNotifications($userId),
            'notifications' => $notifications,
        ];
    }

    public function markNotificationsRead(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $statement = $this->pdo->prepare(
            'UPDATE post_notifications
             SET is_read = 1
             WHERE user_id = :user_id'
        );
        $statement->execute(['user_id' => (int) $user['id']]);

        return ['unread_count' => 0];
    }

    public function adminPostStats(): array
    {
        return [
            'posts' => (int) $this->pdo->query('SELECT COUNT(*) FROM posts')->fetchColumn(),
            'active_posts' => (int) $this->pdo->query('SELECT COUNT(*) FROM posts WHERE status = "active"')->fetchColumn(),
            'comments' => (int) $this->pdo->query('SELECT COUNT(*) FROM post_comments')->fetchColumn(),
            'reports' => (int) $this->pdo->query('SELECT COUNT(*) FROM post_reports')->fetchColumn()
                + (int) $this->pdo->query('SELECT COUNT(*) FROM post_comment_reports')->fetchColumn(),
            'open_reports' => (int) $this->pdo->query('SELECT COUNT(*) FROM post_reports WHERE status IN ("new", "reviewed")')->fetchColumn()
                + (int) $this->pdo->query('SELECT COUNT(*) FROM post_comment_reports WHERE status IN ("new", "reviewed")')->fetchColumn(),
        ];
    }

    public function adminListPosts(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT *
                FROM posts
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                author_name LIKE :search
                OR body_text LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $status = $this->normalizePostStatus($status);
            $sql .= ' AND status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY created_at DESC, id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminUpdatePost(
        int $postId,
        string $bodyText,
        ?string $imagePath,
        string $status
    ): void
    {
        if ($postId < 1) {
            throw new ApiException('Invalid post id.', 422);
        }

        $bodyText = trim($bodyText);
        $imagePath = $imagePath !== null ? trim($imagePath) : null;

        if ($bodyText === '' || mb_strlen($bodyText) > 1000) {
            throw new ApiException('Invalid post body.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE posts
             SET body_text = :body_text,
                 image_path = :image_path,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'body_text' => $bodyText,
            'image_path' => $imagePath !== '' ? $imagePath : null,
            'status' => $this->normalizePostStatus($status),
            'updated_at' => $this->now(),
            'id' => $postId,
        ]);
    }

    public function adminListReports(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT *
                FROM (
                    SELECT
                        post_reports.id,
                        \'post\' AS report_target,
                        post_reports.post_id,
                        NULL AS comment_id,
                        post_reports.reporter_user_id,
                        post_reports.reporter_name,
                        post_reports.reason,
                        post_reports.status,
                        post_reports.created_at,
                        post_reports.updated_at,
                        posts.author_name,
                        posts.body_text,
                        posts.status AS post_status,
                        NULL AS comment_body,
                        NULL AS comment_status
                    FROM post_reports
                    INNER JOIN posts ON posts.id = post_reports.post_id
                    UNION ALL
                    SELECT
                        post_comment_reports.id,
                        \'comment\' AS report_target,
                        post_comment_reports.post_id,
                        post_comment_reports.comment_id,
                        post_comment_reports.reporter_user_id,
                        post_comment_reports.reporter_name,
                        post_comment_reports.reason,
                        post_comment_reports.status,
                        post_comment_reports.created_at,
                        post_comment_reports.updated_at,
                        posts.author_name,
                        posts.body_text,
                        posts.status AS post_status,
                        post_comments.body_text AS comment_body,
                        post_comments.status AS comment_status
                    FROM post_comment_reports
                    INNER JOIN posts ON posts.id = post_comment_reports.post_id
                    INNER JOIN post_comments ON post_comments.id = post_comment_reports.comment_id
                ) report_items
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                reporter_name LIKE :search
                OR reason LIKE :search
                OR author_name LIKE :search
                OR body_text LIKE :search
                OR comment_body LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $status = $this->normalizeReportStatus($status);
            $sql .= ' AND status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY created_at DESC, id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminUpdateReportStatus(
        int $reportId,
        string $status,
        bool $hidePost,
        string $targetType = 'post'
    ): void {
        if ($reportId < 1) {
            throw new ApiException('Invalid report id.', 422);
        }

        $targetType = $targetType === 'comment' ? 'comment' : 'post';
        $table = $targetType === 'comment' ? 'post_comment_reports' : 'post_reports';

        $this->pdo->beginTransaction();

        try {
            $statement = $this->pdo->prepare(
                'UPDATE ' . $table . '
                 SET status = :status,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'status' => $this->normalizeReportStatus($status),
                'updated_at' => $this->now(),
                'id' => $reportId,
            ]);

            if ($hidePost && $targetType === 'post') {
                $postStatement = $this->pdo->prepare(
                    'UPDATE posts
                     SET status = "hidden",
                         updated_at = :updated_at
                     WHERE id = (
                        SELECT post_id
                        FROM ' . $table . '
                        WHERE id = :report_id
                     )'
                );
                $postStatement->execute([
                    'updated_at' => $this->now(),
                    'report_id' => $reportId,
                ]);
            } elseif ($hidePost) {
                $commentStatement = $this->pdo->prepare(
                    'UPDATE post_comments
                     SET status = "hidden",
                         updated_at = :updated_at
                     WHERE id = (
                        SELECT comment_id
                        FROM post_comment_reports
                        WHERE id = :report_id
                     )
                       AND status = "active"'
                );
                $commentStatement->execute([
                    'updated_at' => $this->now(),
                    'report_id' => $reportId,
                ]);

                $postStatement = $this->pdo->prepare(
                    'UPDATE posts
                     SET comment_count = (
                        SELECT COUNT(*)
                        FROM post_comments
                        WHERE post_comments.post_id = posts.id
                          AND post_comments.status = "active"
                     ),
                         updated_at = :updated_at
                     WHERE id = (
                        SELECT post_id
                        FROM post_comment_reports
                        WHERE id = :report_id
                     )'
                );
                $postStatement->execute([
                    'updated_at' => $this->now(),
                    'report_id' => $reportId,
                ]);
            }

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }
    }

    public function adminListReportReasons(): array
    {
        $statement = $this->pdo->query(
            'SELECT *
             FROM post_report_reasons
             ORDER BY display_order ASC, id ASC'
        );

        return $statement->fetchAll();
    }

    public function adminSaveReportReason(
        int $reasonId,
        string $label,
        string $description,
        int $displayOrder,
        string $status
    ): void {
        $label = trim($label);
        $description = trim($description);
        $status = in_array($status, ['active', 'hidden'], true) ? $status : 'active';

        if ($label === '' || mb_strlen($label) > 120) {
            throw new ApiException('Invalid report reason label.', 422);
        }

        if (mb_strlen($description) > 255) {
            throw new ApiException('Report reason description is too long.', 422);
        }

        $now = $this->now();
        $reasonKey = $this->uniqueReportReasonKey(
            $this->reportReasonKeyFromLabel($label),
            $reasonId
        );

        if ($reasonId > 0) {
            $statement = $this->pdo->prepare(
                'UPDATE post_report_reasons
                 SET reason_key = :reason_key,
                     label = :label,
                     description = :description,
                     display_order = :display_order,
                     status = :status,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'reason_key' => $reasonKey,
                'label' => $label,
                'description' => $description,
                'display_order' => max(0, $displayOrder),
                'status' => $status,
                'updated_at' => $now,
                'id' => $reasonId,
            ]);
            return;
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO post_report_reasons
                (reason_key, label, description, display_order, status, created_at, updated_at)
             VALUES
                (:reason_key, :label, :description, :display_order, :status, :created_at, :updated_at)'
        );
        $statement->execute([
            'reason_key' => $reasonKey,
            'label' => $label,
            'description' => $description,
            'display_order' => max(0, $displayOrder),
            'status' => $status,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    private function feedPostById(int $postId, int $viewerUserId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT posts.*,
                    shared_posts.author_name AS shared_author_name,
                    shared_posts.author_avatar_asset AS shared_author_avatar_asset,
                    shared_posts.body_text AS shared_body_text,
                    shared_posts.image_path AS shared_image_path,
                    post_followings.id AS following_id,
                    author_follow.id AS author_following_id,
                    post_likes.id AS like_id
             FROM posts
             LEFT JOIN posts shared_posts
                ON shared_posts.id = posts.shared_post_id
             LEFT JOIN post_followings
                ON post_followings.author_key = posts.author_key
               AND post_followings.user_id = :viewer_id
             LEFT JOIN user_follows author_follow
                ON author_follow.followed_user_id = posts.author_user_id
               AND author_follow.follower_user_id = :viewer_id
               AND author_follow.status = "active"
             LEFT JOIN post_likes
                ON post_likes.post_id = posts.id
               AND post_likes.user_id = :viewer_id
             WHERE posts.id = :post_id
             LIMIT 1'
        );
        $statement->execute([
            'viewer_id' => $viewerUserId,
            'post_id' => $postId,
        ]);
        $post = $statement->fetch();

        if ($post === false) {
            throw new ApiException('Post not found.', 404);
        }

        return $this->mapFeedPost($post, $viewerUserId);
    }

    private function mapFeedPost(array $post, int $viewerUserId): array
    {
        $authorUserId = isset($post['author_user_id']) && $post['author_user_id'] !== null
            ? (int) $post['author_user_id']
            : null;
        $canFollow = $authorUserId === null || $authorUserId !== $viewerUserId;
        $isOwner = $authorUserId !== null && $authorUserId === $viewerUserId;

        return [
            'id' => (int) $post['id'],
            'author_user_id' => $authorUserId,
            'author_key' => (string) $post['author_key'],
            'author_name' => (string) $post['author_name'],
            'author_avatar_asset' => (string) ($post['author_avatar_asset'] ?: 'assets/images/post_author_avatar.png'),
            'body_text' => (string) $post['body_text'],
            'image_path' => $post['image_path'] !== null ? (string) $post['image_path'] : null,
            'status' => (string) $post['status'],
            'is_followed' => $canFollow
                ? (($post['author_following_id'] ?? null) !== null || ($post['following_id'] ?? null) !== null)
                : false,
            'can_follow' => $canFollow,
            'is_liked' => $post['like_id'] !== null,
            'can_edit' => $isOwner,
            'can_delete' => $isOwner,
            'like_count' => (int) $post['like_count'],
            'comment_count' => (int) $post['comment_count'],
            'share_count' => (int) $post['share_count'],
            'is_shared' => isset($post['shared_post_id']) && $post['shared_post_id'] !== null,
            'shared_post_id' => isset($post['shared_post_id']) && $post['shared_post_id'] !== null
                ? (int) $post['shared_post_id']
                : null,
            'shared_author_name' => isset($post['shared_author_name']) && $post['shared_author_name'] !== null
                ? (string) $post['shared_author_name']
                : null,
            'shared_author_avatar_asset' => isset($post['shared_author_avatar_asset']) && $post['shared_author_avatar_asset'] !== null
                ? (string) $post['shared_author_avatar_asset']
                : null,
            'shared_body_text' => isset($post['shared_body_text']) && $post['shared_body_text'] !== null
                ? (string) $post['shared_body_text']
                : null,
            'shared_image_path' => isset($post['shared_image_path']) && $post['shared_image_path'] !== null
                ? (string) $post['shared_image_path']
                : null,
            'report_count' => (int) $post['report_count'],
            'date_label' => $this->formatDateLabel((string) $post['created_at']),
            'relative_time' => $this->formatRelativeTime((string) $post['created_at']),
        ];
    }

    private function mapReportReason(array $reason): array
    {
        return [
            'id' => (int) $reason['id'],
            'reason_key' => (string) $reason['reason_key'],
            'label' => (string) $reason['label'],
            'description' => (string) ($reason['description'] ?? ''),
        ];
    }

    private function mapComment(array $comment, int $viewerUserId): array
    {
        $authorUserId = isset($comment['user_id']) && $comment['user_id'] !== null
            ? (int) $comment['user_id']
            : null;
        $isOwner = $authorUserId !== null && $authorUserId === $viewerUserId;

        return [
            'id' => (int) $comment['id'],
            'author_name' => (string) $comment['author_name_snapshot'],
            'author_avatar_asset' => (string) (($comment['author_avatar_asset'] ?? '') ?: 'assets/images/post_author_avatar.png'),
            'body_text' => (string) $comment['body_text'],
            'created_at_label' => $this->formatRelativeTime((string) $comment['created_at']),
            'can_edit' => $isOwner,
            'can_delete' => $isOwner,
            'can_report' => !$isOwner,
        ];
    }

    private function mapNotification(array $notification): array
    {
        return [
            'id' => (int) $notification['id'],
            'message' => (string) $notification['message'],
            'notification_type' => (string) $notification['notification_type'],
            'is_read' => (int) $notification['is_read'] === 1,
            'created_at_label' => $this->formatRelativeTime((string) $notification['created_at']),
        ];
    }

    private function createNotification(
        array $post,
        array $actorUser,
        string $type,
        string $message
    ): void {
        if (!in_array($type, self::NOTIFICATION_TYPES, true)) {
            return;
        }

        $authorUserId = isset($post['author_user_id']) && $post['author_user_id'] !== null
            ? (int) $post['author_user_id']
            : 0;

        if ($authorUserId < 1 || $authorUserId === (int) $actorUser['id']) {
            return;
        }

        $insert = $this->pdo->prepare(
            'INSERT INTO post_notifications
                (user_id, post_id, actor_user_id, actor_name, notification_type, message, is_read, created_at)
             VALUES
                (:user_id, :post_id, :actor_user_id, :actor_name, :notification_type, :message, :is_read, :created_at)'
        );
        $insert->execute([
            'user_id' => $authorUserId,
            'post_id' => (int) $post['id'],
            'actor_user_id' => (int) $actorUser['id'],
            'actor_name' => $this->displayNameForUser($actorUser),
            'notification_type' => $type,
            'message' => $message,
            'is_read' => 0,
            'created_at' => $this->now(),
        ]);
    }

    private function countUnreadNotifications(int $userId): int
    {
        $statement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM post_notifications
             WHERE user_id = :user_id AND is_read = 0'
        );
        $statement->execute(['user_id' => $userId]);

        return (int) $statement->fetchColumn();
    }

    private function incrementPostCounter(int $postId, string $column, int $delta): void
    {
        if (!in_array($column, ['like_count', 'comment_count', 'share_count', 'report_count'], true)) {
            throw new ApiException('Invalid counter column.', 500);
        }

        $statement = $this->pdo->prepare(
            "UPDATE posts
             SET {$column} = CASE
                    WHEN ({$column} + :delta) < 0 THEN 0
                    ELSE {$column} + :delta
                 END,
                 updated_at = :updated_at
             WHERE id = :id"
        );
        $statement->execute([
            'delta' => $delta,
            'updated_at' => $this->now(),
            'id' => $postId,
        ]);
    }

    private function requireComment(int $postId, int $commentId): array
    {
        if ($postId < 1 || $commentId < 1) {
            throw new ApiException('Invalid comment id.', 422);
        }

        $this->requirePost($postId);

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM post_comments
             WHERE id = :id
               AND post_id = :post_id
               AND status = "active"
             LIMIT 1'
        );
        $statement->execute([
            'id' => $commentId,
            'post_id' => $postId,
        ]);
        $comment = $statement->fetch();

        if ($comment === false) {
            throw new ApiException('Comment not found.', 404);
        }

        return $comment;
    }

    private function requirePost(int $postId): array
    {
        if ($postId < 1) {
            throw new ApiException('Invalid post id.', 422);
        }

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM posts
             WHERE id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $postId]);
        $post = $statement->fetch();

        if ($post === false) {
            throw new ApiException('Post not found.', 404);
        }

        return $post;
    }

    private function assertOwnPost(array $post, int $userId): void
    {
        $authorUserId = isset($post['author_user_id']) && $post['author_user_id'] !== null
            ? (int) $post['author_user_id']
            : 0;

        if ($authorUserId !== $userId) {
            throw new ApiException('You can only edit your own posts.', 403);
        }
    }

    private function assertOwnComment(array $comment, int $userId): void
    {
        $authorUserId = isset($comment['user_id']) && $comment['user_id'] !== null
            ? (int) $comment['user_id']
            : 0;

        if ($authorUserId !== $userId) {
            throw new ApiException('You can only edit your own comments.', 403);
        }
    }

    private function resolveReportReasonLabel(string $reason): string
    {
        $reason = trim($reason);
        if ($reason !== '') {
            $statement = $this->pdo->prepare(
                'SELECT *
                 FROM post_report_reasons
                 WHERE status = "active"
                   AND reason_key = :reason
                 LIMIT 1'
            );
            $statement->execute(['reason' => $reason]);
            $row = $statement->fetch();
            if ($row !== false) {
                return (string) $row['label'];
            }

            if (ctype_digit($reason)) {
                $statement = $this->pdo->prepare(
                    'SELECT *
                     FROM post_report_reasons
                     WHERE status = "active"
                       AND id = :id
                     LIMIT 1'
                );
                $statement->execute(['id' => (int) $reason]);
                $row = $statement->fetch();
                if ($row !== false) {
                    return (string) $row['label'];
                }
            }
        }

        $fallback = $this->pdo->query(
            'SELECT label
             FROM post_report_reasons
             WHERE status = "active"
             ORDER BY display_order ASC, id ASC
             LIMIT 1'
        )->fetchColumn();

        if ($fallback !== false && trim((string) $fallback) !== '') {
            return (string) $fallback;
        }

        return $reason !== '' ? mb_substr($reason, 0, 190) : 'بلاغ عام';
    }

    private function reportReasonKeyFromLabel(string $label): string
    {
        $key = mb_strtolower($label);
        $key = preg_replace('/[^\p{L}\p{N}]+/u', '-', $key) ?? '';
        $key = trim($key, '-');

        return $key !== '' ? mb_substr($key, 0, 90) : 'reason';
    }

    private function uniqueReportReasonKey(string $baseKey, int $exceptReasonId = 0): string
    {
        $key = $baseKey;
        $index = 2;
        while (true) {
            $statement = $this->pdo->prepare(
                'SELECT id
                 FROM post_report_reasons
                 WHERE reason_key = :reason_key
                   AND id <> :except_id
                 LIMIT 1'
            );
            $statement->execute([
                'reason_key' => $key,
                'except_id' => max(0, $exceptReasonId),
            ]);
            if ($statement->fetch() === false) {
                return $key;
            }
            $key = mb_substr($baseKey, 0, 84) . '-' . $index;
            $index++;
        }
    }

    private function requireUser(?string $authorizationHeader): array
    {
        $user = $this->resolveUserFromAuthorization($authorizationHeader);
        if ($user === null) {
            throw new ApiException('Authentication required.', 401);
        }

        return $user;
    }

    private function resolveUserFromAuthorization(?string $authorizationHeader): ?array
    {
        if ($authorizationHeader === null || !preg_match('/Bearer\s+(.+)/i', $authorizationHeader, $matches)) {
            return null;
        }

        $token = trim((string) ($matches[1] ?? ''));
        if ($token === '') {
            return null;
        }

        $statement = $this->pdo->prepare(
            'SELECT users.*
             FROM auth_tokens
             INNER JOIN users ON users.id = auth_tokens.user_id
             WHERE auth_tokens.token_hash = :token_hash
             LIMIT 1'
        );
        $statement->execute([
            'token_hash' => hash('sha256', $token),
        ]);
        $user = $statement->fetch();

        return $user === false ? null : $user;
    }

    private function ensureDefaultFollowings(int $userId): void
    {
        $statement = $this->pdo->prepare('SELECT COUNT(*) FROM post_followings WHERE user_id = :user_id');
        $statement->execute(['user_id' => $userId]);
        if ((int) $statement->fetchColumn() > 0) {
            return;
        }

        $defaults = [
            'seed:asmaa' => 'اسماء فتحي',
            'seed:nour' => 'نور سالم',
        ];

        $insert = $this->pdo->prepare(
            'INSERT INTO post_followings
                (user_id, author_key, author_name_snapshot, created_at)
             VALUES
                (:user_id, :author_key, :author_name_snapshot, :created_at)'
        );
        foreach ($defaults as $authorKey => $authorName) {
            $insert->execute([
                'user_id' => $userId,
                'author_key' => $authorKey,
                'author_name_snapshot' => $authorName,
                'created_at' => $this->now(),
            ]);
        }
    }

    private function displayNameForUser(array $user): string
    {
        $nickname = trim((string) ($user['nickname'] ?? ''));
        if ($nickname !== '') {
            return $nickname;
        }

        $email = trim((string) ($user['email'] ?? ''));
        if ($email !== '') {
            return $email;
        }

        $phone = trim((string) ($user['phone'] ?? ''));
        if ($phone !== '') {
            return $phone;
        }

        return 'Hallo Party User';
    }

    private function avatarForUser(array $user): string
    {
        $avatar = trim((string) ($user['avatar_asset'] ?? ''));
        return $avatar !== '' ? $avatar : 'assets/images/post_author_avatar.png';
    }

    private function authorKeyForUserId(int $userId): string
    {
        return 'user:' . $userId;
    }

    private function storeImageDraft(array $draft): string
    {
        $fileName = trim((string) ($draft['filename'] ?? 'post-image'));
        $mimeType = trim((string) ($draft['mime_type'] ?? 'image/jpeg'));
        $content = trim((string) ($draft['content_base64'] ?? ''));

        if ($content === '') {
            throw new ApiException('Invalid post image.', 422);
        }

        $decoded = base64_decode($content, true);
        if ($decoded === false) {
            throw new ApiException('Invalid post image payload.', 422);
        }

        if (strlen($decoded) > 5 * 1024 * 1024) {
            throw new ApiException('Post image is too large.', 422);
        }

        $extension = match ($mimeType) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $directory = dirname(__DIR__) . '/storage/posts';
        if (!is_dir($directory) && !mkdir($directory, 0777, true) && !is_dir($directory)) {
            throw new ApiException('Failed to create post storage directory.', 500);
        }

        $safeName = preg_replace('/[^a-zA-Z0-9_\-]/', '-', pathinfo($fileName, PATHINFO_FILENAME)) ?: 'post';
        $relativePath = '/storage/posts/' . $safeName . '-' . bin2hex(random_bytes(6)) . '.' . $extension;
        $absolutePath = dirname(__DIR__) . $relativePath;

        if (file_put_contents($absolutePath, $decoded) === false) {
            throw new ApiException('Failed to store post image.', 500);
        }

        return $relativePath;
    }

    private function normalizePostStatus(string $status): string
    {
        if (!in_array($status, self::POST_STATUS_OPTIONS, true)) {
            throw new ApiException('Invalid post status.', 422);
        }

        return $status;
    }

    private function normalizeReportStatus(string $status): string
    {
        if (!in_array($status, self::REPORT_STATUS_OPTIONS, true)) {
            throw new ApiException('Invalid report status.', 422);
        }

        return $status;
    }

    private function formatDateLabel(string $timestamp): string
    {
        try {
            return (new DateTimeImmutable($timestamp))->format('m/d/Y');
        } catch (Throwable) {
            return date('m/d/Y');
        }
    }

    private function formatRelativeTime(string $timestamp): string
    {
        try {
            $createdAt = new DateTimeImmutable($timestamp);
        } catch (Throwable) {
            return 'just now';
        }

        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
        $seconds = max(0, $now->getTimestamp() - $createdAt->getTimestamp());

        if ($seconds < 60) {
            return 'just now';
        }

        $minutes = (int) floor($seconds / 60);
        if ($minutes < 60) {
            return sprintf('%d min ago', $minutes);
        }

        $hours = (int) floor($minutes / 60);
        if ($hours < 24) {
            return sprintf('%d hours ago', $hours);
        }

        $days = (int) floor($hours / 24);
        return sprintf('%d days ago', $days);
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
