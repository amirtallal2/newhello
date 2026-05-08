<?php

declare(strict_types=1);

final class ChatService
{
    private const DEFAULT_AVATAR = 'assets/images/profile_avatar.png';
    private const SUPPORT_AVATAR = 'assets/images/chat_support_icon.png';
    private const NOTIFICATION_AVATAR = 'assets/images/chat_notification_icon.png';
    private const MESSAGE_TYPES = ['text', 'image', 'gift', 'voice'];

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function inbox(string $scope, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $this->ensureChatTargetUserSchema();
        $scope = $scope === 'friends' ? 'friends' : 'messages';

        $this->ensureDefaults((int) $user['id']);

        if ($scope === 'friends') {
            $this->ensureFriendThreads((int) $user['id']);

            return [
                'threads' => $this->listFriendThreads((int) $user['id']),
            ];
        }

        return [
            'system_threads' => $this->listThreads(
                ownerUserId: (int) $user['id'],
                listingGroup: 'messages',
                isSystem: true
            ),
            'threads' => $this->listThreads(
                ownerUserId: (int) $user['id'],
                listingGroup: 'messages',
                isSystem: false
            ),
        ];
    }

    public function selection(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $this->ensureChatTargetUserSchema();
        $this->ensureDefaults((int) $user['id']);
        $this->ensureFriendThreads((int) $user['id']);

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM chat_threads
             WHERE owner_user_id = :owner_user_id
               AND is_system = 0
               AND is_deleted = 0
             ORDER BY display_order ASC, updated_at DESC, id DESC'
        );
        $statement->execute([
            'owner_user_id' => (int) $user['id'],
        ]);

        return [
            'threads' => array_map(
                fn (array $thread): array => $this->mapThread($thread),
                $statement->fetchAll() ?: []
            ),
        ];
    }

    public function conversation(int $threadId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $this->ensureChatTargetUserSchema();
        $this->ensureDefaults((int) $user['id']);
        $thread = $this->requireThread($threadId, (int) $user['id']);

        $this->markThreadRead($threadId, (int) $user['id']);

        return [
            'thread' => $this->mapThread($thread),
            'messages' => $this->listMessages($threadId),
            'current_user_name' => $this->displayNameForUser($user),
        ];
    }

    public function sendMessage(
        int $threadId,
        string $bodyText,
        ?string $authorizationHeader,
        string $messageType = 'text',
        ?array $attachmentUpload = null,
        ?string $attachmentPath = null,
        ?string $attachmentName = null,
        int $giftId = 0,
        int $quantity = 1
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $this->ensureChatTargetUserSchema();
        $this->ensureChatMessageMediaSchema();
        $this->ensureDefaults((int) $user['id']);
        $thread = $this->requireThread($threadId, (int) $user['id']);
        $messageType = $this->normalizeMessageType($messageType);

        if ($messageType === 'gift') {
            $giftContext = $this->processChatGift($thread, $user, $giftId, $quantity);
            $attachment = [
                'path' => $giftContext['asset_path'],
                'mime_type' => 'application/vnd.halloparty.gift',
                'name' => $giftContext['gift_name'],
            ];
            $bodyText = trim($bodyText) !== '' ? $bodyText : $giftContext['body_text'];
        } else {
            $attachment = $this->normalizeMessageAttachment(
                $attachmentUpload,
                $attachmentPath,
                $attachmentName
            );
            if ($attachment !== null && $messageType === 'text') {
                $messageType = str_starts_with((string) $attachment['mime_type'], 'image/')
                    ? 'image'
                    : 'voice';
            }
        }
        $bodyText = $this->normalizeMessageBody($bodyText, $messageType);

        $preview = $this->previewForMessage($messageType, $bodyText);

        $now = $this->now();
        $timeLabel = gmdate('H:i');

        $this->insertMessage(
            $threadId,
            'outgoing',
            $this->displayNameForUser($user),
            $bodyText,
            $messageType,
            $timeLabel,
            $now,
            $attachment
        );

        $this->updateThreadPreview(
            $threadId,
            previewText: $preview['text'],
            messageDateLabel: gmdate('m/d/y'),
            readStyle: 'double',
            unreadCount: 0,
            isPhotoPreview: $preview['is_photo']
        );

        if ((string) $thread['thread_type'] === 'direct' && !empty($thread['target_user_id'])) {
            $targetUser = $this->findUserById((int) $thread['target_user_id']);
            if ($targetUser !== null) {
                $recipientThread = $this->ensureDirectThread(
                    (int) $targetUser['id'],
                    $user,
                    previewText: $preview['text']
                );
                $this->insertMessage(
                    (int) $recipientThread['id'],
                    'incoming',
                    $this->displayNameForUser($user),
                    $bodyText,
                    $messageType,
                    $timeLabel,
                    $now,
                    $attachment
                );

                $this->updateThreadPreview(
                    (int) $recipientThread['id'],
                    previewText: $preview['text'],
                    messageDateLabel: gmdate('m/d/y'),
                    readStyle: 'single',
                    unreadCount: ((int) $recipientThread['unread_count']) + 1,
                    isPhotoPreview: $preview['is_photo']
                );
            }
        }

        if ((string) $thread['thread_type'] === 'support') {
            $replyText = 'تم استلام رسالتك وسنراجعها في أقرب وقت.';
            $this->insertMessage(
                $threadId,
                'incoming',
                'خدمه العملاء',
                $replyText,
                'text',
                gmdate('H:i'),
                $this->now()
            );

            $this->updateThreadPreview(
                $threadId,
                previewText: $replyText,
                messageDateLabel: gmdate('m/d/y'),
                readStyle: 'single',
                unreadCount: 1,
                isPhotoPreview: false
            );
        }

        return $this->conversation($threadId, $authorizationHeader);
    }

    public function startDirectThread(int $targetUserId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $this->ensureChatTargetUserSchema();
        $this->ensureDefaults((int) $user['id']);

        if ($targetUserId < 1 || $targetUserId === (int) $user['id']) {
            throw new ApiException('Invalid chat target.', 422);
        }

        $targetUser = $this->findUserById($targetUserId);
        if ($targetUser === null || (string) $targetUser['status'] !== 'active') {
            throw new ApiException('User not found.', 404);
        }

        if (!$this->canDirectMessage((int) $user['id'], (int) $targetUser['id'])) {
            throw new ApiException('This user does not accept direct messages.', 403);
        }

        $thread = $this->ensureDirectThread((int) $user['id'], $targetUser);

        return $this->conversation((int) $thread['id'], $authorizationHeader);
    }

    public function search(string $query, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $this->ensureChatTargetUserSchema();
        $this->ensureDefaults((int) $user['id']);

        $query = trim($query);
        if ($query === '') {
            $query = 'Mo';
        }

        $recent = $this->listSearchHistory((int) $user['id']);

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM chat_threads
             WHERE owner_user_id = :owner_user_id
               AND is_deleted = 0
               AND (title LIKE :search OR preview_text LIKE :search)
             ORDER BY updated_at DESC, id DESC
             LIMIT 10'
        );
        $statement->execute([
            'owner_user_id' => (int) $user['id'],
            'search' => '%' . $query . '%',
        ]);

        return [
            'query' => $query,
            'recent_searches' => $recent,
            'results' => array_map(
                fn (array $thread): array => $this->mapThread($thread),
                $statement->fetchAll() ?: []
            ),
        ];
    }

    public function deleteSearch(int $searchId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $statement = $this->pdo->prepare(
            'DELETE FROM chat_search_history
             WHERE id = :id AND user_id = :user_id'
        );
        $statement->execute([
            'id' => $searchId,
            'user_id' => (int) $user['id'],
        ]);

        return [
            'recent_searches' => $this->listSearchHistory((int) $user['id']),
        ];
    }

    public function rememberSearch(
        string $label,
        ?int $threadId,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $label = trim($label);

        if ($label === '') {
            throw new ApiException('Search label is required.', 422);
        }

        $delete = $this->pdo->prepare(
            'DELETE FROM chat_search_history
             WHERE user_id = :user_id AND label = :label'
        );
        $delete->execute([
            'user_id' => (int) $user['id'],
            'label' => $label,
        ]);

        $insert = $this->pdo->prepare(
            'INSERT INTO chat_search_history
                (user_id, label, target_thread_id, created_at)
             VALUES
                (:user_id, :label, :target_thread_id, :created_at)'
        );
        $insert->execute([
            'user_id' => (int) $user['id'],
            'label' => $label,
            'target_thread_id' => $threadId,
            'created_at' => $this->now(),
        ]);

        $trimIds = $this->pdo->prepare(
            'SELECT id
             FROM chat_search_history
             WHERE user_id = :user_id
             ORDER BY created_at DESC, id DESC'
        );
        $trimIds->execute(['user_id' => (int) $user['id']]);
        $ids = array_map('intval', array_column($trimIds->fetchAll() ?: [], 'id'));
        if (count($ids) > 10) {
            $staleIds = array_slice($ids, 10);
            $deleteStale = $this->pdo->prepare(
                'DELETE FROM chat_search_history WHERE id = :id'
            );
            foreach ($staleIds as $staleId) {
                $deleteStale->execute(['id' => $staleId]);
            }
        }

        return [
            'recent_searches' => $this->listSearchHistory((int) $user['id']),
        ];
    }

    public function bulkAction(
        array $threadIds,
        string $action,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $action = $action === 'delete' ? 'delete' : 'mark_read';
        $threadIds = array_values(array_unique(array_filter(array_map('intval', $threadIds))));

        if ($threadIds === []) {
            return ['updated_count' => 0];
        }

        $updated = 0;
        foreach ($threadIds as $threadId) {
            $thread = $this->findThread($threadId, (int) $user['id']);
            if ($thread === null) {
                continue;
            }

            if ($action === 'delete') {
                $statement = $this->pdo->prepare(
                    'UPDATE chat_threads
                     SET is_deleted = 1, updated_at = :updated_at
                     WHERE id = :id'
                );
                $statement->execute([
                    'updated_at' => $this->now(),
                    'id' => $threadId,
                ]);
            } else {
                $this->markThreadRead($threadId, (int) $user['id']);
            }

            $updated++;
        }

        return ['updated_count' => $updated];
    }

    public function adminThreadStats(): array
    {
        return [
            'threads' => (int) $this->pdo->query(
                'SELECT COUNT(*) FROM chat_threads WHERE is_deleted = 0'
            )->fetchColumn(),
            'unread_threads' => (int) $this->pdo->query(
                'SELECT COUNT(*) FROM chat_threads WHERE is_deleted = 0 AND unread_count > 0'
            )->fetchColumn(),
            'messages' => (int) $this->pdo->query(
                'SELECT COUNT(*) FROM chat_messages'
            )->fetchColumn(),
        ];
    }

    public function adminListThreads(
        string $search = '',
        string $group = 'all',
        string $status = 'all'
    ): array {
        $conditions = ['chat_threads.is_deleted = 0'];
        $params = [];

        if ($search !== '') {
            $conditions[] =
                '(chat_threads.title LIKE :search OR chat_threads.preview_text LIKE :search OR users.nickname LIKE :search OR users.email LIKE :search)';
            $params['search'] = '%' . trim($search) . '%';
        }

        if (in_array($group, ['friends', 'messages'], true)) {
            $conditions[] = 'chat_threads.listing_group = :listing_group';
            $params['listing_group'] = $group;
        }

        if (in_array($status, ['active', 'archived', 'hidden'], true)) {
            $conditions[] = 'chat_threads.status = :status';
            $params['status'] = $status;
        }

        $statement = $this->pdo->prepare(
            'SELECT chat_threads.*,
                    users.nickname AS owner_nickname,
                    users.email AS owner_email
             FROM chat_threads
             LEFT JOIN users ON users.id = chat_threads.owner_user_id
             WHERE ' . implode(' AND ', $conditions) . '
             ORDER BY chat_threads.updated_at DESC, chat_threads.id DESC'
        );
        $statement->execute($params);

        return $statement->fetchAll() ?: [];
    }

    public function adminGetThread(int $threadId): array
    {
        if ($threadId < 1) {
            throw new ApiException('Invalid thread id.', 422);
        }

        $statement = $this->pdo->prepare(
            'SELECT chat_threads.*,
                    users.nickname AS owner_nickname,
                    users.email AS owner_email
             FROM chat_threads
             LEFT JOIN users ON users.id = chat_threads.owner_user_id
             WHERE chat_threads.id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $threadId]);
        $thread = $statement->fetch();

        if ($thread === false) {
            throw new ApiException('Thread not found.', 404);
        }

        return $thread;
    }

    public function adminListMessages(int $threadId): array
    {
        $this->ensureChatMessageMediaSchema();

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM chat_messages
             WHERE thread_id = :thread_id
             ORDER BY id ASC'
        );
        $statement->execute(['thread_id' => $threadId]);

        return $statement->fetchAll() ?: [];
    }

    public function adminSendMessage(
        int $threadId,
        string $bodyText,
        string $senderName = 'Admin Panel'
    ): void {
        $thread = $this->adminGetThread($threadId);
        $this->ensureChatMessageMediaSchema();
        $bodyText = trim($bodyText);

        if ($bodyText === '') {
            throw new ApiException('Message body is required.', 422);
        }

        $this->insertMessage(
            $threadId,
            'incoming',
            $senderName,
            $bodyText,
            'text',
            gmdate('H:i'),
            $this->now()
        );

        $this->updateThreadPreview(
            $threadId,
            previewText: $bodyText,
            messageDateLabel: gmdate('m/d/y'),
            readStyle: 'single',
            unreadCount: ((int) $thread['unread_count']) + 1,
            isPhotoPreview: false
        );
    }

    public function adminUpdateThread(
        int $threadId,
        string $title,
        string $previewText,
        string $avatarAsset,
        string $statusColorHex,
        string $readStyle,
        int $unreadCount,
        string $status
    ): void
    {
        if (!in_array($status, ['active', 'archived', 'hidden'], true)) {
            throw new ApiException('Invalid chat thread status.', 422);
        }

        $title = trim($title);
        $previewText = trim($previewText);
        $avatarAsset = trim($avatarAsset);
        $statusColorHex = trim($statusColorHex);
        $readStyle = trim($readStyle);

        if ($title === '') {
            throw new ApiException('Thread title is required.', 422);
        }

        if ($avatarAsset === '') {
            throw new ApiException('Thread avatar is required.', 422);
        }

        if (!in_array($readStyle, ['none', 'single', 'double'], true)) {
            throw new ApiException('Invalid read style.', 422);
        }

        if ($statusColorHex !== '' && !preg_match('/^#[0-9A-Fa-f]{6}$/', $statusColorHex)) {
            throw new ApiException('Invalid status color.', 422);
        }

        $this->adminGetThread($threadId);

        $statement = $this->pdo->prepare(
            'UPDATE chat_threads
             SET title = :title,
                 preview_text = :preview_text,
                 avatar_asset = :avatar_asset,
                 status_color_hex = :status_color_hex,
                 read_style = :read_style,
                 unread_count = :unread_count,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'title' => $title,
            'preview_text' => $previewText,
            'avatar_asset' => $avatarAsset,
            'status_color_hex' => $statusColorHex !== '' ? $statusColorHex : '#6F7C8F',
            'read_style' => $readStyle,
            'unread_count' => max(0, $unreadCount),
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $threadId,
        ]);
    }

    private function processChatGift(array $thread, array $sender, int $giftId, int $quantity): array
    {
        $this->ensureChatGiftTransactionsSchema();

        if ((string) $thread['thread_type'] !== 'direct') {
            throw new ApiException('الهدايا متاحة في المحادثات الخاصة فقط.', 422);
        }

        if ($giftId < 1) {
            throw new ApiException('Gift is required.', 422);
        }

        if ($quantity < 1 || $quantity > 999) {
            throw new ApiException('Invalid gift quantity.', 422);
        }

        $recipient = $this->resolveChatGiftRecipient($thread, $sender);
        if ($recipient !== null && (string) $recipient['status'] !== 'active') {
            $recipient = null;
        }

        $gift = $this->findGiftById($giftId);
        if ($gift === null || (string) $gift['status'] !== 'active') {
            throw new ApiException('Gift not found.', 404);
        }

        $senderUserId = (int) $sender['id'];
        $recipientUserId = $recipient === null ? 0 : (int) $recipient['id'];
        $this->createWalletForUser($senderUserId);
        $wallet = $this->walletRowForUser($senderUserId);
        $unitPrice = (int) $gift['price_coins'];
        $totalPrice = $unitPrice * $quantity;

        if ((int) $wallet['coins_balance'] < $totalPrice) {
            throw new ApiException('Insufficient coin balance.', 422);
        }

        $commissionPercent = $this->giftPlatformCommissionPercent();
        $earnings = $this->calculateGiftEarnings(
            $totalPrice,
            $commissionPercent,
            $recipientUserId,
            $senderUserId
        );
        $now = $this->now();

        $this->pdo->beginTransaction();

        try {
            $updateWallet = $this->pdo->prepare(
                'UPDATE user_wallets
                 SET coins_balance = coins_balance - :amount, updated_at = :updated_at
                 WHERE user_id = :user_id'
            );
            $updateWallet->execute([
                'amount' => $totalPrice,
                'updated_at' => $now,
                'user_id' => $senderUserId,
            ]);

            $insertGift = $this->pdo->prepare(
                'INSERT INTO chat_gift_transactions
                    (thread_id, sender_user_id, sender_name, sender_avatar_asset, recipient_user_id, recipient_name_snapshot, gift_id, gift_name_snapshot, quantity, unit_price_coins, total_price_coins, platform_fee_coins, creator_earning_diamonds, platform_commission_percent, created_at)
                 VALUES
                    (:thread_id, :sender_user_id, :sender_name, :sender_avatar_asset, :recipient_user_id, :recipient_name_snapshot, :gift_id, :gift_name_snapshot, :quantity, :unit_price_coins, :total_price_coins, :platform_fee_coins, :creator_earning_diamonds, :platform_commission_percent, :created_at)'
            );
            $insertGift->execute([
                'thread_id' => (int) $thread['id'],
                'sender_user_id' => $senderUserId,
                'sender_name' => $this->displayNameForUser($sender),
                'sender_avatar_asset' => (string) ($sender['avatar_asset'] ?: self::DEFAULT_AVATAR),
                'recipient_user_id' => $recipientUserId > 0 ? $recipientUserId : null,
                'recipient_name_snapshot' => $recipient === null
                    ? 'محادثة'
                    : $this->displayNameForUser($recipient),
                'gift_id' => $giftId,
                'gift_name_snapshot' => (string) $gift['name'],
                'quantity' => $quantity,
                'unit_price_coins' => $unitPrice,
                'total_price_coins' => $totalPrice,
                'platform_fee_coins' => $earnings['platform_fee_coins'],
                'creator_earning_diamonds' => $earnings['creator_earning_diamonds'],
                'platform_commission_percent' => $commissionPercent,
                'created_at' => $now,
            ]);
            $transactionId = (int) $this->pdo->lastInsertId();

            $insertWalletTransaction = $this->pdo->prepare(
                'INSERT INTO wallet_transactions
                    (user_id, wallet_type, direction, amount, status, title, subtitle, context_type, context_ref, created_at)
                 VALUES
                    (:user_id, :wallet_type, :direction, :amount, :status, :title, :subtitle, :context_type, :context_ref, :created_at)'
            );
            $insertWalletTransaction->execute([
                'user_id' => $senderUserId,
                'wallet_type' => 'coins',
                'direction' => 'out',
                'amount' => $totalPrice,
                'status' => 'success',
                'title' => 'إرسال هدية في الشات',
                'subtitle' => (string) $gift['name'] . ' x' . $quantity,
                'context_type' => 'chat_gift',
                'context_ref' => (string) $transactionId,
                'created_at' => $now,
            ]);

            if ($earnings['creator_earning_diamonds'] > 0) {
                $this->creditGiftRecipient(
                    $recipientUserId,
                    $earnings['creator_earning_diamonds'],
                    'ربح هدية شات',
                    (string) $gift['name'] . ' من ' . $this->displayNameForUser($sender),
                    'chat_gift_earning',
                    $transactionId
                );
            }

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'gift_name' => (string) $gift['name'],
            'asset_path' => (string) $gift['asset_path'],
            'body_text' => 'أرسل ' . (string) $gift['name'] . ' x' . $quantity,
        ];
    }

    private function findGiftById(int $giftId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM gifts WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $giftId]);
        $gift = $statement->fetch();

        return $gift === false ? null : $gift;
    }

    private function resolveChatGiftRecipient(array $thread, array $sender): ?array
    {
        if (!empty($thread['target_user_id'])) {
            return $this->findUserById((int) $thread['target_user_id']);
        }

        $threadKey = (string) ($thread['thread_key'] ?? '');
        if (preg_match('/(?:direct|friend)-user-(\d+)/', $threadKey, $matches) === 1) {
            $user = $this->findUserById((int) $matches[1]);
            if ($user !== null && (int) $user['id'] !== (int) $sender['id']) {
                return $user;
            }
        }

        $title = trim((string) ($thread['title'] ?? ''));
        if ($title !== '') {
            $statement = $this->pdo->prepare(
                'SELECT *
                 FROM users
                 WHERE id != :sender_user_id
                   AND status = "active"
                   AND (nickname = :title OR email = :title OR phone = :title)
                 ORDER BY id ASC
                 LIMIT 1'
            );
            $statement->execute([
                'sender_user_id' => (int) $sender['id'],
                'title' => $title,
            ]);
            $user = $statement->fetch();
            if ($user !== false) {
                $this->attachThreadTarget((int) $thread['id'], (int) $user['id']);
                return $user;
            }
        }

        return null;
    }

    private function attachThreadTarget(int $threadId, int $targetUserId): void
    {
        try {
            $statement = $this->pdo->prepare(
                'UPDATE chat_threads
                 SET target_user_id = :target_user_id, updated_at = :updated_at
                 WHERE id = :id AND target_user_id IS NULL'
            );
            $statement->execute([
                'target_user_id' => $targetUserId,
                'updated_at' => $this->now(),
                'id' => $threadId,
            ]);
        } catch (Throwable) {
        }
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
            throw new ApiException('Wallet not found.', 500);
        }

        return $wallet;
    }

    private function createWalletForUser(int $userId): void
    {
        $now = $this->now();
        $statement = $this->pdo->prepare(
            'INSERT IGNORE INTO user_wallets
                (user_id, coins_balance, diamonds_balance, created_at, updated_at)
             VALUES
                (:user_id, 1235, 5, :created_at, :updated_at)'
        );
        $statement->execute([
            'user_id' => $userId,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
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

    private function listThreads(int $ownerUserId, string $listingGroup, bool $isSystem): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM chat_threads
             WHERE owner_user_id = :owner_user_id
               AND listing_group = :listing_group
               AND is_system = :is_system
               AND is_deleted = 0
               AND status != "hidden"
             ORDER BY display_order ASC, updated_at DESC, id DESC'
        );
        $statement->execute([
            'owner_user_id' => $ownerUserId,
            'listing_group' => $listingGroup,
            'is_system' => $isSystem ? 1 : 0,
        ]);

        return array_map(
            fn (array $thread): array => $this->mapThread($thread),
            $statement->fetchAll() ?: []
        );
    }

    private function listMessages(int $threadId): array
    {
        $this->ensureChatMessageMediaSchema();

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM chat_messages
             WHERE thread_id = :thread_id
             ORDER BY id ASC'
        );
        $statement->execute(['thread_id' => $threadId]);

        return array_map(
            fn (array $message): array => $this->mapMessage($message),
            $statement->fetchAll() ?: []
        );
    }

    private function listSearchHistory(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM chat_search_history
             WHERE user_id = :user_id
             ORDER BY created_at DESC, id DESC
             LIMIT 10'
        );
        $statement->execute(['user_id' => $userId]);

        return array_map(
            static fn (array $row): array => [
                'id' => (int) $row['id'],
                'label' => (string) $row['label'],
                'target_thread_id' => $row['target_thread_id'] === null
                    ? null
                    : (int) $row['target_thread_id'],
            ],
            $statement->fetchAll() ?: []
        );
    }

    private function mapThread(array $thread): array
    {
        return [
            'id' => (int) $thread['id'],
            'listing_group' => (string) $thread['listing_group'],
            'thread_type' => (string) $thread['thread_type'],
            'title' => (string) $thread['title'],
            'preview_text' => (string) $thread['preview_text'],
            'avatar_asset' => (string) $thread['avatar_asset'],
            'status_color_hex' => (string) $thread['status_color_hex'],
            'read_style' => (string) $thread['read_style'],
            'is_photo_preview' => (int) $thread['is_photo_preview'] === 1,
            'message_date_label' => (string) $thread['message_date_label'],
            'unread_count' => (int) $thread['unread_count'],
            'is_system' => (int) $thread['is_system'] === 1,
            'status' => (string) $thread['status'],
            'target_user_id' => isset($thread['target_user_id']) && $thread['target_user_id'] !== null
                ? (int) $thread['target_user_id']
                : null,
        ];
    }

    private function mapMessage(array $message): array
    {
        return [
            'id' => (int) $message['id'],
            'direction' => (string) $message['direction'],
            'sender_name' => (string) $message['sender_name'],
            'body_text' => (string) $message['body_text'],
            'message_type' => (string) $message['message_type'],
            'attachment_path' => isset($message['attachment_path']) && $message['attachment_path'] !== null
                ? (string) $message['attachment_path']
                : null,
            'attachment_mime_type' => isset($message['attachment_mime_type']) && $message['attachment_mime_type'] !== null
                ? (string) $message['attachment_mime_type']
                : null,
            'attachment_name' => isset($message['attachment_name']) && $message['attachment_name'] !== null
                ? (string) $message['attachment_name']
                : null,
            'time_label' => (string) $message['time_label'],
            'created_at_label' => $this->relativeTime((string) $message['created_at']),
        ];
    }

    private function ensureDefaults(int $ownerUserId): void
    {
        $this->ensureChatTargetUserSchema();
        $this->ensureChatMessageMediaSchema();
        $statement = $this->pdo->prepare(
            'SELECT COUNT(*) FROM chat_threads WHERE owner_user_id = :owner_user_id'
        );
        $statement->execute(['owner_user_id' => $ownerUserId]);
        if ((int) $statement->fetchColumn() > 0) {
            return;
        }

        $threadIds = [];
        $threadIds['friends-1'] = $this->seedThread(
            $ownerUserId,
            'friends-1',
            'friends',
            'direct',
            'محمد احمد',
            '',
            self::DEFAULT_AVATAR,
            '#EA4335',
            'single',
            false,
            false,
            '11/16/19',
            1,
            [
                ['incoming', 'Good bye!', '17:47'],
                ['outgoing', 'Good morning!', '10:10'],
                ['incoming', 'Do you know what time is it?', '11:40'],
                ['outgoing', 'It’s morning in Egypt 😎', '11:43'],
            ]
        );
        $threadIds['friends-2'] = $this->seedThread(
            $ownerUserId,
            'friends-2',
            'friends',
            'direct',
            'محمد احمد',
            'كيف حالك يارب ان تكون بخير ؟؟',
            self::DEFAULT_AVATAR,
            '#34A853',
            'double',
            false,
            false,
            '11/16/19',
            0,
            [
                ['incoming', 'كيف حالك يارب ان تكون بخير ؟؟', '11:16'],
            ]
        );
        $threadIds['friends-3'] = $this->seedThread(
            $ownerUserId,
            'friends-3',
            'friends',
            'direct',
            'محمد احمد',
            'صورة',
            self::DEFAULT_AVATAR,
            '#34A853',
            'double',
            true,
            false,
            '11/16/19',
            0,
            [
                ['incoming', 'صورة', '11:17'],
            ]
        );
        $threadIds['friends-4'] = $this->seedThread(
            $ownerUserId,
            'friends-4',
            'friends',
            'direct',
            'محمد احمد',
            '',
            self::DEFAULT_AVATAR,
            '#EA4335',
            'single',
            false,
            false,
            '11/16/19',
            1,
            [
                ['incoming', 'مرحباً', '11:18'],
            ]
        );
        $threadIds['friends-5'] = $this->seedThread(
            $ownerUserId,
            'friends-5',
            'friends',
            'direct',
            'محمد احمد',
            'كيف حالك يارب ان تكون بخير ؟؟',
            self::DEFAULT_AVATAR,
            '#34A853',
            'double',
            false,
            false,
            '11/16/19',
            0,
            [
                ['incoming', 'كيف حالك يارب ان تكون بخير ؟؟', '11:19'],
            ]
        );
        $threadIds['friends-6'] = $this->seedThread(
            $ownerUserId,
            'friends-6',
            'friends',
            'direct',
            'محمد احمد',
            'صورة',
            self::DEFAULT_AVATAR,
            '#34A853',
            'double',
            true,
            false,
            '11/16/19',
            0,
            [
                ['incoming', 'صورة', '11:20'],
            ]
        );

        $threadIds['support'] = $this->seedThread(
            $ownerUserId,
            'messages-support',
            'messages',
            'support',
            'خدمه العملاء',
            'اي مشكله واجهتك يرجي تخبرني بتفاصيل',
            self::SUPPORT_AVATAR,
            '#34A853',
            'none',
            false,
            true,
            '',
            0,
            [
                ['incoming', 'اي مشكله واجهتك يرجي تخبرني بتفاصيل', '09:00'],
            ]
        );
        $threadIds['notification'] = $this->seedThread(
            $ownerUserId,
            'messages-notification',
            'messages',
            'notification',
            'الاشعارات',
            'ممكن تعيطي هديه',
            self::NOTIFICATION_AVATAR,
            '#34A853',
            'none',
            false,
            true,
            '',
            0,
            [
                ['incoming', 'ممكن تعيطي هديه', '09:05'],
            ]
        );
        $threadIds['messages-1'] = $this->seedThread(
            $ownerUserId,
            'messages-1',
            'messages',
            'direct',
            'محمد احمد',
            '',
            self::DEFAULT_AVATAR,
            '#EA4335',
            'single',
            false,
            false,
            '11/16/19',
            1,
            [
                ['incoming', 'Good bye!', '17:47'],
                ['outgoing', 'Good morning!', '10:10'],
                ['incoming', 'Do you know what time is it?', '11:40'],
                ['outgoing', 'It’s morning in Egypt 😎', '11:43'],
            ]
        );
        $threadIds['messages-2'] = $this->seedThread(
            $ownerUserId,
            'messages-2',
            'messages',
            'direct',
            'محمد احمد',
            'كيف حالك يارب ان تكون بخير ؟؟',
            self::DEFAULT_AVATAR,
            '#34A853',
            'double',
            false,
            false,
            '11/16/19',
            0,
            [
                ['incoming', 'كيف حالك يارب ان تكون بخير ؟؟', '11:50'],
            ]
        );
        $threadIds['messages-3'] = $this->seedThread(
            $ownerUserId,
            'messages-3',
            'messages',
            'direct',
            'محمد احمد',
            'صورة',
            self::DEFAULT_AVATAR,
            '#34A853',
            'double',
            true,
            false,
            '11/16/19',
            0,
            [
                ['incoming', 'صورة', '11:52'],
            ]
        );

        $searchSeeds = [
            ['Mo', $threadIds['messages-1'] ?? null],
            ['Abdullahman Mohamed', $threadIds['messages-2'] ?? null],
            ['Youssef Sherif', $threadIds['messages-3'] ?? null],
        ];

        $insertSearch = $this->pdo->prepare(
            'INSERT INTO chat_search_history
                (user_id, label, target_thread_id, created_at)
             VALUES
                (:user_id, :label, :target_thread_id, :created_at)'
        );
        foreach ($searchSeeds as [$label, $targetThreadId]) {
            $insertSearch->execute([
                'user_id' => $ownerUserId,
                'label' => $label,
                'target_thread_id' => $targetThreadId,
                'created_at' => $this->now(),
            ]);
        }
    }

    private function ensureFriendThreads(int $ownerUserId): void
    {
        $this->ensureChatTargetUserSchema();
        $friends = $this->friendRows($ownerUserId);
        if ($friends === []) {
            return;
        }

        $findThread = $this->pdo->prepare(
            'SELECT id
             FROM chat_threads
             WHERE owner_user_id = :owner_user_id
               AND thread_key = :thread_key
             LIMIT 1'
        );
        $updateThread = $this->pdo->prepare(
            'UPDATE chat_threads
             SET title = :title,
                 avatar_asset = :avatar_asset,
                 target_user_id = :target_user_id,
                 status = "active",
                 is_deleted = 0,
                 updated_at = :updated_at
             WHERE id = :id'
        );

        foreach ($friends as $friend) {
            $friendId = (int) $friend['id'];
            $threadKey = 'friend-user-' . $friendId;
            $title = $this->displayNameForUser($friend);
            $avatar = (string) (($friend['avatar_asset'] ?? '') ?: self::DEFAULT_AVATAR);

            $findThread->execute([
                'owner_user_id' => $ownerUserId,
                'thread_key' => $threadKey,
            ]);
            $existing = $findThread->fetch();

            if ($existing === false) {
                $this->seedThread(
                    $ownerUserId,
                    $threadKey,
                    'friends',
                    'direct',
                    $title,
                    'أصبحتم أصدقاء الآن',
                    $avatar,
                    '#34A853',
                    'none',
                    false,
                    false,
                    gmdate('m/d/y'),
                    0,
                    [
                        ['incoming', 'أصبحتم أصدقاء الآن', gmdate('H:i')],
                    ],
                    $friendId
                );
                continue;
            }

            $updateThread->execute([
                'title' => $title,
                'avatar_asset' => $avatar,
                'target_user_id' => $friendId,
                'updated_at' => $this->now(),
                'id' => (int) $existing['id'],
            ]);
        }
    }

    private function listFriendThreads(int $ownerUserId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT chat_threads.*
             FROM chat_threads
             INNER JOIN user_follows outgoing
                ON outgoing.follower_user_id = :owner_user_id
               AND outgoing.followed_user_id = chat_threads.target_user_id
               AND outgoing.status = "active"
             INNER JOIN user_follows incoming
                ON incoming.follower_user_id = chat_threads.target_user_id
               AND incoming.followed_user_id = :owner_user_id
               AND incoming.status = "active"
             WHERE chat_threads.owner_user_id = :owner_user_id
               AND chat_threads.listing_group = "friends"
               AND chat_threads.is_system = 0
               AND chat_threads.is_deleted = 0
               AND chat_threads.status = "active"
               AND chat_threads.target_user_id IS NOT NULL
             ORDER BY chat_threads.updated_at DESC, chat_threads.id DESC'
        );
        $statement->execute(['owner_user_id' => $ownerUserId]);

        return array_map(
            fn (array $thread): array => $this->mapThread($thread),
            $statement->fetchAll() ?: []
        );
    }

    private function ensureDirectThread(
        int $ownerUserId,
        array $targetUser,
        string $previewText = ''
    ): array {
        $this->ensureChatTargetUserSchema();
        $targetUserId = (int) $targetUser['id'];
        $threadKey = 'direct-user-' . $targetUserId;
        $title = $this->displayNameForUser($targetUser);
        $avatar = (string) (($targetUser['avatar_asset'] ?? '') ?: self::DEFAULT_AVATAR);

        $findThread = $this->pdo->prepare(
            'SELECT *
             FROM chat_threads
             WHERE owner_user_id = :owner_user_id
               AND thread_key = :thread_key
             LIMIT 1'
        );
        $findThread->execute([
            'owner_user_id' => $ownerUserId,
            'thread_key' => $threadKey,
        ]);
        $existing = $findThread->fetch();

        if ($existing !== false) {
            $updateThread = $this->pdo->prepare(
                'UPDATE chat_threads
                 SET target_user_id = :target_user_id,
                     listing_group = "messages",
                     thread_type = "direct",
                     title = :title,
                     avatar_asset = :avatar_asset,
                     status = "active",
                     is_deleted = 0,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $updateThread->execute([
                'target_user_id' => $targetUserId,
                'title' => $title,
                'avatar_asset' => $avatar,
                'updated_at' => $this->now(),
                'id' => (int) $existing['id'],
            ]);

            return $this->requireThread((int) $existing['id'], $ownerUserId);
        }

        $threadId = $this->seedThread(
            $ownerUserId,
            $threadKey,
            'messages',
            'direct',
            $title,
            $previewText,
            $avatar,
            '#34A853',
            'none',
            false,
            false,
            $previewText === '' ? '' : gmdate('m/d/y'),
            0,
            [],
            $targetUserId
        );

        return $this->requireThread($threadId, $ownerUserId);
    }

    private function friendRows(int $ownerUserId): array
    {
        try {
            $statement = $this->pdo->prepare(
                'SELECT users.*
                 FROM user_follows outgoing
                 INNER JOIN user_follows incoming
                    ON incoming.follower_user_id = outgoing.followed_user_id
                   AND incoming.followed_user_id = outgoing.follower_user_id
                   AND incoming.status = "active"
                 INNER JOIN users ON users.id = outgoing.followed_user_id
                 WHERE outgoing.follower_user_id = :owner_user_id
                   AND outgoing.status = "active"
                   AND users.status = "active"
                 ORDER BY outgoing.created_at DESC, users.id DESC'
            );
            $statement->execute(['owner_user_id' => $ownerUserId]);

            return $statement->fetchAll() ?: [];
        } catch (Throwable) {
            return [];
        }
    }

    private function seedThread(
        int $ownerUserId,
        string $threadKey,
        string $listingGroup,
        string $threadType,
        string $title,
        string $previewText,
        string $avatarAsset,
        string $statusColorHex,
        string $readStyle,
        bool $isPhotoPreview,
        bool $isSystem,
        string $messageDateLabel,
        int $unreadCount,
        array $messages,
        ?int $targetUserId = null
    ): int {
        $createdAt = $this->now();

        $threadInsert = $this->pdo->prepare(
            'INSERT INTO chat_threads
                (owner_user_id, target_user_id, thread_key, listing_group, thread_type, title, preview_text, avatar_asset,
                 status_color_hex, read_style, is_photo_preview, unread_count, is_system, status,
                 display_order, message_date_label, created_at, updated_at)
             VALUES
                (:owner_user_id, :target_user_id, :thread_key, :listing_group, :thread_type, :title, :preview_text, :avatar_asset,
                 :status_color_hex, :read_style, :is_photo_preview, :unread_count, :is_system, :status,
                 :display_order, :message_date_label, :created_at, :updated_at)'
        );
        $threadInsert->execute([
            'owner_user_id' => $ownerUserId,
            'target_user_id' => $targetUserId,
            'thread_key' => $threadKey,
            'listing_group' => $listingGroup,
            'thread_type' => $threadType,
            'title' => $title,
            'preview_text' => $previewText,
            'avatar_asset' => $avatarAsset,
            'status_color_hex' => $statusColorHex,
            'read_style' => $readStyle,
            'is_photo_preview' => $isPhotoPreview ? 1 : 0,
            'unread_count' => $unreadCount,
            'is_system' => $isSystem ? 1 : 0,
            'status' => 'active',
            'display_order' => $this->threadDisplayOrder($threadKey),
            'message_date_label' => $messageDateLabel,
            'created_at' => $createdAt,
            'updated_at' => $createdAt,
        ]);

        $threadId = (int) $this->pdo->lastInsertId();

        foreach ($messages as [$direction, $bodyText, $timeLabel]) {
            $this->insertMessage(
                $threadId,
                $direction,
                $direction === 'outgoing' ? 'المستخدم الحالي' : $title,
                $bodyText,
                $bodyText === 'صورة' ? 'image' : 'text',
                $timeLabel,
                $createdAt
            );
        }

        return $threadId;
    }

    private function threadDisplayOrder(string $threadKey): int
    {
        return match ($threadKey) {
            'friends-1' => 1,
            'friends-2' => 2,
            'friends-3' => 3,
            'friends-4' => 4,
            'friends-5' => 5,
            'friends-6' => 6,
            'messages-support' => 1,
            'messages-notification' => 2,
            'messages-1' => 3,
            'messages-2' => 4,
            'messages-3' => 5,
            default => 99,
        };
    }

    private function insertMessage(
        int $threadId,
        string $direction,
        string $senderName,
        string $bodyText,
        string $messageType,
        string $timeLabel,
        string $createdAt,
        ?array $attachment = null
    ): void {
        $this->ensureChatMessageMediaSchema();

        $statement = $this->pdo->prepare(
            'INSERT INTO chat_messages
                (thread_id, direction, sender_name, body_text, message_type,
                 attachment_path, attachment_mime_type, attachment_name, time_label, created_at)
             VALUES
                (:thread_id, :direction, :sender_name, :body_text, :message_type,
                 :attachment_path, :attachment_mime_type, :attachment_name, :time_label, :created_at)'
        );
        $statement->execute([
            'thread_id' => $threadId,
            'direction' => $direction,
            'sender_name' => $senderName,
            'body_text' => $bodyText,
            'message_type' => $messageType,
            'attachment_path' => $attachment['path'] ?? null,
            'attachment_mime_type' => $attachment['mime_type'] ?? null,
            'attachment_name' => $attachment['name'] ?? null,
            'time_label' => $timeLabel,
            'created_at' => $createdAt,
        ]);
    }

    private function normalizeMessageType(string $messageType): string
    {
        $messageType = strtolower(trim($messageType));
        if ($messageType === '') {
            return 'text';
        }

        if (!in_array($messageType, self::MESSAGE_TYPES, true)) {
            throw new ApiException('Unsupported message type.', 422);
        }

        return $messageType;
    }

    private function normalizeMessageBody(string $bodyText, string $messageType): string
    {
        $bodyText = trim($bodyText);

        if ($bodyText === '') {
            $bodyText = match ($messageType) {
                'image' => 'صورة',
                'gift' => 'أرسل هدية 🎁',
                'voice' => 'رسالة صوتية',
                default => '',
            };
        }

        if ($bodyText === '') {
            throw new ApiException('Message body is required.', 422);
        }

        if (mb_strlen($bodyText) > 2000) {
            throw new ApiException('Message body is too long.', 422);
        }

        return $bodyText;
    }

    private function previewForMessage(string $messageType, string $bodyText): array
    {
        return match ($messageType) {
            'image' => ['text' => 'صورة', 'is_photo' => true],
            'gift' => ['text' => $bodyText !== '' ? $bodyText : 'هدية', 'is_photo' => false],
            'voice' => ['text' => 'رسالة صوتية', 'is_photo' => false],
            default => ['text' => $bodyText, 'is_photo' => false],
        };
    }

    private function normalizeMessageAttachment(
        ?array $attachmentUpload,
        ?string $attachmentPath,
        ?string $attachmentName
    ): ?array {
        if ($attachmentUpload !== null) {
            return $this->storeMessageAttachment($attachmentUpload);
        }

        $attachmentPath = trim((string) $attachmentPath);
        if ($attachmentPath === '') {
            return null;
        }

        return [
            'path' => $attachmentPath,
            'mime_type' => null,
            'name' => trim((string) $attachmentName) ?: basename($attachmentPath),
        ];
    }

    private function storeMessageAttachment(array $draft): array
    {
        $fileName = trim((string) ($draft['filename'] ?? 'chat-attachment'));
        $mimeType = strtolower(trim((string) ($draft['mime_type'] ?? 'image/jpeg')));
        $content = trim((string) ($draft['content_base64'] ?? ''));

        if ($content === '') {
            throw new ApiException('Invalid chat attachment.', 422);
        }

        if (!in_array($mimeType, [
            'image/png',
            'image/jpeg',
            'image/jpg',
            'image/webp',
            'audio/mpeg',
            'audio/mp3',
            'audio/mp4',
            'audio/aac',
            'audio/webm',
            'audio/wav',
        ], true)) {
            throw new ApiException('Unsupported chat attachment type.', 422);
        }

        $decoded = base64_decode($content, true);
        if ($decoded === false || $decoded === '') {
            throw new ApiException('Invalid chat attachment payload.', 422);
        }

        if (strlen($decoded) > 8 * 1024 * 1024) {
            throw new ApiException('Chat attachment is too large.', 422);
        }

        $extension = match ($mimeType) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            'audio/mpeg', 'audio/mp3' => 'mp3',
            'audio/mp4' => 'm4a',
            'audio/aac' => 'aac',
            'audio/webm' => 'webm',
            'audio/wav' => 'wav',
            default => 'jpg',
        };

        $directory = dirname(__DIR__) . '/storage/chat';
        if (!is_dir($directory) && !mkdir($directory, 0777, true) && !is_dir($directory)) {
            throw new ApiException('Failed to create chat storage directory.', 500);
        }

        $safeName = preg_replace('/[^a-zA-Z0-9_\-]/', '-', pathinfo($fileName, PATHINFO_FILENAME)) ?: 'chat';
        $relativePath = '/storage/chat/' . $safeName . '-' . bin2hex(random_bytes(6)) . '.' . $extension;
        $absolutePath = dirname(__DIR__) . $relativePath;

        if (file_put_contents($absolutePath, $decoded) === false) {
            throw new ApiException('Failed to store chat attachment.', 500);
        }

        return [
            'path' => $relativePath,
            'mime_type' => $mimeType,
            'name' => $fileName,
        ];
    }

    private function updateThreadPreview(
        int $threadId,
        string $previewText,
        string $messageDateLabel,
        string $readStyle,
        int $unreadCount,
        bool $isPhotoPreview
    ): void {
        $statement = $this->pdo->prepare(
            'UPDATE chat_threads
             SET preview_text = :preview_text,
                 message_date_label = :message_date_label,
                 read_style = :read_style,
                 unread_count = :unread_count,
                 is_photo_preview = :is_photo_preview,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'preview_text' => $previewText,
            'message_date_label' => $messageDateLabel,
            'read_style' => $readStyle,
            'unread_count' => max(0, $unreadCount),
            'is_photo_preview' => $isPhotoPreview ? 1 : 0,
            'updated_at' => $this->now(),
            'id' => $threadId,
        ]);
    }

    private function markThreadRead(int $threadId, int $ownerUserId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE chat_threads
             SET unread_count = 0,
                 read_style = CASE
                     WHEN read_style = "none" THEN "none"
                     ELSE "double"
                 END,
                 updated_at = :updated_at
             WHERE id = :id AND owner_user_id = :owner_user_id'
        );
        $statement->execute([
            'updated_at' => $this->now(),
            'id' => $threadId,
            'owner_user_id' => $ownerUserId,
        ]);
    }

    private function requireThread(int $threadId, int $ownerUserId): array
    {
        $thread = $this->findThread($threadId, $ownerUserId);
        if ($thread === null) {
            throw new ApiException('Chat thread not found.', 404);
        }

        return $thread;
    }

    private function findThread(int $threadId, int $ownerUserId): ?array
    {
        if ($threadId < 1) {
            return null;
        }

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM chat_threads
             WHERE id = :id
               AND owner_user_id = :owner_user_id
               AND is_deleted = 0
             LIMIT 1'
        );
        $statement->execute([
            'id' => $threadId,
            'owner_user_id' => $ownerUserId,
        ]);
        $thread = $statement->fetch();

        return $thread === false ? null : $thread;
    }

    private function findUserById(int $userId): ?array
    {
        if ($userId < 1) {
            return null;
        }

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

    private function canDirectMessage(int $viewerUserId, int $targetUserId): bool
    {
        try {
            $settings = $this->pdo->prepare(
                'SELECT allow_direct_messages
                 FROM user_settings
                 WHERE user_id = :user_id
                 LIMIT 1'
            );
            $settings->execute(['user_id' => $targetUserId]);
            $row = $settings->fetch();
            if ($row === false || (int) $row['allow_direct_messages'] === 1) {
                return true;
            }

            return $this->areFriends($viewerUserId, $targetUserId);
        } catch (Throwable) {
            return true;
        }
    }

    private function areFriends(int $firstUserId, int $secondUserId): bool
    {
        try {
            $statement = $this->pdo->prepare(
                'SELECT COUNT(*)
                 FROM user_follows outgoing
                 INNER JOIN user_follows incoming
                    ON incoming.follower_user_id = outgoing.followed_user_id
                   AND incoming.followed_user_id = outgoing.follower_user_id
                   AND incoming.status = "active"
                 WHERE outgoing.follower_user_id = :first_user_id
                   AND outgoing.followed_user_id = :second_user_id
                   AND outgoing.status = "active"'
            );
            $statement->execute([
                'first_user_id' => $firstUserId,
                'second_user_id' => $secondUserId,
            ]);

            return (int) $statement->fetchColumn() > 0;
        } catch (Throwable) {
            return false;
        }
    }

    private function ensureChatTargetUserSchema(): void
    {
        try {
            $statement = $this->pdo->query("SHOW COLUMNS FROM chat_threads LIKE 'target_user_id'");
            if ($statement !== false && $statement->fetch() !== false) {
                return;
            }

            $this->pdo->exec(
                'ALTER TABLE chat_threads
                 ADD COLUMN target_user_id INT UNSIGNED NULL AFTER owner_user_id'
            );
        } catch (Throwable) {
        }
    }

    private function ensureChatMessageMediaSchema(): void
    {
        $columns = [
            'attachment_path' => 'ALTER TABLE chat_messages ADD COLUMN attachment_path VARCHAR(255) NULL AFTER message_type',
            'attachment_mime_type' => 'ALTER TABLE chat_messages ADD COLUMN attachment_mime_type VARCHAR(120) NULL AFTER attachment_path',
            'attachment_name' => 'ALTER TABLE chat_messages ADD COLUMN attachment_name VARCHAR(190) NULL AFTER attachment_mime_type',
        ];

        foreach ($columns as $column => $sql) {
            try {
                $statement = $this->pdo->query("SHOW COLUMNS FROM chat_messages LIKE '" . $column . "'");
                if ($statement !== false && $statement->fetch() !== false) {
                    continue;
                }

                $this->pdo->exec($sql);
            } catch (Throwable) {
            }
        }
    }

    private function ensureChatGiftTransactionsSchema(): void
    {
        try {
            $this->pdo->exec(
                'CREATE TABLE IF NOT EXISTS chat_gift_transactions (
                    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                    thread_id INT UNSIGNED NOT NULL,
                    sender_user_id INT UNSIGNED NULL,
                    sender_name VARCHAR(190) NOT NULL,
                    sender_avatar_asset VARCHAR(255) NULL,
                    recipient_user_id INT UNSIGNED NULL,
                    recipient_name_snapshot VARCHAR(190) NULL,
                    gift_id INT UNSIGNED NOT NULL,
                    gift_name_snapshot VARCHAR(190) NOT NULL,
                    quantity INT NOT NULL DEFAULT 1,
                    unit_price_coins INT NOT NULL DEFAULT 10,
                    total_price_coins INT NOT NULL DEFAULT 10,
                    platform_fee_coins INT NOT NULL DEFAULT 0,
                    creator_earning_diamonds INT NOT NULL DEFAULT 0,
                    platform_commission_percent DECIMAL(5,2) NOT NULL DEFAULT 50.00,
                    created_at DATETIME NOT NULL,
                    INDEX idx_chat_gifts_thread (thread_id),
                    INDEX idx_chat_gifts_sender (sender_user_id),
                    INDEX idx_chat_gifts_recipient (recipient_user_id),
                    CONSTRAINT fk_chat_gifts_thread FOREIGN KEY (thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE,
                    CONSTRAINT fk_chat_gifts_sender FOREIGN KEY (sender_user_id) REFERENCES users(id) ON DELETE SET NULL,
                    CONSTRAINT fk_chat_gifts_recipient FOREIGN KEY (recipient_user_id) REFERENCES users(id) ON DELETE SET NULL,
                    CONSTRAINT fk_chat_gifts_gift FOREIGN KEY (gift_id) REFERENCES gifts(id) ON DELETE CASCADE
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
            );
        } catch (Throwable) {
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

    private function displayNameForUser(array $user): string
    {
        $nickname = trim((string) ($user['nickname'] ?? ''));
        if ($nickname !== '') {
            return $nickname;
        }

        $email = trim((string) ($user['email'] ?? ''));
        if ($email !== '') {
            return strstr($email, '@', true) ?: $email;
        }

        return 'User';
    }

    private function relativeTime(string $timestamp): string
    {
        $createdAt = strtotime($timestamp);
        if ($createdAt === false) {
            return 'just now';
        }

        $delta = time() - $createdAt;
        if ($delta < 60) {
            return 'just now';
        }
        if ($delta < 3600) {
            return floor($delta / 60) . ' min ago';
        }
        if ($delta < 86400) {
            return floor($delta / 3600) . ' hours ago';
        }

        return gmdate('M j', $createdAt);
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
