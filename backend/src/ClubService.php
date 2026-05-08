<?php

declare(strict_types=1);

final class ClubService
{
    private const DEFAULT_AVATAR = 'assets/images/home_club_icon.png';
    private const CREATION_COST_DIAMONDS = 500000;

    public function __construct(private readonly PDO $pdo)
    {
        $this->ensureSchema();
        $this->seedDefaultClubs();
    }

    public function listClubs(
        string $scope,
        string $query,
        ?string $authorizationHeader
    ): array {
        $scope = in_array($scope, ['trending', 'mine', 'newest'], true) ? $scope : 'trending';
        $query = trim($query);
        $viewer = $this->resolveUserFromAuthorization($authorizationHeader);
        $viewerId = $viewer === null ? null : (int) $viewer['id'];

        $sql = 'SELECT clubs.*,
                       users.nickname AS owner_nickname,
                       users.email AS owner_email,
                       users.avatar_asset AS owner_avatar_asset
                FROM clubs
                LEFT JOIN users ON users.id = clubs.owner_user_id
                WHERE clubs.status = "active"';
        $params = [];

        if ($query !== '') {
            $sql .= ' AND (clubs.name LIKE :query OR clubs.code LIKE :query OR clubs.announcement_text LIKE :query)';
            $params['query'] = '%' . $query . '%';
        }

        if ($scope === 'mine' && $viewerId !== null) {
            $sql .= ' AND EXISTS (
                SELECT 1
                FROM club_members
                WHERE club_members.club_id = clubs.id
                  AND club_members.user_id = :viewer_id
                  AND club_members.status = "active"
            )';
            $params['viewer_id'] = $viewerId;
        } elseif ($scope === 'mine') {
            return [
                'scope' => $scope,
                'query' => $query,
                'clubs' => [],
            ];
        }

        $sql .= $scope === 'newest'
            ? ' ORDER BY clubs.created_at DESC, clubs.id DESC'
            : ' ORDER BY clubs.ranking_points DESC, clubs.members_count DESC, clubs.created_at DESC';

        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $clubs = [];
        foreach ($statement->fetchAll() as $club) {
            $clubs[] = $this->mapClub($club, $viewerId);
        }

        return [
            'scope' => $scope,
            'query' => $query,
            'clubs' => $clubs,
        ];
    }

    public function detail(int $clubId, ?string $authorizationHeader): array
    {
        $viewer = $this->resolveUserFromAuthorization($authorizationHeader);
        $viewerId = $viewer === null ? null : (int) $viewer['id'];
        $club = $this->requireClub($clubId);

        return [
            'club' => $this->mapClub($club, $viewerId),
            'members' => $this->members($clubId),
            'feed' => $this->feed($clubId),
        ];
    }

    public function createClub(
        string $name,
        string $code,
        string $announcementText,
        ?string $avatarAsset,
        ?array $avatarUpload,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $name = trim($name);
        $code = trim($code);
        $announcementText = trim($announcementText);

        if ($name === '') {
            throw new ApiException('Club name is required.', 422);
        }

        if ($code === '') {
            throw new ApiException('Club code is required.', 422);
        }

        if (mb_strlen($name) > 20) {
            throw new ApiException('Club name must be 20 characters or less.', 422);
        }

        if (mb_strlen($code) > 20) {
            throw new ApiException('Club code must be 20 characters or less.', 422);
        }

        if (mb_strlen($announcementText) > 500) {
            throw new ApiException('Club announcement must be 500 characters or less.', 422);
        }

        if (!preg_match('/^[\p{Arabic}A-Za-z0-9_\-]+$/u', $code)) {
            throw new ApiException('Club code contains invalid characters.', 422);
        }

        $normalizedCode = mb_strtoupper($code, 'UTF-8');
        if ($this->findClubByCode($normalizedCode) !== null) {
            throw new ApiException('Club code already exists.', 422);
        }

        $avatarPath = $avatarUpload !== null
            ? $this->storeClubImageDraft($avatarUpload)
            : $this->sanitizeAvatarPath($avatarAsset);
        $now = $this->now();

        $this->pdo->beginTransaction();
        try {
            $statement = $this->pdo->prepare(
                'INSERT INTO clubs
                    (owner_user_id, name, code, announcement_text, avatar_asset, members_count, rooms_count, ranking_points, status, creation_cost_diamonds, created_at, updated_at)
                 VALUES
                    (:owner_user_id, :name, :code, :announcement_text, :avatar_asset, :members_count, :rooms_count, :ranking_points, :status, :creation_cost_diamonds, :created_at, :updated_at)'
            );
            $statement->execute([
                'owner_user_id' => (int) $user['id'],
                'name' => $name,
                'code' => $normalizedCode,
                'announcement_text' => $announcementText,
                'avatar_asset' => $avatarPath,
                'members_count' => 1,
                'rooms_count' => 0,
                'ranking_points' => 500,
                'status' => 'active',
                'creation_cost_diamonds' => self::CREATION_COST_DIAMONDS,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $clubId = (int) $this->pdo->lastInsertId();
            $this->insertMember($clubId, (int) $user['id'], 'owner', $now);

            $this->insertPost(
                $clubId,
                (int) $user['id'],
                $announcementText !== '' ? $announcementText : 'تم إنشاء النادي بنجاح.',
                $now
            );

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        $club = $this->requireClub((int) $clubId);

        return [
            'club' => $this->mapClub($club, (int) $user['id']),
            'creation_cost_diamonds' => self::CREATION_COST_DIAMONDS,
        ];
    }

    public function joinClub(int $clubId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $club = $this->requireClub($clubId);
        $userId = (int) $user['id'];

        if ($this->activeMembership($clubId, $userId) !== null) {
            return ['club' => $this->mapClub($club, $userId)];
        }

        $now = $this->now();
        $existing = $this->membershipRow($clubId, $userId);

        if ($existing === null) {
            $this->insertMember($clubId, $userId, 'member', $now);
        } else {
            $statement = $this->pdo->prepare(
                'UPDATE club_members
                 SET status = :status, role = :role, updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'status' => 'active',
                'role' => (string) ($existing['role'] ?? 'member') === 'owner' ? 'owner' : 'member',
                'updated_at' => $now,
                'id' => (int) $existing['id'],
            ]);
        }

        $this->syncClubCounters($clubId);
        $this->incrementClubPoints($clubId, 20);

        return ['club' => $this->mapClub($this->requireClub($clubId), $userId)];
    }

    public function leaveClub(int $clubId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $club = $this->requireClub($clubId);
        $userId = (int) $user['id'];
        $membership = $this->activeMembership($clubId, $userId);

        if ($membership === null) {
            return ['club' => $this->mapClub($club, $userId)];
        }

        if ((string) $membership['role'] === 'owner') {
            throw new ApiException('Club owner cannot leave before transferring ownership.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE club_members
             SET status = :status, updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => 'inactive',
            'updated_at' => $this->now(),
            'id' => (int) $membership['id'],
        ]);

        $this->syncClubCounters($clubId);

        return ['club' => $this->mapClub($this->requireClub($clubId), $userId)];
    }

    public function createPost(int $clubId, string $bodyText, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $bodyText = trim($bodyText);

        if ($bodyText === '') {
            throw new ApiException('Post text is required.', 422);
        }

        if (mb_strlen($bodyText) > 500) {
            throw new ApiException('Post text must be 500 characters or less.', 422);
        }

        $this->requireClub($clubId);
        if ($this->activeMembership($clubId, (int) $user['id']) === null) {
            throw new ApiException('Join the club before posting.', 403);
        }

        $this->insertPost($clubId, (int) $user['id'], $bodyText, $this->now());
        $this->incrementClubPoints($clubId, 5);

        return $this->detail($clubId, $authorizationHeader);
    }

    public function adminStats(): array
    {
        return [
            'clubs' => (int) $this->pdo->query('SELECT COUNT(*) FROM clubs')->fetchColumn(),
            'active_clubs' => (int) $this->pdo->query('SELECT COUNT(*) FROM clubs WHERE status = "active"')->fetchColumn(),
            'club_members' => (int) $this->pdo->query('SELECT COUNT(*) FROM club_members WHERE status = "active"')->fetchColumn(),
            'club_posts' => (int) $this->pdo->query('SELECT COUNT(*) FROM club_posts WHERE status = "active"')->fetchColumn(),
        ];
    }

    public function adminListClubs(string $search = ''): array
    {
        $sql = 'SELECT clubs.*,
                       users.nickname AS owner_nickname,
                       users.email AS owner_email,
                       (
                           SELECT COUNT(*)
                           FROM club_posts
                           WHERE club_posts.club_id = clubs.id
                             AND club_posts.status = "active"
                       ) AS posts_count
                FROM clubs
                LEFT JOIN users ON users.id = clubs.owner_user_id';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE clubs.name LIKE :search OR clubs.code LIKE :search OR users.nickname LIKE :search OR users.email LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY clubs.ranking_points DESC, clubs.created_at DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminUpdateClub(
        int $clubId,
        string $name,
        string $code,
        string $announcementText,
        string $avatarAsset,
        int $rankingPoints,
        string $status
    ): void {
        $name = trim($name);
        $code = mb_strtoupper(trim($code), 'UTF-8');
        $announcementText = trim($announcementText);

        if ($name === '' || $code === '') {
            throw new ApiException('Club name and code are required.', 422);
        }

        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid club status.', 422);
        }

        $existing = $this->findClubByCode($code);
        if ($existing !== null && (int) $existing['id'] !== $clubId) {
            throw new ApiException('Club code already exists.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE clubs
             SET name = :name,
                 code = :code,
                 announcement_text = :announcement_text,
                 avatar_asset = :avatar_asset,
                 ranking_points = :ranking_points,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'name' => $name,
            'code' => $code,
            'announcement_text' => $announcementText,
            'avatar_asset' => $this->sanitizeAvatarPath($avatarAsset),
            'ranking_points' => max(0, $rankingPoints),
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $clubId,
        ]);
    }

    private function members(int $clubId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT club_members.*,
                    users.nickname,
                    users.email,
                    users.avatar_asset
             FROM club_members
             LEFT JOIN users ON users.id = club_members.user_id
             WHERE club_members.club_id = :club_id
               AND club_members.status = "active"
             ORDER BY CASE club_members.role WHEN "owner" THEN 0 WHEN "admin" THEN 1 ELSE 2 END,
                      club_members.joined_at ASC,
                      club_members.id ASC'
        );
        $statement->execute(['club_id' => $clubId]);

        $members = [];
        foreach ($statement->fetchAll() as $member) {
            $members[] = [
                'id' => (int) $member['id'],
                'user_id' => $member['user_id'] === null ? null : (int) $member['user_id'],
                'nickname' => $this->displayName($member),
                'avatar_asset' => $this->displayAvatar($member),
                'role' => (string) $member['role'],
                'joined_at_label' => $this->dateLabel((string) $member['joined_at']),
            ];
        }

        return $members;
    }

    private function feed(int $clubId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT club_posts.*,
                    users.nickname,
                    users.email,
                    users.avatar_asset
             FROM club_posts
             LEFT JOIN users ON users.id = club_posts.author_user_id
             WHERE club_posts.club_id = :club_id
               AND club_posts.status = "active"
             ORDER BY club_posts.created_at DESC, club_posts.id DESC
             LIMIT 50'
        );
        $statement->execute(['club_id' => $clubId]);

        $feed = [];
        foreach ($statement->fetchAll() as $post) {
            $feed[] = [
                'id' => (int) $post['id'],
                'author_user_id' => $post['author_user_id'] === null ? null : (int) $post['author_user_id'],
                'author_name' => $this->displayName($post),
                'author_avatar_asset' => $this->displayAvatar($post),
                'body_text' => (string) $post['body_text'],
                'created_at_label' => $this->dateLabel((string) $post['created_at']),
            ];
        }

        return $feed;
    }

    private function requireClub(int $clubId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT clubs.*,
                    users.nickname AS owner_nickname,
                    users.email AS owner_email,
                    users.avatar_asset AS owner_avatar_asset
             FROM clubs
             LEFT JOIN users ON users.id = clubs.owner_user_id
             WHERE clubs.id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $clubId]);
        $club = $statement->fetch();

        if ($club === false) {
            throw new ApiException('Club not found.', 404);
        }

        return $club;
    }

    private function findClubByCode(string $code): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM clubs WHERE code = :code LIMIT 1');
        $statement->execute(['code' => $code]);
        $club = $statement->fetch();

        return $club === false ? null : $club;
    }

    private function mapClub(array $club, ?int $viewerUserId): array
    {
        $membership = $viewerUserId === null ? null : $this->activeMembership((int) $club['id'], $viewerUserId);
        $ownerUserId = $club['owner_user_id'] === null ? null : (int) $club['owner_user_id'];
        $isOwner = $viewerUserId !== null && $ownerUserId === $viewerUserId;
        $role = $membership === null ? '' : (string) $membership['role'];

        return [
            'id' => (int) $club['id'],
            'name' => (string) $club['name'],
            'code' => (string) $club['code'],
            'announcement_text' => (string) ($club['announcement_text'] ?? ''),
            'owner_user_id' => $ownerUserId,
            'owner_name' => $this->ownerName($club),
            'avatar_asset' => (string) (($club['avatar_asset'] ?? '') ?: self::DEFAULT_AVATAR),
            'members_count' => (int) ($club['members_count'] ?? 0),
            'rooms_count' => (int) ($club['rooms_count'] ?? 0),
            'ranking_points' => (int) ($club['ranking_points'] ?? 0),
            'status' => (string) ($club['status'] ?? 'active'),
            'is_member' => $membership !== null,
            'is_owner' => $isOwner,
            'role' => $role,
            'creation_cost_diamonds' => (int) ($club['creation_cost_diamonds'] ?? self::CREATION_COST_DIAMONDS),
            'created_at_label' => $this->dateLabel((string) $club['created_at']),
        ];
    }

    private function activeMembership(int $clubId, int $userId): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM club_members
             WHERE club_id = :club_id
               AND user_id = :user_id
               AND status = "active"
             LIMIT 1'
        );
        $statement->execute([
            'club_id' => $clubId,
            'user_id' => $userId,
        ]);
        $membership = $statement->fetch();

        return $membership === false ? null : $membership;
    }

    private function membershipRow(int $clubId, int $userId): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM club_members
             WHERE club_id = :club_id
               AND user_id = :user_id
             LIMIT 1'
        );
        $statement->execute([
            'club_id' => $clubId,
            'user_id' => $userId,
        ]);
        $membership = $statement->fetch();

        return $membership === false ? null : $membership;
    }

    private function insertMember(int $clubId, int $userId, string $role, string $now): void
    {
        $statement = $this->pdo->prepare(
            'INSERT INTO club_members
                (club_id, user_id, role, status, joined_at, updated_at)
             VALUES
                (:club_id, :user_id, :role, :status, :joined_at, :updated_at)'
        );
        $statement->execute([
            'club_id' => $clubId,
            'user_id' => $userId,
            'role' => $role,
            'status' => 'active',
            'joined_at' => $now,
            'updated_at' => $now,
        ]);
    }

    private function insertPost(int $clubId, ?int $authorUserId, string $bodyText, string $now): void
    {
        $statement = $this->pdo->prepare(
            'INSERT INTO club_posts
                (club_id, author_user_id, body_text, status, created_at, updated_at)
             VALUES
                (:club_id, :author_user_id, :body_text, :status, :created_at, :updated_at)'
        );
        $statement->execute([
            'club_id' => $clubId,
            'author_user_id' => $authorUserId,
            'body_text' => $bodyText,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    private function syncClubCounters(int $clubId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE clubs
             SET members_count = (
                     SELECT COUNT(*)
                     FROM club_members
                     WHERE club_id = :club_id_for_count
                       AND status = "active"
                 ),
                 updated_at = :updated_at
             WHERE id = :club_id'
        );
        $statement->execute([
            'club_id_for_count' => $clubId,
            'updated_at' => $this->now(),
            'club_id' => $clubId,
        ]);
    }

    private function incrementClubPoints(int $clubId, int $points): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE clubs
             SET ranking_points = ranking_points + :points,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'points' => $points,
            'updated_at' => $this->now(),
            'id' => $clubId,
        ]);
    }

    private function insertWalletTransactionIfTableExists(
        int $userId,
        int $amount,
        string $title,
        string $subtitle
    ): void {
        if (!$this->tableExists('wallet_transactions')) {
            return;
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO wallet_transactions
                (user_id, wallet_type, direction, amount, status, title, subtitle, context_ref, created_at)
             VALUES
                (:user_id, :wallet_type, :direction, :amount, :status, :title, :subtitle, :context_ref, :created_at)'
        );
        $statement->execute([
            'user_id' => $userId,
            'wallet_type' => 'diamonds',
            'direction' => 'debit',
            'amount' => $amount,
            'status' => 'success',
            'title' => $title,
            'subtitle' => $subtitle,
            'context_ref' => 'club_create',
            'created_at' => $this->now(),
        ]);
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

        $hashedToken = hash('sha256', $token);
        $statement = $this->pdo->prepare(
            'SELECT users.*
             FROM auth_tokens
             INNER JOIN users ON users.id = auth_tokens.user_id
             WHERE auth_tokens.token_hash = :token_hash
             LIMIT 1'
        );
        $statement->execute(['token_hash' => $hashedToken]);
        $user = $statement->fetch();

        return $user === false ? null : $user;
    }

    private function requireUser(?string $authorizationHeader): array
    {
        $user = $this->resolveUserFromAuthorization($authorizationHeader);
        if ($user === null) {
            throw new ApiException('Authentication required.', 401);
        }

        return $user;
    }

    private function ownerName(array $club): string
    {
        $nickname = trim((string) ($club['owner_nickname'] ?? ''));
        if ($nickname !== '') {
            return $nickname;
        }

        $email = trim((string) ($club['owner_email'] ?? ''));
        if ($email !== '') {
            return $email;
        }

        return 'Hallo Party';
    }

    private function displayName(array $row): string
    {
        $nickname = trim((string) ($row['nickname'] ?? ''));
        if ($nickname !== '') {
            return $nickname;
        }

        $email = trim((string) ($row['email'] ?? ''));
        if ($email !== '') {
            return $email;
        }

        return 'Hallo Party User';
    }

    private function displayAvatar(array $row): string
    {
        $avatar = trim((string) ($row['avatar_asset'] ?? ''));
        return $avatar !== '' ? $avatar : 'assets/images/profile_avatar.png';
    }

    private function sanitizeAvatarPath(?string $path): string
    {
        $path = trim((string) $path);
        if ($path === '') {
            return self::DEFAULT_AVATAR;
        }

        if (str_starts_with($path, 'assets/') || str_starts_with($path, '/storage/clubs/')) {
            return $path;
        }

        return self::DEFAULT_AVATAR;
    }

    private function storeClubImageDraft(array $draft): string
    {
        $fileName = trim((string) ($draft['filename'] ?? 'club-image'));
        $mimeType = trim((string) ($draft['mime_type'] ?? 'image/jpeg'));
        $content = trim((string) ($draft['content_base64'] ?? ''));

        if ($content === '') {
            throw new ApiException('Invalid club image.', 422);
        }

        if (!in_array($mimeType, ['image/png', 'image/jpeg', 'image/jpg', 'image/webp'], true)) {
            throw new ApiException('Unsupported club image type.', 422);
        }

        $decoded = base64_decode($content, true);
        if ($decoded === false) {
            throw new ApiException('Invalid club image payload.', 422);
        }

        if (strlen($decoded) > 5 * 1024 * 1024) {
            throw new ApiException('Club image is too large.', 422);
        }

        $extension = match ($mimeType) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $directory = dirname(__DIR__) . '/storage/clubs';
        if (!is_dir($directory) && !mkdir($directory, 0777, true) && !is_dir($directory)) {
            throw new ApiException('Failed to create club image storage.', 500);
        }

        $safeName = preg_replace('/[^a-zA-Z0-9_\-]/', '-', pathinfo($fileName, PATHINFO_FILENAME)) ?: 'club';
        $relativePath = '/storage/clubs/' . $safeName . '-' . bin2hex(random_bytes(6)) . '.' . $extension;
        $absolutePath = dirname(__DIR__) . $relativePath;

        if (file_put_contents($absolutePath, $decoded) === false) {
            throw new ApiException('Failed to store club image.', 500);
        }

        return $relativePath;
    }

    private function dateLabel(string $datetime): string
    {
        $timestamp = strtotime($datetime);
        if ($timestamp === false) {
            return '';
        }

        $diff = time() - $timestamp;
        if ($diff < 60) {
            return 'الآن';
        }

        if ($diff < 3600) {
            return (string) max(1, (int) floor($diff / 60)) . ' د';
        }

        if ($diff < 86400) {
            return (string) max(1, (int) floor($diff / 3600)) . ' س';
        }

        if ($diff < 172800) {
            return 'أمس';
        }

        return gmdate('Y/m/d', $timestamp);
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }

    private function tableExists(string $table): bool
    {
        try {
            $statement = $this->pdo->prepare('SELECT 1 FROM ' . $table . ' LIMIT 1');
            $statement->execute();
            return true;
        } catch (Throwable) {
            return false;
        }
    }

    private function ensureSchema(): void
    {
        $driver = (string) $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
        $isMysql = $driver === 'mysql';

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS clubs (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            owner_user_id INT UNSIGNED NULL,
            name VARCHAR(120) NOT NULL,
            code VARCHAR(40) NOT NULL UNIQUE,
            announcement_text TEXT NULL,
            avatar_asset VARCHAR(255) NOT NULL,
            members_count INT NOT NULL DEFAULT 0,
            rooms_count INT NOT NULL DEFAULT 0,
            ranking_points INT NOT NULL DEFAULT 0,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            creation_cost_diamonds INT NOT NULL DEFAULT 500000,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            INDEX idx_clubs_owner (owner_user_id),
            INDEX idx_clubs_status_rank (status, ranking_points),
            CONSTRAINT fk_clubs_owner_user FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS clubs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            owner_user_id INTEGER NULL,
            name TEXT NOT NULL,
            code TEXT NOT NULL UNIQUE,
            announcement_text TEXT NULL,
            avatar_asset TEXT NOT NULL,
            members_count INTEGER NOT NULL DEFAULT 0,
            rooms_count INTEGER NOT NULL DEFAULT 0,
            ranking_points INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT "active",
            creation_cost_diamonds INTEGER NOT NULL DEFAULT 500000,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )');

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS club_members (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            club_id INT UNSIGNED NOT NULL,
            user_id INT UNSIGNED NULL,
            role VARCHAR(20) NOT NULL DEFAULT "member",
            status VARCHAR(20) NOT NULL DEFAULT "active",
            joined_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            UNIQUE KEY uq_club_members_user (club_id, user_id),
            INDEX idx_club_members_user (user_id),
            CONSTRAINT fk_club_members_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
            CONSTRAINT fk_club_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS club_members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            club_id INTEGER NOT NULL,
            user_id INTEGER NULL,
            role TEXT NOT NULL DEFAULT "member",
            status TEXT NOT NULL DEFAULT "active",
            joined_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )');

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS club_posts (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            club_id INT UNSIGNED NOT NULL,
            author_user_id INT UNSIGNED NULL,
            body_text TEXT NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            INDEX idx_club_posts_club (club_id, status, created_at),
            CONSTRAINT fk_club_posts_club FOREIGN KEY (club_id) REFERENCES clubs(id) ON DELETE CASCADE,
            CONSTRAINT fk_club_posts_author FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS club_posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            club_id INTEGER NOT NULL,
            author_user_id INTEGER NULL,
            body_text TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )');
    }

    private function seedDefaultClubs(): void
    {
        $count = (int) $this->pdo->query('SELECT COUNT(*) FROM clubs')->fetchColumn();
        if ($count > 0) {
            return;
        }

        $now = $this->now();
        $clubs = [
            ['نادي ملوك هالو', 'HALLO', 'مسابقات وغرف يومية لأعضاء النادي.', self::DEFAULT_AVATAR, 1280, 12, 89500],
            ['نادي الأصدقاء', 'FRIENDS', 'تعالوا نتجمع في غرف صوتية ولايفات يومية.', 'assets/images/profile_avatar.png', 640, 5, 43000],
            ['مزيكا لايف', 'MUSIC', 'غناء ومزيكا وتحديات PK طول الأسبوع.', 'assets/images/home_room_1.png', 420, 4, 28500],
        ];

        $statement = $this->pdo->prepare(
            'INSERT INTO clubs
                (owner_user_id, name, code, announcement_text, avatar_asset, members_count, rooms_count, ranking_points, status, creation_cost_diamonds, created_at, updated_at)
             VALUES
                (:owner_user_id, :name, :code, :announcement_text, :avatar_asset, :members_count, :rooms_count, :ranking_points, :status, :creation_cost_diamonds, :created_at, :updated_at)'
        );

        foreach ($clubs as $club) {
            $statement->execute([
                'owner_user_id' => null,
                'name' => $club[0],
                'code' => $club[1],
                'announcement_text' => $club[2],
                'avatar_asset' => $club[3],
                'members_count' => $club[4],
                'rooms_count' => $club[5],
                'ranking_points' => $club[6],
                'status' => 'active',
                'creation_cost_diamonds' => self::CREATION_COST_DIAMONDS,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
            $clubId = (int) $this->pdo->lastInsertId();
            $this->insertPost($clubId, null, (string) $club[2], $now);
        }
    }
}
