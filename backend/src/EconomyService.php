<?php

declare(strict_types=1);

require_once __DIR__ . '/ReferralService.php';

final class EconomyService
{
    private const WALLET_TYPES = ['coins', 'diamonds'];
    private const STORE_CATEGORIES = [
        'frames',
        'animated_frames',
        'backgrounds',
        'chat_frames',
        'entry_effects',
        'aristocracy',
    ];
    private const BAG_GROUPS = ['animated', 'art', 'entry_effects'];

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function walletSummary(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $wallet = $this->walletRowForUser((int) $user['id']);

        return [
            'wallet' => $this->mapWallet($wallet),
            'packages' => [
                'diamonds' => $this->listWalletPackages('diamonds'),
                'coins' => $this->listWalletPackages('coins'),
            ],
        ];
    }

    public function topUpWallet(int $packageId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $package = $this->findWalletPackageById($packageId);

        if ($package === null || (string) $package['status'] !== 'active') {
            throw new ApiException('Wallet package not found.', 404);
        }

        $userId = (int) $user['id'];
        $walletType = (string) $package['wallet_type'];
        $amount = (int) $package['amount'] + (int) $package['bonus_amount'];
        $referralService = new ReferralService($this->pdo);
        $packagePriceUsd = $this->parsePackagePriceUsd((string) $package['price_label']);

        $this->pdo->beginTransaction();

        try {
            $this->adjustWalletBalance($userId, $walletType, $amount);
            $this->insertWalletTransaction(
                $userId,
                $walletType,
                'credit',
                $amount,
                'success',
                'تم الشحن بنجاح',
                sprintf('شحن %d %s الآن', $amount, $walletType === 'coins' ? 'عملة' : 'ماسة'),
                'wallet_topup',
                (string) $packageId
            );
            $referralService->recordRechargeReward($userId, $packagePriceUsd);
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->walletSummary($authorizationHeader);
    }

    private function parsePackagePriceUsd(string $priceLabel): float
    {
        $normalized = preg_replace('/[^0-9.]/', '', $priceLabel) ?? '';
        if ($normalized === '') {
            return 0.0;
        }

        return max(0.0, (float) $normalized);
    }

    public function walletRecords(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];

        return [
            'wallet' => $this->mapWallet($this->walletRowForUser($userId)),
            'records' => $this->listWalletTransactions($userId, null),
        ];
    }

    public function history(string $walletType, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $walletType = trim($walletType);
        if (!in_array($walletType, self::WALLET_TYPES, true)) {
            throw new ApiException('Invalid history wallet type.', 422);
        }

        return [
            'wallet_type' => $walletType,
            'wallet' => $this->mapWallet($this->walletRowForUser((int) $user['id'])),
            'entries' => $this->listWalletTransactions((int) $user['id'], $walletType),
        ];
    }

    public function storeCatalog(string $categoryKey, ?string $authorizationHeader): array
    {
        $this->requireUser($authorizationHeader);
        $categoryKey = trim($categoryKey);

        if (!in_array($categoryKey, self::STORE_CATEGORIES, true)) {
            throw new ApiException('Invalid store category.', 422);
        }

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM store_items
             WHERE category_key = :category_key
               AND status = :status
             ORDER BY display_order ASC, id ASC'
        );
        $statement->execute([
            'category_key' => $categoryKey,
            'status' => 'active',
        ]);

        $items = [];
        foreach ($statement->fetchAll() as $item) {
            $items[] = $this->mapStoreItem($item);
        }

        return [
            'category_key' => $categoryKey,
            'items' => $items,
        ];
    }

    public function purchaseStoreItem(
        int $itemId,
        int $durationDays,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $item = $this->requireStoreItem($itemId);
        $priceAmount = $this->resolveItemPrice($item, $durationDays);
        $userId = (int) $user['id'];

        $this->pdo->beginTransaction();

        try {
            $this->debitWallet($userId, (string) $item['currency_type'], $priceAmount);
            $inventoryId = $this->insertInventoryRecord(
                $userId,
                $item,
                $durationDays,
                'purchase',
                null,
                $this->displayNameForUser($user)
            );
            $this->insertWalletTransaction(
                $userId,
                (string) $item['currency_type'],
                'debit',
                $priceAmount,
                'success',
                'تم شراء العنصر',
                sprintf('شراء %s لمدة %d أيام', (string) $item['name'], $durationDays),
                'store_purchase',
                (string) $inventoryId
            );
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'wallet' => $this->mapWallet($this->walletRowForUser($userId)),
            'inventory' => $this->mapInventoryItem($this->requireInventoryItem($inventoryId, $userId)),
        ];
    }

    public function sendStoreItem(
        int $itemId,
        int $durationDays,
        ?int $recipientUserId,
        string $recipientName,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $item = $this->requireStoreItem($itemId);
        $priceAmount = $this->resolveItemPrice($item, $durationDays);
        $senderUserId = (int) $user['id'];
        $senderName = $this->displayNameForUser($user);
        $recipientName = trim($recipientName);

        if ($recipientName === '') {
            throw new ApiException('Recipient name is required.', 422);
        }

        $recipientUser = null;
        if ($recipientUserId !== null) {
            $recipientUser = $this->findUserById($recipientUserId);
            if ($recipientUser === null) {
                throw new ApiException('Recipient not found.', 404);
            }

            $recipientName = $this->displayNameForUser($recipientUser);
        }

        $this->pdo->beginTransaction();

        try {
            $this->debitWallet($senderUserId, (string) $item['currency_type'], $priceAmount);

            $inventoryId = null;
            if ($recipientUser !== null) {
                $inventoryId = $this->insertInventoryRecord(
                    (int) $recipientUser['id'],
                    $item,
                    $durationDays,
                    'gift',
                    $senderName,
                    $recipientName
                );
            }

            $insert = $this->pdo->prepare(
                'INSERT INTO store_send_transactions
                    (sender_user_id, recipient_user_id, recipient_name_snapshot, item_id, item_name_snapshot, duration_days, price_amount, currency_type, created_at)
                 VALUES
                    (:sender_user_id, :recipient_user_id, :recipient_name_snapshot, :item_id, :item_name_snapshot, :duration_days, :price_amount, :currency_type, :created_at)'
            );
            $insert->execute([
                'sender_user_id' => $senderUserId,
                'recipient_user_id' => $recipientUser === null ? null : (int) $recipientUser['id'],
                'recipient_name_snapshot' => $recipientName,
                'item_id' => (int) $item['id'],
                'item_name_snapshot' => (string) $item['name'],
                'duration_days' => $durationDays,
                'price_amount' => $priceAmount,
                'currency_type' => (string) $item['currency_type'],
                'created_at' => $this->now(),
            ]);

            $this->insertWalletTransaction(
                $senderUserId,
                (string) $item['currency_type'],
                'debit',
                $priceAmount,
                'success',
                'تم الإرسال بنجاح',
                sprintf('إرسال %s إلى %s', (string) $item['name'], $recipientName),
                'store_send',
                (string) ($inventoryId ?? $this->pdo->lastInsertId())
            );

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'wallet' => $this->mapWallet($this->walletRowForUser($senderUserId)),
            'recipient_name' => $recipientName,
        ];
    }

    public function sendRecipients(string $query, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $query = trim($query);
        $userId = (int) $user['id'];

        $sql = 'SELECT users.id, users.nickname, users.avatar_asset
                FROM user_follows outgoing
                INNER JOIN user_follows incoming
                    ON incoming.follower_user_id = outgoing.followed_user_id
                   AND incoming.followed_user_id = outgoing.follower_user_id
                   AND incoming.status = "active"
                INNER JOIN users ON users.id = outgoing.followed_user_id
                WHERE outgoing.follower_user_id = :user_id
                  AND outgoing.status = "active"
                  AND users.status = :status';
        $params = [
            'user_id' => $userId,
            'status' => 'active',
        ];

        if ($query !== '') {
            $sql .= ' AND LOWER(COALESCE(users.nickname, "")) LIKE :query';
            $params['query'] = '%' . mb_strtolower($query) . '%';
        }

        $sql .= ' ORDER BY outgoing.created_at DESC, users.id ASC LIMIT 9';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $avatars = [
            ['avatar' => 'assets/images/profile_store_friend_yara.png', 'inner' => null],
            ['avatar' => 'assets/images/profile_store_friend_nona_frame.png', 'inner' => 'assets/images/profile_store_friend_nona_avatar.png'],
            ['avatar' => 'assets/images/profile_store_friend_yara_alt.png', 'inner' => null],
        ];

        $recipients = [];
        foreach (array_values($statement->fetchAll()) as $index => $row) {
            $avatar = $avatars[$index % count($avatars)];
            $recipients[] = [
                'id' => (int) $row['id'],
                'name' => (string) (($row['nickname'] ?: 'User #' . $row['id'])),
                'avatar_asset_path' => (string) (($row['avatar_asset'] ?? '') ?: $avatar['avatar']),
                'inner_avatar_asset_path' => $avatar['inner'],
            ];
        }

        return ['recipients' => $recipients];
    }

    public function bagItems(string $bagGroup, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $bagGroup = trim($bagGroup);
        if (!in_array($bagGroup, self::BAG_GROUPS, true)) {
            throw new ApiException('Invalid bag category.', 422);
        }

        $userId = (int) $user['id'];
        $this->expireInventoryIfNeeded($userId);
        $categoryKeys = $this->bagGroupCategories($bagGroup);

        $placeholders = implode(', ', array_fill(0, count($categoryKeys), '?'));
        $statement = $this->pdo->prepare(
            "SELECT *
             FROM user_store_inventory
             WHERE user_id = ?
               AND category_key IN ($placeholders)
               AND status = ?
             ORDER BY is_equipped DESC, created_at DESC, id DESC"
        );
        $statement->execute([$userId, ...$categoryKeys, 'active']);

        $items = [];
        foreach ($statement->fetchAll() as $item) {
            $items[] = $this->mapInventoryItem($item);
        }

        return [
            'group' => $bagGroup,
            'items' => $items,
        ];
    }

    public function equipInventoryItem(int $inventoryId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];
        $item = $this->requireInventoryItem($inventoryId, $userId);
        $categoryKeys = $this->bagGroupCategories($this->bagGroupForCategory((string) $item['category_key']));

        $this->pdo->beginTransaction();
        try {
            $placeholders = implode(', ', array_fill(0, count($categoryKeys), '?'));
            $reset = $this->pdo->prepare(
                "UPDATE user_store_inventory
                 SET is_equipped = 0, updated_at = ?
                 WHERE user_id = ?
                   AND category_key IN ($placeholders)"
            );
            $reset->execute([$this->now(), $userId, ...$categoryKeys]);

            $update = $this->pdo->prepare(
                'UPDATE user_store_inventory
                 SET is_equipped = 1, updated_at = :updated_at
                 WHERE id = :id'
            );
            $update->execute([
                'updated_at' => $this->now(),
                'id' => $inventoryId,
            ]);
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'item' => $this->mapInventoryItem($this->requireInventoryItem($inventoryId, $userId)),
        ];
    }

    public function unequipInventoryItem(int $inventoryId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];
        $this->requireInventoryItem($inventoryId, $userId);

        $update = $this->pdo->prepare(
            'UPDATE user_store_inventory
             SET is_equipped = 0, updated_at = :updated_at
             WHERE id = :id'
        );
        $update->execute([
            'updated_at' => $this->now(),
            'id' => $inventoryId,
        ]);

        return [
            'item' => $this->mapInventoryItem($this->requireInventoryItem($inventoryId, $userId)),
        ];
    }

    public function removeInventoryItem(int $inventoryId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];
        $this->requireInventoryItem($inventoryId, $userId);

        $update = $this->pdo->prepare(
            'UPDATE user_store_inventory
             SET status = :status, is_equipped = 0, updated_at = :updated_at
             WHERE id = :id'
        );
        $update->execute([
            'status' => 'removed',
            'updated_at' => $this->now(),
            'id' => $inventoryId,
        ]);

        return ['success' => true];
    }

    public function adminListWalletPackages(string $walletType = '', string $search = ''): array
    {
        $sql = 'SELECT * FROM wallet_packages WHERE 1 = 1';
        $params = [];

        if ($walletType !== '') {
            $sql .= ' AND wallet_type = :wallet_type';
            $params['wallet_type'] = $walletType;
        }

        if ($search !== '') {
            $sql .= ' AND price_label LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY wallet_type ASC, display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function createWalletPackageAdmin(
        string $walletType,
        int $amount,
        int $bonusAmount,
        string $priceLabel,
        string $status
    ): void {
        $this->assertWalletType($walletType);
        $this->assertStatus($status);

        $insert = $this->pdo->prepare(
            'INSERT INTO wallet_packages
                (wallet_type, amount, bonus_amount, price_label, status, display_order, created_at, updated_at)
             VALUES
                (:wallet_type, :amount, :bonus_amount, :price_label, :status, :display_order, :created_at, :updated_at)'
        );
        $insert->execute([
            'wallet_type' => $walletType,
            'amount' => max(1, $amount),
            'bonus_amount' => max(0, $bonusAmount),
            'price_label' => trim($priceLabel) === '' ? '0' : trim($priceLabel),
            'status' => $status,
            'display_order' => $this->nextDisplayOrder('wallet_packages'),
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);
    }

    public function updateWalletPackageAdmin(
        int $packageId,
        string $walletType,
        int $amount,
        int $bonusAmount,
        string $priceLabel,
        string $status
    ): void {
        $this->assertWalletType($walletType);
        $this->assertStatus($status);

        $update = $this->pdo->prepare(
            'UPDATE wallet_packages
             SET wallet_type = :wallet_type,
                 amount = :amount,
                 bonus_amount = :bonus_amount,
                 price_label = :price_label,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $update->execute([
            'wallet_type' => $walletType,
            'amount' => max(1, $amount),
            'bonus_amount' => max(0, $bonusAmount),
            'price_label' => trim($priceLabel) === '' ? '0' : trim($priceLabel),
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $packageId,
        ]);
    }

    public function adminListStoreItems(string $categoryKey = '', string $search = ''): array
    {
        $sql = 'SELECT * FROM store_items WHERE 1 = 1';
        $params = [];

        if ($categoryKey !== '') {
            $sql .= ' AND category_key = :category_key';
            $params['category_key'] = $categoryKey;
        }

        if ($search !== '') {
            $sql .= ' AND name LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY category_key ASC, display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function createStoreItemAdmin(
        string $categoryKey,
        string $name,
        string $previewAssetPath,
        string $dialogIconAssetPath,
        string $dialogPreviewAssetPath,
        int $price3Days,
        int $price7Days,
        int $price15Days,
        int $price30Days,
        string $discount3Days,
        string $discount7Days,
        string $discount15Days,
        string $discount30Days,
        string $status
    ): void {
        $this->assertStoreCategory($categoryKey);
        $this->assertStatus($status);

        $insert = $this->pdo->prepare(
            'INSERT INTO store_items
                (category_key, name, preview_asset_path, dialog_icon_asset_path, dialog_preview_asset_path, price_3_days, price_7_days, price_15_days, price_30_days, discount_3_days, discount_7_days, discount_15_days, discount_30_days, currency_type, status, display_order, created_at, updated_at)
             VALUES
                (:category_key, :name, :preview_asset_path, :dialog_icon_asset_path, :dialog_preview_asset_path, :price_3_days, :price_7_days, :price_15_days, :price_30_days, :discount_3_days, :discount_7_days, :discount_15_days, :discount_30_days, :currency_type, :status, :display_order, :created_at, :updated_at)'
        );
        $insert->execute([
            'category_key' => $categoryKey,
            'name' => trim($name) === '' ? 'عنصر جديد' : trim($name),
            'preview_asset_path' => trim($previewAssetPath),
            'dialog_icon_asset_path' => trim($dialogIconAssetPath) === '' ? null : trim($dialogIconAssetPath),
            'dialog_preview_asset_path' => trim($dialogPreviewAssetPath) === '' ? null : trim($dialogPreviewAssetPath),
            'price_3_days' => max(0, $price3Days),
            'price_7_days' => max(0, $price7Days),
            'price_15_days' => max(0, $price15Days),
            'price_30_days' => max(0, $price30Days),
            'discount_3_days' => trim($discount3Days),
            'discount_7_days' => trim($discount7Days),
            'discount_15_days' => trim($discount15Days),
            'discount_30_days' => trim($discount30Days),
            'currency_type' => 'coins',
            'status' => $status,
            'display_order' => $this->nextDisplayOrder('store_items'),
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);
    }

    public function updateStoreItemAdmin(
        int $itemId,
        string $categoryKey,
        string $name,
        string $previewAssetPath,
        string $dialogIconAssetPath,
        string $dialogPreviewAssetPath,
        int $price3Days,
        int $price7Days,
        int $price15Days,
        int $price30Days,
        string $discount3Days,
        string $discount7Days,
        string $discount15Days,
        string $discount30Days,
        string $status
    ): void {
        $this->assertStoreCategory($categoryKey);
        $this->assertStatus($status);

        $update = $this->pdo->prepare(
            'UPDATE store_items
             SET category_key = :category_key,
                 name = :name,
                 preview_asset_path = :preview_asset_path,
                 dialog_icon_asset_path = :dialog_icon_asset_path,
                 dialog_preview_asset_path = :dialog_preview_asset_path,
                 price_3_days = :price_3_days,
                 price_7_days = :price_7_days,
                 price_15_days = :price_15_days,
                 price_30_days = :price_30_days,
                 discount_3_days = :discount_3_days,
                 discount_7_days = :discount_7_days,
                 discount_15_days = :discount_15_days,
                 discount_30_days = :discount_30_days,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $update->execute([
            'category_key' => $categoryKey,
            'name' => trim($name) === '' ? 'عنصر جديد' : trim($name),
            'preview_asset_path' => trim($previewAssetPath),
            'dialog_icon_asset_path' => trim($dialogIconAssetPath) === '' ? null : trim($dialogIconAssetPath),
            'dialog_preview_asset_path' => trim($dialogPreviewAssetPath) === '' ? null : trim($dialogPreviewAssetPath),
            'price_3_days' => max(0, $price3Days),
            'price_7_days' => max(0, $price7Days),
            'price_15_days' => max(0, $price15Days),
            'price_30_days' => max(0, $price30Days),
            'discount_3_days' => trim($discount3Days),
            'discount_7_days' => trim($discount7Days),
            'discount_15_days' => trim($discount15Days),
            'discount_30_days' => trim($discount30Days),
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $itemId,
        ]);
    }

    public function adminListEconomyTransactions(string $search = ''): array
    {
        $statement = $this->pdo->prepare(
            'SELECT wallet_transactions.*,
                    users.nickname AS user_nickname,
                    users.email AS user_email
             FROM wallet_transactions
             INNER JOIN users ON users.id = wallet_transactions.user_id
             WHERE (:search = "" OR wallet_transactions.title LIKE :like_search OR wallet_transactions.subtitle LIKE :like_search OR COALESCE(users.nickname, "") LIKE :like_search OR COALESCE(users.email, "") LIKE :like_search)
             ORDER BY wallet_transactions.created_at DESC, wallet_transactions.id DESC
             LIMIT 200'
        );
        $statement->execute([
            'search' => $search,
            'like_search' => '%' . $search . '%',
        ]);

        return $statement->fetchAll();
    }

    private function listWalletPackages(string $walletType): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM wallet_packages
             WHERE wallet_type = :wallet_type
               AND status = :status
             ORDER BY display_order ASC, id ASC'
        );
        $statement->execute([
            'wallet_type' => $walletType,
            'status' => 'active',
        ]);

        $packages = [];
        foreach ($statement->fetchAll() as $row) {
            $packages[] = [
                'id' => (int) $row['id'],
                'wallet_type' => (string) $row['wallet_type'],
                'amount' => (int) $row['amount'],
                'bonus_amount' => (int) $row['bonus_amount'],
                'price_label' => (string) $row['price_label'],
            ];
        }

        return $packages;
    }

    private function listWalletTransactions(int $userId, ?string $walletType): array
    {
        $sql = 'SELECT *
                FROM wallet_transactions
                WHERE user_id = :user_id';
        $params = ['user_id' => $userId];

        if ($walletType !== null) {
            $sql .= ' AND wallet_type = :wallet_type';
            $params['wallet_type'] = $walletType;
        }

        $sql .= ' ORDER BY created_at DESC, id DESC LIMIT 100';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $entries = [];
        foreach ($statement->fetchAll() as $row) {
            $createdAt = strtotime((string) $row['created_at']) ?: time();
            $entries[] = [
                'id' => (int) $row['id'],
                'wallet_type' => (string) $row['wallet_type'],
                'direction' => (string) $row['direction'],
                'amount' => (int) $row['amount'],
                'status' => (string) $row['status'],
                'title' => (string) $row['title'],
                'subtitle' => (string) $row['subtitle'],
                'date_label' => gmdate('d/m/Y', $createdAt),
                'time_label' => gmdate('H:i', $createdAt),
            ];
        }

        return $entries;
    }

    private function insertWalletTransaction(
        int $userId,
        string $walletType,
        string $direction,
        int $amount,
        string $status,
        string $title,
        string $subtitle,
        string $contextType,
        ?string $contextRef
    ): void {
        $insert = $this->pdo->prepare(
            'INSERT INTO wallet_transactions
                (user_id, wallet_type, direction, amount, status, title, subtitle, context_type, context_ref, created_at)
             VALUES
                (:user_id, :wallet_type, :direction, :amount, :status, :title, :subtitle, :context_type, :context_ref, :created_at)'
        );
        $insert->execute([
            'user_id' => $userId,
            'wallet_type' => $walletType,
            'direction' => $direction,
            'amount' => $amount,
            'status' => $status,
            'title' => $title,
            'subtitle' => $subtitle,
            'context_type' => $contextType,
            'context_ref' => $contextRef,
            'created_at' => $this->now(),
        ]);
    }

    private function debitWallet(int $userId, string $walletType, int $amount): void
    {
        $wallet = $this->walletRowForUser($userId);
        $column = $walletType === 'diamonds' ? 'diamonds_balance' : 'coins_balance';

        if ((int) $wallet[$column] < $amount) {
            throw new ApiException('رصيدك غير كافٍ لإتمام العملية.', 422);
        }

        $this->adjustWalletBalance($userId, $walletType, -$amount);
    }

    private function adjustWalletBalance(int $userId, string $walletType, int $delta): void
    {
        $column = $walletType === 'diamonds' ? 'diamonds_balance' : 'coins_balance';
        $statement = $this->pdo->prepare(
            "UPDATE user_wallets
             SET $column = $column + :delta,
                 updated_at = :updated_at
             WHERE user_id = :user_id"
        );
        $statement->execute([
            'delta' => $delta,
            'updated_at' => $this->now(),
            'user_id' => $userId,
        ]);
    }

    private function walletRowForUser(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM user_wallets
             WHERE user_id = :user_id
             LIMIT 1'
        );
        $statement->execute(['user_id' => $userId]);
        $wallet = $statement->fetch();

        if ($wallet === false) {
            throw new ApiException('Wallet not found.', 404);
        }

        return $wallet;
    }

    private function mapWallet(array $wallet): array
    {
        return [
            'coins_balance' => (int) $wallet['coins_balance'],
            'diamonds_balance' => (int) $wallet['diamonds_balance'],
        ];
    }

    private function mapStoreItem(array $item): array
    {
        return [
            'id' => (int) $item['id'],
            'category_key' => (string) $item['category_key'],
            'name' => (string) $item['name'],
            'preview_asset_path' => (string) $item['preview_asset_path'],
            'dialog_icon_asset_path' => $item['dialog_icon_asset_path'] === null ? null : (string) $item['dialog_icon_asset_path'],
            'dialog_preview_asset_path' => $item['dialog_preview_asset_path'] === null ? null : (string) $item['dialog_preview_asset_path'],
            'currency_type' => (string) $item['currency_type'],
            'durations' => [
                ['days' => 3, 'price' => (int) $item['price_3_days'], 'discount' => (string) $item['discount_3_days']],
                ['days' => 7, 'price' => (int) $item['price_7_days'], 'discount' => (string) $item['discount_7_days']],
                ['days' => 15, 'price' => (int) $item['price_15_days'], 'discount' => (string) $item['discount_15_days']],
                ['days' => 30, 'price' => (int) $item['price_30_days'], 'discount' => (string) $item['discount_30_days']],
            ],
            'default_duration_days' => 7,
        ];
    }

    private function insertInventoryRecord(
        int $userId,
        array $item,
        int $durationDays,
        string $acquiredVia,
        ?string $senderName,
        ?string $recipientName
    ): int {
        $expiresAt = gmdate('Y-m-d H:i:s', time() + ($durationDays * 86400));
        $insert = $this->pdo->prepare(
            'INSERT INTO user_store_inventory
                (user_id, item_id, category_key, item_name_snapshot, preview_asset_path, dialog_preview_asset_path, duration_days, status, is_equipped, acquired_via, sender_name_snapshot, recipient_name_snapshot, expires_at, created_at, updated_at)
             VALUES
                (:user_id, :item_id, :category_key, :item_name_snapshot, :preview_asset_path, :dialog_preview_asset_path, :duration_days, :status, :is_equipped, :acquired_via, :sender_name_snapshot, :recipient_name_snapshot, :expires_at, :created_at, :updated_at)'
        );
        $insert->execute([
            'user_id' => $userId,
            'item_id' => (int) $item['id'],
            'category_key' => (string) $item['category_key'],
            'item_name_snapshot' => (string) $item['name'],
            'preview_asset_path' => (string) $item['preview_asset_path'],
            'dialog_preview_asset_path' => $item['dialog_preview_asset_path'] === null ? null : (string) $item['dialog_preview_asset_path'],
            'duration_days' => $durationDays,
            'status' => 'active',
            'is_equipped' => 0,
            'acquired_via' => $acquiredVia,
            'sender_name_snapshot' => $senderName,
            'recipient_name_snapshot' => $recipientName,
            'expires_at' => $expiresAt,
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);

        return (int) $this->pdo->lastInsertId();
    }

    private function requireInventoryItem(int $inventoryId, int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM user_store_inventory
             WHERE id = :id
               AND user_id = :user_id
             LIMIT 1'
        );
        $statement->execute([
            'id' => $inventoryId,
            'user_id' => $userId,
        ]);
        $item = $statement->fetch();

        if ($item === false) {
            throw new ApiException('Inventory item not found.', 404);
        }

        return $item;
    }

    private function mapInventoryItem(array $item): array
    {
        $expiresAt = strtotime((string) $item['expires_at']) ?: time();

        return [
            'id' => (int) $item['id'],
            'item_id' => (int) $item['item_id'],
            'category_key' => (string) $item['category_key'],
            'name' => (string) $item['item_name_snapshot'],
            'preview_asset_path' => (string) $item['preview_asset_path'],
            'dialog_preview_asset_path' => $item['dialog_preview_asset_path'] === null ? null : (string) $item['dialog_preview_asset_path'],
            'duration_days' => (int) $item['duration_days'],
            'status' => (string) $item['status'],
            'is_equipped' => (int) $item['is_equipped'] === 1,
            'acquired_via' => (string) $item['acquired_via'],
            'expires_at_label' => gmdate('d/m/Y', $expiresAt),
        ];
    }

    private function expireInventoryIfNeeded(int $userId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE user_store_inventory
             SET status = :status, is_equipped = 0, updated_at = :updated_at
             WHERE user_id = :user_id
               AND status = :active_status
               AND expires_at < :now'
        );
        $statement->execute([
            'status' => 'expired',
            'updated_at' => $this->now(),
            'user_id' => $userId,
            'active_status' => 'active',
            'now' => $this->now(),
        ]);
    }

    private function requireStoreItem(int $itemId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM store_items
             WHERE id = :id
               AND status = :status
             LIMIT 1'
        );
        $statement->execute([
            'id' => $itemId,
            'status' => 'active',
        ]);
        $item = $statement->fetch();

        if ($item === false) {
            throw new ApiException('Store item not found.', 404);
        }

        return $item;
    }

    private function resolveItemPrice(array $item, int $durationDays): int
    {
        $column = match ($durationDays) {
            3 => 'price_3_days',
            7 => 'price_7_days',
            15 => 'price_15_days',
            30 => 'price_30_days',
            default => null,
        };

        if ($column === null) {
            throw new ApiException('Invalid duration selected.', 422);
        }

        $price = (int) $item[$column];
        if ($price <= 0) {
            throw new ApiException('Selected duration is not available.', 422);
        }

        return $price;
    }

    private function findWalletPackageById(int $packageId): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM wallet_packages
             WHERE id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $packageId]);
        $package = $statement->fetch();

        return $package === false ? null : $package;
    }

    private function bagGroupForCategory(string $categoryKey): string
    {
        return match ($categoryKey) {
            'animated_frames' => 'animated',
            'entry_effects' => 'entry_effects',
            default => 'art',
        };
    }

    private function bagGroupCategories(string $bagGroup): array
    {
        return match ($bagGroup) {
            'animated' => ['animated_frames'],
            'entry_effects' => ['entry_effects'],
            default => ['frames', 'backgrounds', 'chat_frames', 'aristocracy'],
        };
    }

    private function assertWalletType(string $walletType): void
    {
        if (!in_array($walletType, self::WALLET_TYPES, true)) {
            throw new ApiException('Invalid wallet type.', 422);
        }
    }

    private function assertStoreCategory(string $categoryKey): void
    {
        if (!in_array($categoryKey, self::STORE_CATEGORIES, true)) {
            throw new ApiException('Invalid store category.', 422);
        }
    }

    private function assertStatus(string $status): void
    {
        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid status.', 422);
        }
    }

    private function nextDisplayOrder(string $table): int
    {
        return ((int) $this->pdo->query("SELECT COALESCE(MAX(display_order), 0) FROM $table")->fetchColumn()) + 1;
    }

    private function requireUser(?string $authorizationHeader): array
    {
        $user = $this->resolveUserFromAuthorization($authorizationHeader);

        if ($user === null) {
            throw new ApiException('Unauthenticated.', 401);
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

    private function findUserById(int $userId): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM users
             WHERE id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $userId]);
        $user = $statement->fetch();

        return $user === false ? null : $user;
    }

    private function displayNameForUser(array $user): string
    {
        $nickname = trim((string) ($user['nickname'] ?? ''));
        if ($nickname !== '') {
            return $nickname;
        }

        $email = trim((string) ($user['email'] ?? ''));
        if ($email !== '') {
            return (string) strstr($email, '@', true);
        }

        return 'Voice User';
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
