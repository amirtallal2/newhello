<?php

declare(strict_types=1);

final class GiftService
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    public function catalog(): array
    {
        $statement = $this->pdo->query(
            'SELECT *
             FROM gifts
             WHERE status = "active"
             ORDER BY display_order ASC, id ASC'
        );

        $gifts = [];
        foreach ($statement->fetchAll() as $gift) {
            $gifts[] = $this->mapGift($gift);
        }

        return $gifts;
    }

    public function walletSummary(?string $authorizationHeader): array
    {
        $user = $this->resolveUserFromAuthorization($authorizationHeader);

        if ($user === null) {
            return [
                'coins_balance' => 1235,
                'diamonds_balance' => 5,
                'is_guest' => true,
            ];
        }

        return $this->walletSummaryForUser((int) $user['id']);
    }

    public function sendRoomGift(
        int $roomId,
        int $giftId,
        int $quantity,
        string $recipientMode,
        ?int $recipientSlot,
        ?string $authorizationHeader
    ): array {
        if ($quantity < 1 || $quantity > 999) {
            throw new ApiException('Invalid gift quantity.', 422);
        }

        if (!in_array($recipientMode, ['room_users', 'selected_user'], true)) {
            throw new ApiException('Invalid recipient mode.', 422);
        }

        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        $gift = $this->findGiftById($giftId);
        if ($gift === null || (string) $gift['status'] !== 'active') {
            throw new ApiException('Gift not found.', 404);
        }

        $user = $this->resolveUserFromAuthorization($authorizationHeader);
        if ($user === null) {
            throw new ApiException('Authentication required to send gifts.', 401);
        }

        $wallet = $this->walletRowForUser((int) $user['id']);
        $unitPrice = (int) $gift['price_coins'];
        $totalPrice = $unitPrice * $quantity;
        $recipient = $this->resolveRoomGiftRecipient($room, $recipientMode, $recipientSlot);
        $commissionPercent = $this->giftPlatformCommissionPercent();
        $earnings = $this->calculateGiftEarnings(
            $totalPrice,
            $commissionPercent,
            (int) ($recipient['user_id'] ?? 0),
            (int) $user['id']
        );

        if ((int) $wallet['coins_balance'] < $totalPrice) {
            throw new ApiException('Insufficient coin balance.', 422);
        }

        $this->pdo->beginTransaction();

        try {
            $updateWallet = $this->pdo->prepare(
                'UPDATE user_wallets
                 SET coins_balance = coins_balance - :amount, updated_at = :updated_at
                 WHERE user_id = :user_id'
            );
            $updateWallet->execute([
                'amount' => $totalPrice,
                'updated_at' => $this->now(),
                'user_id' => $user['id'],
            ]);

            $insertTransaction = $this->pdo->prepare(
                'INSERT INTO room_gift_transactions
                    (room_id, sender_user_id, sender_name, sender_avatar_asset, recipient_user_id, recipient_name_snapshot, gift_id, gift_name_snapshot, quantity, unit_price_coins, total_price_coins, platform_fee_coins, creator_earning_diamonds, platform_commission_percent, recipient_mode, recipient_slot, created_at)
                 VALUES
                    (:room_id, :sender_user_id, :sender_name, :sender_avatar_asset, :recipient_user_id, :recipient_name_snapshot, :gift_id, :gift_name_snapshot, :quantity, :unit_price_coins, :total_price_coins, :platform_fee_coins, :creator_earning_diamonds, :platform_commission_percent, :recipient_mode, :recipient_slot, :created_at)'
            );
            $insertTransaction->execute([
                'room_id' => $roomId,
                'sender_user_id' => $user['id'],
                'sender_name' => (string) ($user['nickname'] ?: $user['email'] ?: 'Mohammed Ahmed'),
                'sender_avatar_asset' => (string) ($user['avatar_asset'] ?: 'assets/images/profile_avatar.png'),
                'recipient_user_id' => $recipient['user_id'],
                'recipient_name_snapshot' => $recipient['name'],
                'gift_id' => $giftId,
                'gift_name_snapshot' => $gift['name'],
                'quantity' => $quantity,
                'unit_price_coins' => $unitPrice,
                'total_price_coins' => $totalPrice,
                'platform_fee_coins' => $earnings['platform_fee_coins'],
                'creator_earning_diamonds' => $earnings['creator_earning_diamonds'],
                'platform_commission_percent' => $commissionPercent,
                'recipient_mode' => $recipientMode,
                'recipient_slot' => $recipientSlot,
                'created_at' => $this->now(),
            ]);
            $transactionId = (int) $this->pdo->lastInsertId();

            $insertWalletTransaction = $this->pdo->prepare(
                'INSERT INTO wallet_transactions
                    (user_id, wallet_type, direction, amount, status, title, subtitle, context_type, context_ref, created_at)
                 VALUES
                    (:user_id, :wallet_type, :direction, :amount, :status, :title, :subtitle, :context_type, :context_ref, :created_at)'
            );
            $insertWalletTransaction->execute([
                'user_id' => (int) $user['id'],
                'wallet_type' => 'coins',
                'direction' => 'out',
                'amount' => $totalPrice,
                'status' => 'success',
                'title' => 'إرسال هدية',
                'subtitle' => (string) $gift['name'] . ' x' . $quantity,
                'context_type' => 'room_gift',
                'context_ref' => (string) $transactionId,
                'created_at' => $this->now(),
            ]);

            if ((int) ($recipient['user_id'] ?? 0) > 0 && $earnings['creator_earning_diamonds'] > 0) {
                $this->creditGiftRecipient(
                    (int) $recipient['user_id'],
                    $earnings['creator_earning_diamonds'],
                    'ربح هدية غرفة صوتية',
                    (string) $gift['name'] . ' من ' . (string) ($user['nickname'] ?: $user['email'] ?: 'مستخدم'),
                    'room_gift_earning',
                    $transactionId
                );
            }

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'wallet' => $this->walletSummaryForUser((int) $user['id']),
            'supporters' => $this->roomReceivedGifts($roomId),
        ];
    }

    public function roomReceivedGifts(int $roomId): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'SELECT sender_name,
                    sender_avatar_asset,
                    SUM(total_price_coins) AS total_coins,
                    COUNT(*) AS send_count
             FROM room_gift_transactions
             WHERE room_id = :room_id
             GROUP BY sender_name, sender_avatar_asset
             ORDER BY total_coins DESC, send_count DESC, sender_name ASC
             LIMIT 20'
        );
        $statement->execute(['room_id' => $roomId]);

        $entries = [];
        foreach (array_values($statement->fetchAll()) as $index => $row) {
            $entries[] = [
                'rank' => $index + 1,
                'name' => (string) $row['sender_name'],
                'avatar_asset' => (string) ($row['sender_avatar_asset'] ?: 'assets/images/profile_avatar.png'),
                'total_coins' => (int) $row['total_coins'],
                'coins_label' => ((int) $row['total_coins']) . ' Coin',
                'is_top_supporter' => $index === 0,
            ];
        }

        return $entries;
    }

    public function adminGiftStats(): array
    {
        return [
            'gifts' => (int) $this->pdo->query('SELECT COUNT(*) FROM gifts')->fetchColumn(),
            'active_gifts' => (int) $this->pdo->query('SELECT COUNT(*) FROM gifts WHERE status = "active"')->fetchColumn(),
            'sent_transactions' => (int) $this->pdo->query('SELECT COUNT(*) FROM room_gift_transactions')->fetchColumn(),
            'spent_coins' => (int) $this->pdo->query('SELECT COALESCE(SUM(total_price_coins), 0) FROM room_gift_transactions')->fetchColumn(),
            'creator_earnings_diamonds' => (int) $this->pdo->query('SELECT COALESCE(SUM(creator_earning_diamonds), 0) FROM room_gift_transactions')->fetchColumn(),
            'platform_fees_coins' => (int) $this->pdo->query('SELECT COALESCE(SUM(platform_fee_coins), 0) FROM room_gift_transactions')->fetchColumn(),
        ];
    }

    public function adminGiftMonetizationSettings(): array
    {
        return [
            'commission_percent' => $this->giftPlatformCommissionPercent(),
            'recipient_currency' => 'diamonds',
        ];
    }

    public function updateGiftMonetizationSettings(float $commissionPercent): void
    {
        $commissionPercent = max(0.0, min(95.0, $commissionPercent));
        $this->setSettingValue('gift_platform_commission_percent', number_format($commissionPercent, 2, '.', ''));
    }

    public function adminListGifts(string $search = ''): array
    {
        $sql = 'SELECT * FROM gifts';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE name LIKE :search
                      OR category LIKE :search
                      OR asset_path LIKE :search
                      OR animation_path LIKE :search
                      OR sound_path LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function updateGiftAdmin(
        int $giftId,
        string $name,
        string $category,
        string $assetPath,
        string $animationPath,
        string $soundPath,
        bool $isAnimated,
        int $effectDurationMs,
        int $priceCoins,
        int $displayOrder,
        string $status
    ): void {
        if ($name === '' || $category === '' || $assetPath === '' || $priceCoins < 1) {
            throw new ApiException('Invalid gift data.', 422);
        }

        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid gift status.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE gifts
             SET name = :name,
                 category = :category,
                 asset_path = :asset_path,
                 animation_path = :animation_path,
                 sound_path = :sound_path,
                 is_animated = :is_animated,
                 effect_duration_ms = :effect_duration_ms,
                 price_coins = :price_coins,
                 display_order = :display_order,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'name' => $name,
            'category' => $category,
            'asset_path' => $assetPath,
            'animation_path' => $animationPath === '' ? null : $animationPath,
            'sound_path' => $soundPath === '' ? null : $soundPath,
            'is_animated' => $isAnimated ? 1 : 0,
            'effect_duration_ms' => max(600, min(8000, $effectDurationMs)),
            'price_coins' => $priceCoins,
            'display_order' => max(0, $displayOrder),
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $giftId,
        ]);
    }

    public function createGiftAdmin(
        string $name,
        string $category,
        string $assetPath,
        string $animationPath,
        string $soundPath,
        bool $isAnimated,
        int $effectDurationMs,
        int $priceCoins,
        int $displayOrder,
        string $status
    ): void {
        if ($name === '' || $category === '' || $assetPath === '' || $priceCoins < 1) {
            throw new ApiException('Invalid gift data.', 422);
        }

        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid gift status.', 422);
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO gifts
                (name, category, asset_path, animation_path, sound_path, is_animated, effect_duration_ms, price_coins, status, display_order, created_at, updated_at)
             VALUES
                (:name, :category, :asset_path, :animation_path, :sound_path, :is_animated, :effect_duration_ms, :price_coins, :status, :display_order, :created_at, :updated_at)'
        );
        $statement->execute([
            'name' => $name,
            'category' => $category,
            'asset_path' => $assetPath,
            'animation_path' => $animationPath === '' ? null : $animationPath,
            'sound_path' => $soundPath === '' ? null : $soundPath,
            'is_animated' => $isAnimated ? 1 : 0,
            'effect_duration_ms' => max(600, min(8000, $effectDurationMs)),
            'price_coins' => $priceCoins,
            'status' => $status,
            'display_order' => max(0, $displayOrder),
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);
    }

    public function hideGiftAdmin(int $giftId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE gifts
             SET status = "hidden",
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'updated_at' => $this->now(),
            'id' => $giftId,
        ]);
    }

    public function adminListTransactions(string $search = ''): array
    {
        $sql = 'SELECT room_gift_transactions.*,
                       rooms.room_title,
                       gifts.asset_path
                FROM room_gift_transactions
                INNER JOIN rooms ON rooms.id = room_gift_transactions.room_id
                INNER JOIN gifts ON gifts.id = room_gift_transactions.gift_id';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE room_gift_transactions.sender_name LIKE :search
                      OR room_gift_transactions.recipient_name_snapshot LIKE :search
                      OR rooms.room_title LIKE :search
                      OR room_gift_transactions.gift_name_snapshot LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY room_gift_transactions.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function createWalletForUser(int $userId): void
    {
        $statement = $this->pdo->prepare(
            'SELECT user_id FROM user_wallets WHERE user_id = :user_id LIMIT 1'
        );
        $statement->execute(['user_id' => $userId]);

        if ($statement->fetch() !== false) {
            return;
        }

        $insert = $this->pdo->prepare(
            'INSERT INTO user_wallets
                (user_id, coins_balance, diamonds_balance, created_at, updated_at)
             VALUES
                (:user_id, :coins_balance, :diamonds_balance, :created_at, :updated_at)'
        );
        $insert->execute([
            'user_id' => $userId,
            'coins_balance' => 1235,
            'diamonds_balance' => 5,
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);
    }

    private function walletSummaryForUser(int $userId): array
    {
        $wallet = $this->walletRowForUser($userId);

        return [
            'coins_balance' => (int) $wallet['coins_balance'],
            'diamonds_balance' => (int) $wallet['diamonds_balance'],
            'is_guest' => false,
        ];
    }

    private function resolveRoomGiftRecipient(array $room, string $recipientMode, ?int $recipientSlot): array
    {
        if ($recipientMode === 'selected_user' && $recipientSlot !== null && $recipientSlot > 0) {
            $participant = $this->findActiveRoomParticipantBySeat((int) $room['id'], $recipientSlot);
            if ($participant !== null && isset($participant['user_id']) && $participant['user_id'] !== null) {
                return [
                    'user_id' => (int) $participant['user_id'],
                    'name' => (string) ($participant['display_name'] ?: 'مستخدم'),
                ];
            }
        }

        if (isset($room['host_user_id']) && $room['host_user_id'] !== null) {
            $host = $this->findUserById((int) $room['host_user_id']);
            return [
                'user_id' => (int) $room['host_user_id'],
                'name' => $host === null
                    ? (string) ($room['host_name'] ?? 'صاحب الغرفة')
                    : $this->displayNameForUser($host),
            ];
        }

        return [
            'user_id' => null,
            'name' => (string) ($room['host_name'] ?? 'صاحب الغرفة'),
        ];
    }

    private function findActiveRoomParticipantBySeat(int $roomId, int $seatNumber): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM room_audio_participants
             WHERE room_id = :room_id
               AND seat_number = :seat_number
               AND status = "joined"
               AND left_at IS NULL
             ORDER BY id DESC
             LIMIT 1'
        );
        $statement->execute([
            'room_id' => $roomId,
            'seat_number' => $seatNumber,
        ]);
        $participant = $statement->fetch();

        return $participant === false ? null : $participant;
    }

    private function calculateGiftEarnings(
        int $totalPrice,
        float $commissionPercent,
        int $recipientUserId,
        int $senderUserId
    ): array {
        if ($recipientUserId <= 0 || $recipientUserId === $senderUserId) {
            return [
                'platform_fee_coins' => $totalPrice,
                'creator_earning_diamonds' => 0,
            ];
        }

        $platformFee = (int) floor($totalPrice * ($commissionPercent / 100));
        $creatorEarning = max(0, $totalPrice - $platformFee);

        return [
            'platform_fee_coins' => $platformFee,
            'creator_earning_diamonds' => $creatorEarning,
        ];
    }

    private function creditGiftRecipient(
        int $recipientUserId,
        int $amount,
        string $title,
        string $subtitle,
        string $contextType,
        int $transactionId
    ): void {
        $this->createWalletForUser($recipientUserId);

        $updateWallet = $this->pdo->prepare(
            'UPDATE user_wallets
             SET diamonds_balance = diamonds_balance + :amount,
                 updated_at = :updated_at
             WHERE user_id = :user_id'
        );
        $updateWallet->execute([
            'amount' => $amount,
            'updated_at' => $this->now(),
            'user_id' => $recipientUserId,
        ]);

        $insertTransaction = $this->pdo->prepare(
            'INSERT INTO wallet_transactions
                (user_id, wallet_type, direction, amount, status, title, subtitle, context_type, context_ref, created_at)
             VALUES
                (:user_id, :wallet_type, :direction, :amount, :status, :title, :subtitle, :context_type, :context_ref, :created_at)'
        );
        $insertTransaction->execute([
            'user_id' => $recipientUserId,
            'wallet_type' => 'diamonds',
            'direction' => 'in',
            'amount' => $amount,
            'status' => 'success',
            'title' => $title,
            'subtitle' => $subtitle,
            'context_type' => $contextType,
            'context_ref' => (string) $transactionId,
            'created_at' => $this->now(),
        ]);
    }

    private function walletRowForUser(int $userId): array
    {
        $this->createWalletForUser($userId);
        $statement = $this->pdo->prepare(
            'SELECT * FROM user_wallets WHERE user_id = :user_id LIMIT 1'
        );
        $statement->execute(['user_id' => $userId]);
        $wallet = $statement->fetch();

        if ($wallet === false) {
            throw new ApiException('Wallet not found.', 404);
        }

        return $wallet;
    }

    private function findGiftById(int $giftId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM gifts WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $giftId]);
        $gift = $statement->fetch();

        return $gift === false ? null : $gift;
    }

    private function findRoomById(int $roomId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM rooms WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $roomId]);
        $room = $statement->fetch();

        return $room === false ? null : $room;
    }

    private function findUserById(int $userId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM users WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $userId]);
        $user = $statement->fetch();

        return $user === false ? null : $user;
    }

    private function displayNameForUser(array $user): string
    {
        return (string) ($user['nickname'] ?: $user['email'] ?: 'مستخدم');
    }

    private function giftPlatformCommissionPercent(): float
    {
        return max(0.0, min(95.0, (float) $this->settingValue('gift_platform_commission_percent', '50')));
    }

    private function settingValue(string $key, string $default): string
    {
        try {
            $statement = $this->pdo->prepare(
                'SELECT setting_value FROM app_settings WHERE setting_key = :setting_key LIMIT 1'
            );
            $statement->execute(['setting_key' => $key]);
            $value = $statement->fetchColumn();

            return $value === false ? $default : (string) $value;
        } catch (Throwable) {
            return $default;
        }
    }

    private function setSettingValue(string $key, string $value): void
    {
        $now = $this->now();
        try {
            $statement = $this->pdo->prepare(
                'INSERT INTO app_settings (setting_key, setting_value, updated_at)
                 VALUES (:setting_key, :setting_value, :updated_at)
                 ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_at = VALUES(updated_at)'
            );
            $statement->execute([
                'setting_key' => $key,
                'setting_value' => $value,
                'updated_at' => $now,
            ]);
        } catch (Throwable) {
            $statement = $this->pdo->prepare(
                'INSERT INTO app_settings (setting_key, setting_value, updated_at)
                 VALUES (:setting_key, :setting_value, :updated_at)
                 ON CONFLICT(setting_key) DO UPDATE SET setting_value = excluded.setting_value, updated_at = excluded.updated_at'
            );
            $statement->execute([
                'setting_key' => $key,
                'setting_value' => $value,
                'updated_at' => $now,
            ]);
        }
    }

    private function mapGift(array $gift): array
    {
        return [
            'id' => (int) $gift['id'],
            'name' => (string) $gift['name'],
            'category' => (string) $gift['category'],
            'asset_path' => (string) $gift['asset_path'],
            'animation_path' => (string) ($gift['animation_path'] ?? ''),
            'sound_path' => (string) ($gift['sound_path'] ?? ''),
            'is_animated' => ((int) ($gift['is_animated'] ?? 0)) === 1,
            'effect_duration_ms' => (int) ($gift['effect_duration_ms'] ?? 1800),
            'price_coins' => (int) $gift['price_coins'],
            'status' => (string) $gift['status'],
        ];
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

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
