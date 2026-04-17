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
                    (room_id, sender_user_id, sender_name, sender_avatar_asset, gift_id, gift_name_snapshot, quantity, unit_price_coins, total_price_coins, recipient_mode, recipient_slot, created_at)
                 VALUES
                    (:room_id, :sender_user_id, :sender_name, :sender_avatar_asset, :gift_id, :gift_name_snapshot, :quantity, :unit_price_coins, :total_price_coins, :recipient_mode, :recipient_slot, :created_at)'
            );
            $insertTransaction->execute([
                'room_id' => $roomId,
                'sender_user_id' => $user['id'],
                'sender_name' => (string) ($user['nickname'] ?: $user['email'] ?: 'Mohammed Ahmed'),
                'sender_avatar_asset' => 'assets/images/profile_avatar.png',
                'gift_id' => $giftId,
                'gift_name_snapshot' => $gift['name'],
                'quantity' => $quantity,
                'unit_price_coins' => $unitPrice,
                'total_price_coins' => $totalPrice,
                'recipient_mode' => $recipientMode,
                'recipient_slot' => $recipientSlot,
                'created_at' => $this->now(),
            ]);

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
        ];
    }

    public function adminListGifts(string $search = ''): array
    {
        $sql = 'SELECT * FROM gifts';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE name LIKE :search OR category LIKE :search';
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
        int $priceCoins,
        string $status
    ): void {
        if ($name === '' || $category === '' || $priceCoins < 1) {
            throw new ApiException('Invalid gift data.', 422);
        }

        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid gift status.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE gifts
             SET name = :name,
                 category = :category,
                 price_coins = :price_coins,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'name' => $name,
            'category' => $category,
            'price_coins' => $priceCoins,
            'status' => $status,
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

    private function mapGift(array $gift): array
    {
        return [
            'id' => (int) $gift['id'],
            'name' => (string) $gift['name'],
            'category' => (string) $gift['category'],
            'asset_path' => (string) $gift['asset_path'],
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
