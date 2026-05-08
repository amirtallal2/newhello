<?php

declare(strict_types=1);

final class LevelService
{
    private const DEFAULT_HERO_ASSET = 'https://api.builder.io/api/v1/image/assets/TEMP/16e7e797fedfea9339e02eecd482319097e0fed3?width=300';
    private const DEFAULT_BADGE_ASSET = 'assets/images/profile_vip_icon.png';
    private const COIN_ASSET = 'assets/images/profile_store_coin_icon.png';

    public function __construct(private readonly PDO $pdo)
    {
        $this->ensureSchema();
        $this->seedDefaults();
    }

    public function vipSummary(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];
        $this->expireOldSubscriptions($userId);

        $subscription = $this->activeSubscriptionForUser($userId);
        $levels = $this->activeLevelsWithPrivileges();
        $wallet = $this->walletRowForUser($userId);

        return [
            'wallet' => $this->mapWallet($wallet),
            'current_subscription' => $subscription === null ? null : $this->mapSubscription($subscription),
            'levels' => $levels,
            'coin_asset' => self::COIN_ASSET,
        ];
    }

    public function activateVip(int $levelId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $level = $this->requireActiveLevel($levelId);
        $userId = (int) $user['id'];
        $price = max(0, (int) $level['price_coins']);

        $this->pdo->beginTransaction();
        try {
            if ($price > 0) {
                $this->debitCoins($userId, $price);
                $this->insertWalletTransaction(
                    $userId,
                    $price,
                    'تفعيل VIP',
                    sprintf('تفعيل %s لمدة %d يوم', (string) $level['name'], (int) $level['duration_days']),
                    'vip_activate',
                    (string) $level['id']
                );
            }

            $this->activateSubscriptionForUser($userId, $level, 'self');
            $this->insertVipTransaction($userId, $userId, $level, 'activate', 'success');
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->vipSummary($authorizationHeader);
    }

    public function sendVip(
        int $levelId,
        ?int $recipientUserId,
        string $recipientName,
        ?string $authorizationHeader
    ): array {
        $sender = $this->requireUser($authorizationHeader);
        $level = $this->requireActiveLevel($levelId);
        $senderUserId = (int) $sender['id'];
        $recipientName = trim($recipientName);
        $recipient = null;

        if ($recipientUserId !== null && $recipientUserId > 0) {
            $recipient = $this->findUserById($recipientUserId);
            if ($recipient === null) {
                throw new ApiException('Recipient not found.', 404);
            }
            if ((int) $recipient['id'] === $senderUserId) {
                throw new ApiException('You already can activate VIP for yourself.', 422);
            }
            $recipientName = $this->displayNameForUser($recipient);
        }

        if ($recipientName === '') {
            throw new ApiException('Recipient name is required.', 422);
        }

        $price = max(0, (int) $level['price_coins']);

        $this->pdo->beginTransaction();
        try {
            if ($price > 0) {
                $this->debitCoins($senderUserId, $price);
                $this->insertWalletTransaction(
                    $senderUserId,
                    $price,
                    'إرسال VIP',
                    sprintf('إرسال %s إلى %s', (string) $level['name'], $recipientName),
                    'vip_send',
                    (string) $level['id']
                );
            }

            if ($recipient !== null) {
                $this->activateSubscriptionForUser((int) $recipient['id'], $level, 'gift');
            }

            $this->insertVipTransaction(
                $senderUserId,
                $recipient === null ? null : (int) $recipient['id'],
                $level,
                'send',
                'success',
                $recipientName
            );
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->vipSummary($authorizationHeader);
    }

    public function recipients(string $query, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];
        $query = trim($query);

        $sql = 'SELECT users.id, users.nickname, users.profile_handle, users.avatar_asset
                FROM users
                WHERE users.id != :user_id
                  AND users.status = :status';
        $params = [
            'user_id' => $userId,
            'status' => 'active',
        ];

        if ($query !== '') {
            $sql .= ' AND (
                LOWER(COALESCE(users.nickname, "")) LIKE :query
                OR LOWER(COALESCE(users.profile_handle, "")) LIKE :query
                OR CAST(users.id AS CHAR) LIKE :query
            )';
            $params['query'] = '%' . mb_strtolower($query) . '%';
        }

        $sql .= ' ORDER BY users.updated_at DESC, users.id DESC LIMIT 20';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $recipients = [];
        foreach ($statement->fetchAll() as $row) {
            $recipients[] = [
                'id' => (int) $row['id'],
                'name' => $this->displayNameForUser($row),
                'handle' => (string) (($row['profile_handle'] ?? '') ?: 'ID:' . $row['id']),
                'avatar_asset' => (string) (($row['avatar_asset'] ?? '') ?: 'assets/images/profile_avatar.png'),
            ];
        }

        return ['recipients' => $recipients];
    }

    public function adminListVipLevels(): array
    {
        $statement = $this->pdo->query(
            'SELECT *
             FROM vip_levels
             ORDER BY tier_number ASC, display_order ASC, id ASC'
        );

        return $statement->fetchAll();
    }

    public function adminSaveVipLevel(
        int $levelId,
        int $tierNumber,
        string $name,
        string $subtitle,
        string $description,
        int $priceCoins,
        int $durationDays,
        string $heroAssetPath,
        string $badgeAssetPath,
        string $status,
        int $displayOrder
    ): void {
        $tierNumber = max(1, min(99, $tierNumber));
        $status = in_array($status, ['active', 'hidden'], true) ? $status : 'active';
        $name = trim($name) === '' ? 'VIP ' . $tierNumber : trim($name);
        $subtitle = trim($subtitle);
        $description = trim($description);
        $heroAssetPath = trim($heroAssetPath) === '' ? self::DEFAULT_HERO_ASSET : trim($heroAssetPath);
        $badgeAssetPath = trim($badgeAssetPath) === '' ? self::DEFAULT_BADGE_ASSET : trim($badgeAssetPath);
        $now = $this->now();

        if ($levelId > 0) {
            $statement = $this->pdo->prepare(
                'UPDATE vip_levels
                 SET tier_number = :tier_number,
                     name = :name,
                     subtitle = :subtitle,
                     description = :description,
                     price_coins = :price_coins,
                     duration_days = :duration_days,
                     hero_asset_path = :hero_asset_path,
                     badge_asset_path = :badge_asset_path,
                     status = :status,
                     display_order = :display_order,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'tier_number' => $tierNumber,
                'name' => $name,
                'subtitle' => $subtitle,
                'description' => $description,
                'price_coins' => max(0, $priceCoins),
                'duration_days' => max(1, $durationDays),
                'hero_asset_path' => $heroAssetPath,
                'badge_asset_path' => $badgeAssetPath,
                'status' => $status,
                'display_order' => max(0, $displayOrder),
                'updated_at' => $now,
                'id' => $levelId,
            ]);
            return;
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO vip_levels
                (tier_number, name, subtitle, description, price_coins, duration_days, hero_asset_path, badge_asset_path, status, display_order, created_at, updated_at)
             VALUES
                (:tier_number, :name, :subtitle, :description, :price_coins, :duration_days, :hero_asset_path, :badge_asset_path, :status, :display_order, :created_at, :updated_at)'
        );
        $statement->execute([
            'tier_number' => $tierNumber,
            'name' => $name,
            'subtitle' => $subtitle,
            'description' => $description,
            'price_coins' => max(0, $priceCoins),
            'duration_days' => max(1, $durationDays),
            'hero_asset_path' => $heroAssetPath,
            'badge_asset_path' => $badgeAssetPath,
            'status' => $status,
            'display_order' => max(0, $displayOrder),
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    public function adminListPrivileges(): array
    {
        $statement = $this->pdo->query(
            'SELECT *
             FROM vip_privileges
             ORDER BY unlock_tier ASC, display_order ASC, id ASC'
        );

        return $statement->fetchAll();
    }

    public function adminSavePrivilege(
        int $privilegeId,
        int $unlockTier,
        string $title,
        string $description,
        string $iconAssetPath,
        string $status,
        int $displayOrder
    ): void {
        $unlockTier = max(1, min(99, $unlockTier));
        $title = trim($title) === '' ? 'ميزة VIP' : trim($title);
        $description = trim($description);
        $iconAssetPath = trim($iconAssetPath) === '' ? self::DEFAULT_BADGE_ASSET : trim($iconAssetPath);
        $status = in_array($status, ['active', 'hidden'], true) ? $status : 'active';
        $now = $this->now();

        if ($privilegeId > 0) {
            $statement = $this->pdo->prepare(
                'UPDATE vip_privileges
                 SET unlock_tier = :unlock_tier,
                     title = :title,
                     description = :description,
                     icon_asset_path = :icon_asset_path,
                     status = :status,
                     display_order = :display_order,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'unlock_tier' => $unlockTier,
                'title' => $title,
                'description' => $description,
                'icon_asset_path' => $iconAssetPath,
                'status' => $status,
                'display_order' => max(0, $displayOrder),
                'updated_at' => $now,
                'id' => $privilegeId,
            ]);
            return;
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO vip_privileges
                (unlock_tier, title, description, icon_asset_path, status, display_order, created_at, updated_at)
             VALUES
                (:unlock_tier, :title, :description, :icon_asset_path, :status, :display_order, :created_at, :updated_at)'
        );
        $statement->execute([
            'unlock_tier' => $unlockTier,
            'title' => $title,
            'description' => $description,
            'icon_asset_path' => $iconAssetPath,
            'status' => $status,
            'display_order' => max(0, $displayOrder),
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    public function adminSubscriptionsForUser(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT s.*, l.tier_number
             FROM user_vip_subscriptions s
             LEFT JOIN vip_levels l ON l.id = s.level_id
             WHERE s.user_id = :user_id
             ORDER BY s.id DESC
             LIMIT 8'
        );
        $statement->execute(['user_id' => $userId]);

        return $statement->fetchAll();
    }

    private function activeLevelsWithPrivileges(): array
    {
        $privileges = $this->activePrivileges();
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM vip_levels
             WHERE status = :status
             ORDER BY tier_number ASC, display_order ASC, id ASC'
        );
        $statement->execute(['status' => 'active']);

        $levels = [];
        foreach ($statement->fetchAll() as $level) {
            $tierNumber = (int) $level['tier_number'];
            $levels[] = $this->mapLevel($level, $privileges, $tierNumber);
        }

        return $levels;
    }

    private function activePrivileges(): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM vip_privileges
             WHERE status = :status
             ORDER BY unlock_tier ASC, display_order ASC, id ASC'
        );
        $statement->execute(['status' => 'active']);

        return $statement->fetchAll();
    }

    private function mapLevel(array $level, array $privileges, int $tierNumber): array
    {
        $mappedPrivileges = [];
        foreach ($privileges as $privilege) {
            $mappedPrivileges[] = $this->mapPrivilege(
                $privilege,
                (int) $privilege['unlock_tier'] <= $tierNumber
            );
        }

        return [
            'id' => (int) $level['id'],
            'tier_number' => $tierNumber,
            'name' => (string) $level['name'],
            'subtitle' => (string) ($level['subtitle'] ?? ''),
            'description' => (string) ($level['description'] ?? ''),
            'price_coins' => (int) $level['price_coins'],
            'duration_days' => (int) $level['duration_days'],
            'hero_asset_path' => (string) (($level['hero_asset_path'] ?? '') ?: self::DEFAULT_HERO_ASSET),
            'badge_asset_path' => (string) (($level['badge_asset_path'] ?? '') ?: self::DEFAULT_BADGE_ASSET),
            'status' => (string) $level['status'],
            'display_order' => (int) $level['display_order'],
            'unlocked_privileges_count' => count(array_filter($mappedPrivileges, static fn (array $item): bool => (bool) $item['is_unlocked'])),
            'privileges_total_count' => count($mappedPrivileges),
            'privileges' => $mappedPrivileges,
        ];
    }

    private function mapPrivilege(array $privilege, bool $isUnlocked): array
    {
        return [
            'id' => (int) $privilege['id'],
            'unlock_tier' => (int) $privilege['unlock_tier'],
            'title' => (string) $privilege['title'],
            'description' => (string) ($privilege['description'] ?? ''),
            'icon_asset_path' => (string) (($privilege['icon_asset_path'] ?? '') ?: self::DEFAULT_BADGE_ASSET),
            'is_unlocked' => $isUnlocked,
            'status' => (string) $privilege['status'],
            'display_order' => (int) $privilege['display_order'],
        ];
    }

    private function requireActiveLevel(int $levelId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM vip_levels WHERE id = :id AND status = :status LIMIT 1');
        $statement->execute([
            'id' => $levelId,
            'status' => 'active',
        ]);
        $level = $statement->fetch();

        if ($level === false) {
            throw new ApiException('VIP level not found.', 404);
        }

        return $level;
    }

    private function activeSubscriptionForUser(int $userId): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT s.*, l.tier_number, l.badge_asset_path
             FROM user_vip_subscriptions s
             LEFT JOIN vip_levels l ON l.id = s.level_id
             WHERE s.user_id = :user_id
               AND s.status = :status
               AND s.expires_at > :now
             ORDER BY COALESCE(l.tier_number, 0) DESC, s.expires_at DESC
             LIMIT 1'
        );
        $statement->execute([
            'user_id' => $userId,
            'status' => 'active',
            'now' => $this->now(),
        ]);
        $subscription = $statement->fetch();

        return $subscription === false ? null : $subscription;
    }

    private function mapSubscription(array $subscription): array
    {
        return [
            'id' => (int) $subscription['id'],
            'level_id' => (int) $subscription['level_id'],
            'tier_number' => (int) ($subscription['tier_number'] ?? 0),
            'tier_name' => (string) $subscription['tier_name'],
            'source' => (string) ($subscription['source'] ?? 'self'),
            'started_at' => (string) $subscription['started_at'],
            'expires_at' => (string) $subscription['expires_at'],
            'status' => (string) $subscription['status'],
            'badge_asset_path' => (string) (($subscription['badge_asset_path'] ?? '') ?: self::DEFAULT_BADGE_ASSET),
        ];
    }

    private function activateSubscriptionForUser(int $userId, array $level, string $source): void
    {
        $now = $this->now();
        $expiresAt = gmdate('Y-m-d H:i:s', time() + max(1, (int) $level['duration_days']) * 86400);

        $close = $this->pdo->prepare(
            'UPDATE user_vip_subscriptions
             SET status = :status,
                 updated_at = :updated_at
             WHERE user_id = :user_id
               AND status = :active_status'
        );
        $close->execute([
            'status' => 'replaced',
            'updated_at' => $now,
            'user_id' => $userId,
            'active_status' => 'active',
        ]);

        $insert = $this->pdo->prepare(
            'INSERT INTO user_vip_subscriptions
                (user_id, level_id, tier_name, source, started_at, expires_at, status, created_at, updated_at)
             VALUES
                (:user_id, :level_id, :tier_name, :source, :started_at, :expires_at, :status, :created_at, :updated_at)'
        );
        $insert->execute([
            'user_id' => $userId,
            'level_id' => (int) $level['id'],
            'tier_name' => (string) $level['name'],
            'source' => $source,
            'started_at' => $now,
            'expires_at' => $expiresAt,
            'status' => 'active',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $tierNumber = (int) $level['tier_number'];
        $updateUser = $this->pdo->prepare(
            'UPDATE users
             SET vip_tier = :vip_tier,
                 level_current = CASE WHEN COALESCE(level_current, 0) < :tier_number THEN :tier_number ELSE level_current END,
                 level_next = :level_next,
                 level_progress_percent = :progress,
                 badges_count = CASE WHEN COALESCE(badges_count, 0) < :badges_count THEN :badges_count ELSE badges_count END,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $updateUser->execute([
            'vip_tier' => (string) $level['name'],
            'tier_number' => $tierNumber,
            'level_next' => $tierNumber >= 6 ? $tierNumber : $tierNumber + 1,
            'progress' => min(100, max(10, $tierNumber * 16)),
            'badges_count' => $tierNumber + 3,
            'updated_at' => $now,
            'id' => $userId,
        ]);
    }

    private function expireOldSubscriptions(int $userId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE user_vip_subscriptions
             SET status = :expired,
                 updated_at = :updated_at
             WHERE user_id = :user_id
               AND status = :active
               AND expires_at <= :now'
        );
        $statement->execute([
            'expired' => 'expired',
            'updated_at' => $this->now(),
            'user_id' => $userId,
            'active' => 'active',
            'now' => $this->now(),
        ]);
    }

    private function walletRowForUser(int $userId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM user_wallets WHERE user_id = :user_id LIMIT 1');
        $statement->execute(['user_id' => $userId]);
        $wallet = $statement->fetch();

        if ($wallet !== false) {
            return $wallet;
        }

        $defaults = [
            'user_id' => $userId,
            'coins_balance' => 1235,
            'diamonds_balance' => 5,
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ];

        $insert = $this->pdo->prepare(
            'INSERT INTO user_wallets
                (user_id, coins_balance, diamonds_balance, created_at, updated_at)
             VALUES
                (:user_id, :coins_balance, :diamonds_balance, :created_at, :updated_at)'
        );
        $insert->execute($defaults);

        return $defaults;
    }

    private function mapWallet(array $wallet): array
    {
        return [
            'coins_balance' => (int) $wallet['coins_balance'],
            'diamonds_balance' => (int) $wallet['diamonds_balance'],
        ];
    }

    private function debitCoins(int $userId, int $amount): void
    {
        $wallet = $this->walletRowForUser($userId);
        if ((int) $wallet['coins_balance'] < $amount) {
            throw new ApiException('Insufficient coin balance.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE user_wallets
             SET coins_balance = coins_balance - :amount,
                 updated_at = :updated_at
             WHERE user_id = :user_id'
        );
        $statement->execute([
            'amount' => $amount,
            'updated_at' => $this->now(),
            'user_id' => $userId,
        ]);
    }

    private function insertWalletTransaction(
        int $userId,
        int $amount,
        string $title,
        string $subtitle,
        string $contextType,
        string $contextRef
    ): void {
        $statement = $this->pdo->prepare(
            'INSERT INTO wallet_transactions
                (user_id, wallet_type, direction, amount, status, title, subtitle, context_type, context_ref, created_at)
             VALUES
                (:user_id, :wallet_type, :direction, :amount, :status, :title, :subtitle, :context_type, :context_ref, :created_at)'
        );
        $statement->execute([
            'user_id' => $userId,
            'wallet_type' => 'coins',
            'direction' => 'debit',
            'amount' => $amount,
            'status' => 'success',
            'title' => $title,
            'subtitle' => $subtitle,
            'context_type' => $contextType,
            'context_ref' => $contextRef,
            'created_at' => $this->now(),
        ]);
    }

    private function insertVipTransaction(
        int $senderUserId,
        ?int $recipientUserId,
        array $level,
        string $actionType,
        string $status,
        ?string $recipientName = null
    ): void {
        $statement = $this->pdo->prepare(
            'INSERT INTO vip_transactions
                (sender_user_id, recipient_user_id, recipient_name_snapshot, level_id, tier_name, duration_days, price_coins, action_type, status, created_at)
             VALUES
                (:sender_user_id, :recipient_user_id, :recipient_name_snapshot, :level_id, :tier_name, :duration_days, :price_coins, :action_type, :status, :created_at)'
        );
        $statement->execute([
            'sender_user_id' => $senderUserId,
            'recipient_user_id' => $recipientUserId,
            'recipient_name_snapshot' => $recipientName,
            'level_id' => (int) $level['id'],
            'tier_name' => (string) $level['name'],
            'duration_days' => (int) $level['duration_days'],
            'price_coins' => (int) $level['price_coins'],
            'action_type' => $actionType,
            'status' => $status,
            'created_at' => $this->now(),
        ]);
    }

    private function findUserById(int $userId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM users WHERE id = :id AND status = :status LIMIT 1');
        $statement->execute([
            'id' => $userId,
            'status' => 'active',
        ]);
        $user = $statement->fetch();

        return $user === false ? null : $user;
    }

    private function displayNameForUser(array $user): string
    {
        return (string) (($user['nickname'] ?? '') ?: 'User #' . $user['id']);
    }

    private function requireUser(?string $authorizationHeader): array
    {
        if ($authorizationHeader === null || !str_starts_with($authorizationHeader, 'Bearer ')) {
            throw new ApiException('Unauthenticated.', 401);
        }

        $plainToken = trim(substr($authorizationHeader, 7));
        if ($plainToken === '') {
            throw new ApiException('Unauthenticated.', 401);
        }

        $statement = $this->pdo->prepare(
            'SELECT users.*
             FROM auth_tokens
             INNER JOIN users ON users.id = auth_tokens.user_id
             WHERE auth_tokens.token_hash = :token_hash
               AND (auth_tokens.expires_at IS NULL OR auth_tokens.expires_at > :now)
             LIMIT 1'
        );
        $statement->execute([
            'token_hash' => TokenManager::hash($plainToken),
            'now' => $this->now(),
        ]);
        $user = $statement->fetch();

        if ($user === false) {
            throw new ApiException('Unauthenticated.', 401);
        }

        if (($user['status'] ?? 'active') !== 'active') {
            throw new ApiException('This account is suspended.', 403);
        }

        return $user;
    }

    private function ensureSchema(): void
    {
        $driver = (string) $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
        $isMysql = $driver === 'mysql';

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS vip_levels (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            tier_number INT NOT NULL UNIQUE,
            name VARCHAR(80) NOT NULL,
            subtitle VARCHAR(160) NOT NULL DEFAULT "",
            description VARCHAR(255) NOT NULL DEFAULT "",
            price_coins INT NOT NULL DEFAULT 0,
            duration_days INT NOT NULL DEFAULT 30,
            hero_asset_path VARCHAR(500) NULL,
            badge_asset_path VARCHAR(500) NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS vip_levels (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tier_number INTEGER NOT NULL UNIQUE,
            name TEXT NOT NULL,
            subtitle TEXT NOT NULL DEFAULT "",
            description TEXT NOT NULL DEFAULT "",
            price_coins INTEGER NOT NULL DEFAULT 0,
            duration_days INTEGER NOT NULL DEFAULT 30,
            hero_asset_path TEXT NULL,
            badge_asset_path TEXT NULL,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )');

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS vip_privileges (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            unlock_tier INT NOT NULL DEFAULT 1,
            title VARCHAR(160) NOT NULL,
            description VARCHAR(255) NOT NULL DEFAULT "",
            icon_asset_path VARCHAR(500) NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            display_order INT NOT NULL DEFAULT 0,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS vip_privileges (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            unlock_tier INTEGER NOT NULL DEFAULT 1,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT "",
            icon_asset_path TEXT NULL,
            status TEXT NOT NULL DEFAULT "active",
            display_order INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )');

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS user_vip_subscriptions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            level_id INT UNSIGNED NOT NULL,
            tier_name VARCHAR(80) NOT NULL,
            source VARCHAR(20) NOT NULL DEFAULT "self",
            started_at DATETIME NOT NULL,
            expires_at DATETIME NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "active",
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS user_vip_subscriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            level_id INTEGER NOT NULL,
            tier_name TEXT NOT NULL,
            source TEXT NOT NULL DEFAULT "self",
            started_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "active",
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )');

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS vip_transactions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            sender_user_id INT UNSIGNED NOT NULL,
            recipient_user_id INT UNSIGNED NULL,
            recipient_name_snapshot VARCHAR(160) NULL,
            level_id INT UNSIGNED NOT NULL,
            tier_name VARCHAR(80) NOT NULL,
            duration_days INT NOT NULL DEFAULT 30,
            price_coins INT NOT NULL DEFAULT 0,
            action_type VARCHAR(20) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT "success",
            created_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS vip_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_user_id INTEGER NOT NULL,
            recipient_user_id INTEGER NULL,
            recipient_name_snapshot TEXT NULL,
            level_id INTEGER NOT NULL,
            tier_name TEXT NOT NULL,
            duration_days INTEGER NOT NULL DEFAULT 30,
            price_coins INTEGER NOT NULL DEFAULT 0,
            action_type TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "success",
            created_at TEXT NOT NULL
        )');
    }

    private function seedDefaults(): void
    {
        $levelsCount = (int) $this->pdo->query('SELECT COUNT(*) FROM vip_levels')->fetchColumn();
        if ($levelsCount === 0) {
            $this->seedLevels();
        }

        $privilegesCount = (int) $this->pdo->query('SELECT COUNT(*) FROM vip_privileges')->fetchColumn();
        if ($privilegesCount === 0) {
            $this->seedPrivileges();
        }
    }

    private function seedLevels(): void
    {
        $levels = [
            [1, 'VIP 1', 'بداية العضوية المميزة', 'مناسب لمن يريد تجربة مزايا VIP الأساسية.', 9999, 30],
            [2, 'VIP 2', 'حضور أوضح داخل الغرف', 'مزايا إضافية للظهور والتفاعل اليومي.', 29999, 30],
            [3, 'VIP 3', 'مزايا اجتماعية أقوى', 'مناسب للمستخدمين النشطين في الغرف والشات.', 79999, 30],
            [4, 'VIP 4', 'تميّز داخل اللايف والغرف', 'حزمة متقدمة للهدايا والحضور.', 149999, 30],
            [5, 'VIP 5', 'عضوية صفوة المستخدمين', 'أولوية ومؤثرات قوية للمستخدمين الكبار.', 299999, 30],
            [6, 'VIP 6', 'القمة الذهبية', 'كل مميزات VIP مفعلة بأعلى أولوية.', 499999, 30],
        ];

        $statement = $this->pdo->prepare(
            'INSERT INTO vip_levels
                (tier_number, name, subtitle, description, price_coins, duration_days, hero_asset_path, badge_asset_path, status, display_order, created_at, updated_at)
             VALUES
                (:tier_number, :name, :subtitle, :description, :price_coins, :duration_days, :hero_asset_path, :badge_asset_path, :status, :display_order, :created_at, :updated_at)'
        );
        foreach ($levels as $level) {
            $statement->execute([
                'tier_number' => $level[0],
                'name' => $level[1],
                'subtitle' => $level[2],
                'description' => $level[3],
                'price_coins' => $level[4],
                'duration_days' => $level[5],
                'hero_asset_path' => self::DEFAULT_HERO_ASSET,
                'badge_asset_path' => self::DEFAULT_BADGE_ASSET,
                'status' => 'active',
                'display_order' => $level[0],
                'created_at' => $this->now(),
                'updated_at' => $this->now(),
            ]);
        }
    }

    private function seedPrivileges(): void
    {
        $icons = [
            'https://api.builder.io/api/v1/image/assets/TEMP/4479a00c94fbcbc5459e692cd68cf3be49f19557?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/ab6ee03fe23e9a26074377ac29d11b337d1c5a4e?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/8cc2292cca020431f739ec53b3aae69ab23183df?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/8f0b5428cd9dbeb47635cdd816970cafb08e3e3c?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/e0805b8184fea842bc3e89684852e5113ad02fb8?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/d5036566eb072703135a740271420a463e0086d5?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/021ecacda046ede67be8614f748ca0b8ab3bdf67?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/601aa3756aa956b81013f1508d5001ed9c424be2?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/789b4f16fb9c5783f1f038027f935e4285cb6ed8?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/23a693f7edb5324102ea48e03e2be4b55f55a1de?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/04db7e88babe14f90f046e81246c857644a42750?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/c1295cd25caf0a9d6470ef5c4e558ba6eddf0eed?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/6116befbeb38f5b739e251fe2d2951645607e465?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/67801e8995df77c0e9d3db297f375b1278989c0e?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/2e4820df4a2cf7599461918923a97fcaa7f27c95?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/f1ae28e1ac8e13e216ea95911e43876b8ddfba84?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/6110afdd4f922276ee9495b058414c97f0f72343?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/fb6221d5fa0b7417c3cf838cf6daac6dce8eb659?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/c3065ddbd2882f32cfb2508d1f415e54aa39dd7e?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/5053ee0ae8ab22b3bf24654c9cace4b3c5ae0bb2?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/b99c625c1e88a5e3d8659d1681c49e686e746ede?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/4ed6dec57a2bb553008e2b3cfc4960e83e1c3c04?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/ec82910725651de24300202337049e97be05c23d?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/47a254f89cc145a5596b29d95b463a583b7438bc?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/7571f5b3fe466c49fdc6d1c77dfc4f8df32afeda?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/35781be011d20f3e0e59e60cab4c385ef644950d?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/1299f2854b7438bf18ad227dc86994def7283290?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/90c536c0252f26fee0afe28ef20c0be93cc6c754?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/855dc5ca804e5b1b4f6e657ba220b0f08ca87c43?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/986dd430aec1ea75afdf5debd89e9d19aacb7ff6?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/c46961505faabef343ddd786135d187ee4409494?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/22d67087f700077dbe03b1442221907ae9c0d5a9?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/8164ebb08d3ca4c2a1d1622a7ac74670889c737c?width=110',
            'https://api.builder.io/api/v1/image/assets/TEMP/5cb65747b297d85504048eec00071228e1bb0dfb?width=110',
        ];
        $titles = [
            [1, 'المزيد من اعضاء غرفة'],
            [1, 'وسام VIP'],
            [1, 'اطار فاخر'],
            [1, 'العرض في القمة'],
            [1, 'هدايا حصرية'],
            [1, 'خلفية الغرفة'],
            [1, 'الحصول يومي علي 100 الماسة مجانا'],
            [1, 'منع المتابعة'],
            [2, 'اخفاء حالة online'],
            [2, 'رسائل ملونة'],
            [2, 'اخبار بي الدخول'],
            [2, 'ترقية عالية السرعة'],
            [2, 'خصم من المتجر'],
            [3, 'اضاءة المايك'],
            [3, 'قبعات الدردشة الغرفة'],
            [3, 'غلاف الغرفة'],
            [3, 'مؤثرات الدخول'],
            [4, 'ايقونة الغرفة الارستقراطية'],
            [4, 'ارسال الصور في الشات'],
            [4, 'الحصول علي بنر حصري لك'],
            [4, 'الالولية في الابلاغ'],
            [4, 'اخطار بي الدخول'],
            [5, 'خدمة العملاء'],
            [5, 'غير قابل للحظر'],
            [5, 'اخفاء عند زيارة الغرفة'],
            [5, 'خاصية عدم التتبع'],
            [5, 'اعلان الغرف المجاني يوميا في الاوال'],
            [6, 'خصم عند التجديد'],
            [6, 'ضعف مكافاة المهام'],
            [6, 'ايدي غرفة مميز'],
            [6, 'تاثير مقعد vip'],
            [6, 'المزيد من عدد الاصدقاء والماتبعون'],
            [6, 'ايدي مميز'],
            [6, 'رموز تعبيرية حصرية'],
            [6, 'شارة ذهبية داخل الملف الشخصي'],
            [6, 'أولوية الظهور في توصيات الغرف'],
        ];

        $statement = $this->pdo->prepare(
            'INSERT INTO vip_privileges
                (unlock_tier, title, description, icon_asset_path, status, display_order, created_at, updated_at)
             VALUES
                (:unlock_tier, :title, :description, :icon_asset_path, :status, :display_order, :created_at, :updated_at)'
        );

        foreach ($titles as $index => $item) {
            $statement->execute([
                'unlock_tier' => $item[0],
                'title' => $item[1],
                'description' => 'ميزة يتم التحكم فيها من لوحة الأدمن وتظهر تلقائيا حسب مستوى VIP.',
                'icon_asset_path' => $icons[$index % count($icons)],
                'status' => 'active',
                'display_order' => $index + 1,
                'created_at' => $this->now(),
                'updated_at' => $this->now(),
            ]);
        }
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
