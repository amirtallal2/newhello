<?php

declare(strict_types=1);

final class ReferralService
{
    private const DEFAULT_INVITE_HEADER_ASSET = 'https://api.builder.io/api/v1/image/assets/TEMP/f1efcaf22a2d59f5c185fe2e85fe9f5de0c62ae1?width=750';
    private const DEFAULT_REWARD_CARD_ASSET = 'https://api.builder.io/api/v1/image/assets/TEMP/162d7fea0ddaab2b573d9c5341b8a35a9e02bd54?width=654';
    private const DEFAULT_EMPTY_ASSET = 'https://api.builder.io/api/v1/image/assets/TEMP/db7ce84fd71af7a6e23fb548746556307a630c39?width=136';

    public function __construct(private readonly PDO $pdo)
    {
        $this->ensureSchema();
        $this->seedDefaults();
        $this->backfillInviteCodes();
    }

    public function summary(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];
        $inviteCode = $this->ensureInviteCodeForUser($userId);
        $settings = $this->settings();

        return [
            'user' => [
                'id' => $userId,
                'name' => $this->displayNameForUser($user),
                'avatar_asset' => (string) (($user['avatar_asset'] ?? '') ?: 'assets/images/profile_avatar.png'),
                'invite_code' => $inviteCode,
                'invite_link' => $this->inviteLink($inviteCode, $settings),
            ],
            'settings' => $settings,
            'assets' => [
                'header_asset' => (string) $this->settingValue('referral_header_asset', self::DEFAULT_INVITE_HEADER_ASSET),
                'reward_card_asset' => (string) $this->settingValue('referral_reward_card_asset', self::DEFAULT_REWARD_CARD_ASSET),
                'empty_asset' => (string) $this->settingValue('referral_empty_asset', self::DEFAULT_EMPTY_ASSET),
            ],
            'stats' => $this->statsForUser($userId, $settings),
            'reward_cards' => $this->rewardCards($settings),
            'my_invites' => $this->listMyInvites($userId),
            'reward_transactions' => $this->listRewardTransactions($userId),
            'leaderboard' => $this->leaderboard(),
        ];
    }

    public function registerReferralForNewUser(int $newUserId, string $referralCode): void
    {
        $referralCode = $this->normalizeInviteCode($referralCode);
        if ($newUserId <= 0 || $referralCode === '') {
            $this->ensureInviteCodeForUser($newUserId);
            return;
        }

        $this->ensureInviteCodeForUser($newUserId);
        $inviter = $this->findUserByInviteCode($referralCode);
        if ($inviter === null || (int) $inviter['id'] === $newUserId) {
            return;
        }

        $existing = $this->pdo->prepare(
            'SELECT id FROM user_referrals WHERE invited_user_id = :invited_user_id LIMIT 1'
        );
        $existing->execute(['invited_user_id' => $newUserId]);
        if ($existing->fetch() !== false) {
            return;
        }

        $settings = $this->settings();
        $signupReward = max(0.0, (float) $settings['signup_reward_usd']);
        $now = $this->now();

        $this->pdo->prepare(
            'UPDATE users
             SET referred_by_user_id = :referred_by_user_id,
                 updated_at = :updated_at
             WHERE id = :id'
        )->execute([
            'referred_by_user_id' => (int) $inviter['id'],
            'updated_at' => $now,
            'id' => $newUserId,
        ]);

        $insert = $this->pdo->prepare(
            'INSERT INTO user_referrals
                (inviter_user_id, invited_user_id, invite_code_snapshot, status, signup_reward_usd, recharge_reward_usd, total_reward_usd, registered_at, created_at, updated_at)
             VALUES
                (:inviter_user_id, :invited_user_id, :invite_code_snapshot, :status, :signup_reward_usd, :recharge_reward_usd, :total_reward_usd, :registered_at, :created_at, :updated_at)'
        );
        $insert->execute([
            'inviter_user_id' => (int) $inviter['id'],
            'invited_user_id' => $newUserId,
            'invite_code_snapshot' => $referralCode,
            'status' => 'registered',
            'signup_reward_usd' => $signupReward,
            'recharge_reward_usd' => 0,
            'total_reward_usd' => $signupReward,
            'registered_at' => $now,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        if ($signupReward > 0) {
            $this->insertRewardTransaction(
                (int) $inviter['id'],
                $newUserId,
                'signup',
                $signupReward,
                100,
                'مكافأة تسجيل صديق',
                'تم تسجيل صديق جديد باستخدام كود الدعوة.',
                'available',
                (string) $this->pdo->lastInsertId()
            );
        }
    }

    public function recordRechargeReward(int $rechargedUserId, float $packagePriceUsd): void
    {
        if ($rechargedUserId <= 0 || $packagePriceUsd <= 0) {
            return;
        }

        $user = $this->findUserById($rechargedUserId);
        if ($user === null || empty($user['referred_by_user_id'])) {
            return;
        }

        $settings = $this->settings();
        $directInviterId = (int) $user['referred_by_user_id'];
        $directPercent = max(0.0, min(95.0, (float) $settings['direct_recharge_percent']));
        $this->insertRechargeCommission(
            $directInviterId,
            $rechargedUserId,
            $packagePriceUsd,
            $directPercent,
            'recharge_direct',
            'مكافأة شحن مباشر'
        );

        $directInviter = $this->findUserById($directInviterId);
        if ($directInviter !== null && !empty($directInviter['referred_by_user_id'])) {
            $indirectPercent = max(0.0, min(95.0, (float) $settings['indirect_recharge_percent']));
            $this->insertRechargeCommission(
                (int) $directInviter['referred_by_user_id'],
                $rechargedUserId,
                $packagePriceUsd,
                $indirectPercent,
                'recharge_indirect',
                'مكافأة شحن غير مباشر'
            );
        }
    }

    public function adminStats(): array
    {
        $today = gmdate('Y-m-d 00:00:00');

        return [
            'total_referrals' => (int) $this->pdo->query('SELECT COUNT(*) FROM user_referrals')->fetchColumn(),
            'total_rewards_usd' => (float) $this->pdo->query('SELECT COALESCE(SUM(amount_usd), 0) FROM referral_reward_transactions')->fetchColumn(),
            'today_referrals' => (int) $this->scalar(
                'SELECT COUNT(*) FROM user_referrals WHERE created_at >= :today',
                ['today' => $today]
            ),
            'active_codes' => (int) $this->pdo->query(
                'SELECT COUNT(*) FROM users WHERE invite_code IS NOT NULL AND invite_code != ""'
            )->fetchColumn(),
        ];
    }

    public function adminSettings(): array
    {
        return $this->settings();
    }

    public function adminSaveSettings(array $payload): void
    {
        $settings = [
            'referral_daily_target_usd' => $this->decimalString($payload['daily_target_usd'] ?? '50'),
            'referral_first_withdraw_usd' => $this->decimalString($payload['first_withdraw_usd'] ?? '50'),
            'referral_first_withdraw_days' => (string) max(0, (int) ($payload['first_withdraw_days'] ?? 0)),
            'referral_signup_reward_usd' => $this->decimalString($payload['signup_reward_usd'] ?? '1'),
            'referral_direct_recharge_percent' => $this->decimalString($payload['direct_recharge_percent'] ?? '15'),
            'referral_indirect_recharge_percent' => $this->decimalString($payload['indirect_recharge_percent'] ?? '5'),
            'referral_invite_link_base' => trim((string) ($payload['invite_link_base'] ?? 'https://halloparty.online/invite?code=')),
            'referral_header_asset' => trim((string) ($payload['header_asset'] ?? self::DEFAULT_INVITE_HEADER_ASSET)),
            'referral_reward_card_asset' => trim((string) ($payload['reward_card_asset'] ?? self::DEFAULT_REWARD_CARD_ASSET)),
            'referral_empty_asset' => trim((string) ($payload['empty_asset'] ?? self::DEFAULT_EMPTY_ASSET)),
        ];

        foreach ($settings as $key => $value) {
            $this->upsertSetting($key, $value);
        }
    }

    public function adminListReferrals(string $search, string $status): array
    {
        $search = trim($search);
        $status = trim($status);
        $sql = 'SELECT user_referrals.*,
                       inviter.nickname AS inviter_name,
                       inviter.invite_code AS inviter_code,
                       invited.nickname AS invited_name,
                       invited.email AS invited_email,
                       invited.phone AS invited_phone
                FROM user_referrals
                INNER JOIN users inviter ON inviter.id = user_referrals.inviter_user_id
                LEFT JOIN users invited ON invited.id = user_referrals.invited_user_id
                WHERE 1 = 1';
        $params = [];

        if ($status !== '') {
            $sql .= ' AND user_referrals.status = :status';
            $params['status'] = $status;
        }

        if ($search !== '') {
            $sql .= ' AND (
                inviter.nickname LIKE :search
                OR invited.nickname LIKE :search
                OR invited.email LIKE :search
                OR invited.phone LIKE :search
                OR user_referrals.invite_code_snapshot LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY user_referrals.id DESC LIMIT 150';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll(PDO::FETCH_ASSOC);
    }

    public function adminListRewardTransactions(string $search): array
    {
        $search = trim($search);
        $sql = 'SELECT referral_reward_transactions.*,
                       users.nickname AS user_name,
                       source.nickname AS source_user_name
                FROM referral_reward_transactions
                INNER JOIN users ON users.id = referral_reward_transactions.user_id
                LEFT JOIN users source ON source.id = referral_reward_transactions.source_user_id
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                users.nickname LIKE :search
                OR source.nickname LIKE :search
                OR referral_reward_transactions.title LIKE :search
                OR referral_reward_transactions.context_ref LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY referral_reward_transactions.id DESC LIMIT 150';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll(PDO::FETCH_ASSOC);
    }

    public function adminUpdateReferralStatus(int $referralId, string $status): void
    {
        if ($referralId <= 0) {
            throw new ApiException('Referral not found.', 404);
        }

        $status = in_array($status, ['registered', 'qualified', 'paid', 'rejected'], true)
            ? $status
            : 'registered';

        $statement = $this->pdo->prepare(
            'UPDATE user_referrals
             SET status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $referralId,
        ]);
    }

    public function adminUserReferralSummary(int $userId): array
    {
        $user = $this->findUserById($userId);
        if ($user === null) {
            return [
                'invite_code' => '',
                'invited_count' => 0,
                'rewards_usd' => 0.0,
                'recent_referrals' => [],
            ];
        }

        $inviteCode = $this->ensureInviteCodeForUser($userId);
        return [
            'invite_code' => $inviteCode,
            'invited_count' => (int) $this->scalar(
                'SELECT COUNT(*) FROM user_referrals WHERE inviter_user_id = :user_id',
                ['user_id' => $userId]
            ),
            'rewards_usd' => (float) $this->scalar(
                'SELECT COALESCE(SUM(amount_usd), 0) FROM referral_reward_transactions WHERE user_id = :user_id',
                ['user_id' => $userId]
            ),
            'recent_referrals' => $this->recentReferralsForAdminUser($userId),
        ];
    }

    public function ensureInviteCodeForUser(int $userId): string
    {
        if ($userId <= 0) {
            return '';
        }

        $user = $this->findUserById($userId);
        if ($user === null) {
            return '';
        }

        $current = trim((string) ($user['invite_code'] ?? ''));
        if ($current !== '') {
            return $current;
        }

        $code = $this->generateInviteCode($userId);
        $statement = $this->pdo->prepare(
            'UPDATE users SET invite_code = :invite_code, updated_at = :updated_at WHERE id = :id'
        );
        $statement->execute([
            'invite_code' => $code,
            'updated_at' => $this->now(),
            'id' => $userId,
        ]);

        return $code;
    }

    private function statsForUser(int $userId, array $settings): array
    {
        $today = gmdate('Y-m-d 00:00:00');
        $yesterdayStart = gmdate('Y-m-d 00:00:00', time() - 86400);
        $yesterdayEnd = $today;

        return [
            'daily_target_usd' => (float) $settings['daily_target_usd'],
            'first_withdraw_usd' => (float) $settings['first_withdraw_usd'],
            'first_withdraw_days' => (int) $settings['first_withdraw_days'],
            'today_invites' => (int) $this->scalar(
                'SELECT COUNT(*) FROM user_referrals WHERE inviter_user_id = :user_id AND created_at >= :today',
                ['user_id' => $userId, 'today' => $today]
            ),
            'total_invites' => (int) $this->scalar(
                'SELECT COUNT(*) FROM user_referrals WHERE inviter_user_id = :user_id',
                ['user_id' => $userId]
            ),
            'registered_invites' => (int) $this->scalar(
                'SELECT COUNT(*) FROM user_referrals WHERE inviter_user_id = :user_id AND invited_user_id IS NOT NULL',
                ['user_id' => $userId]
            ),
            'unknown_invites' => 0,
            'yesterday_reward_usd' => (float) $this->scalar(
                'SELECT COALESCE(SUM(amount_usd), 0)
                 FROM referral_reward_transactions
                 WHERE user_id = :user_id AND created_at >= :start AND created_at < :end',
                ['user_id' => $userId, 'start' => $yesterdayStart, 'end' => $yesterdayEnd]
            ),
            'accumulated_reward_usd' => (float) $this->scalar(
                'SELECT COALESCE(SUM(amount_usd), 0)
                 FROM referral_reward_transactions
                 WHERE user_id = :user_id',
                ['user_id' => $userId]
            ),
            'available_reward_usd' => (float) $this->scalar(
                'SELECT COALESCE(SUM(amount_usd), 0)
                 FROM referral_reward_transactions
                 WHERE user_id = :user_id AND status = :status',
                ['user_id' => $userId, 'status' => 'available']
            ),
        ];
    }

    private function rewardCards(array $settings): array
    {
        return [
            [
                'title' => 'مكافأة التعبئة',
                'percent' => (float) $settings['direct_recharge_percent'],
                'description' => 'أرباح مباشرة من شحن الأصدقاء.',
            ],
            [
                'title' => 'مكافأة الشبكة',
                'percent' => (float) $settings['indirect_recharge_percent'],
                'description' => 'أرباح إضافية من شحن أصدقاء أصدقائك.',
            ],
        ];
    }

    private function listMyInvites(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT user_referrals.*,
                    users.nickname,
                    users.profile_handle,
                    users.avatar_asset
             FROM user_referrals
             LEFT JOIN users ON users.id = user_referrals.invited_user_id
             WHERE user_referrals.inviter_user_id = :user_id
             ORDER BY user_referrals.id DESC
             LIMIT 20'
        );
        $statement->execute(['user_id' => $userId]);

        $rows = [];
        foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $rows[] = [
                'id' => (int) $row['id'],
                'user_id' => $row['invited_user_id'] === null ? null : (int) $row['invited_user_id'],
                'name' => (string) (($row['nickname'] ?? '') ?: 'صديق جديد'),
                'handle' => (string) (($row['profile_handle'] ?? '') ?: 'Hallo Party'),
                'avatar_asset' => (string) (($row['avatar_asset'] ?? '') ?: 'assets/images/profile_avatar.png'),
                'status' => (string) $row['status'],
                'reward_usd' => (float) $row['total_reward_usd'],
                'registered_at_label' => date('Y-m-d H:i', strtotime((string) $row['registered_at'] ?: (string) $row['created_at'])),
            ];
        }

        return $rows;
    }

    private function listRewardTransactions(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM referral_reward_transactions
             WHERE user_id = :user_id
             ORDER BY id DESC
             LIMIT 25'
        );
        $statement->execute(['user_id' => $userId]);

        $rows = [];
        foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $rows[] = [
                'id' => (int) $row['id'],
                'title' => (string) $row['title'],
                'subtitle' => (string) $row['subtitle'],
                'type' => (string) $row['reward_type'],
                'amount_usd' => (float) $row['amount_usd'],
                'rate_percent' => (float) $row['rate_percent'],
                'status' => (string) $row['status'],
                'created_at_label' => date('Y-m-d H:i', strtotime((string) $row['created_at'])),
            ];
        }

        return $rows;
    }

    private function leaderboard(): array
    {
        $statement = $this->pdo->query(
            'SELECT users.id,
                    users.nickname,
                    users.profile_handle,
                    users.avatar_asset,
                    COUNT(DISTINCT user_referrals.id) AS invited_count,
                    COALESCE(SUM(referral_reward_transactions.amount_usd), 0) AS reward_usd
             FROM users
             LEFT JOIN user_referrals ON user_referrals.inviter_user_id = users.id
             LEFT JOIN referral_reward_transactions ON referral_reward_transactions.user_id = users.id
             GROUP BY users.id, users.nickname, users.profile_handle, users.avatar_asset
             HAVING invited_count > 0 OR reward_usd > 0
             ORDER BY reward_usd DESC, invited_count DESC, users.id ASC
             LIMIT 10'
        );

        $rows = [];
        $rank = 1;
        foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $rows[] = [
                'rank' => $rank++,
                'user_id' => (int) $row['id'],
                'name' => $this->displayNameForUser($row),
                'handle' => (string) (($row['profile_handle'] ?? '') ?: 'ID:' . $row['id']),
                'avatar_asset' => (string) (($row['avatar_asset'] ?? '') ?: 'assets/images/profile_avatar.png'),
                'invited_count' => (int) $row['invited_count'],
                'reward_usd' => (float) $row['reward_usd'],
            ];
        }

        return $rows;
    }

    private function insertRechargeCommission(
        int $rewardUserId,
        int $sourceUserId,
        float $packagePriceUsd,
        float $percent,
        string $type,
        string $title
    ): void {
        if ($rewardUserId <= 0 || $percent <= 0) {
            return;
        }

        $amount = round($packagePriceUsd * ($percent / 100), 2);
        if ($amount <= 0) {
            return;
        }

        $this->insertRewardTransaction(
            $rewardUserId,
            $sourceUserId,
            $type,
            $amount,
            $percent,
            $title,
            sprintf('تم احتساب %.2f%% من عملية شحن بقيمة %.2f دولار.', $percent, $packagePriceUsd),
            'available',
            (string) $sourceUserId
        );

        $this->pdo->prepare(
            'UPDATE user_referrals
             SET recharge_reward_usd = recharge_reward_usd + :amount,
                 total_reward_usd = total_reward_usd + :amount,
                 first_recharge_at = COALESCE(first_recharge_at, :first_recharge_at),
                 updated_at = :updated_at
             WHERE inviter_user_id = :inviter_user_id
               AND invited_user_id = :invited_user_id'
        )->execute([
            'amount' => $amount,
            'first_recharge_at' => $this->now(),
            'updated_at' => $this->now(),
            'inviter_user_id' => $rewardUserId,
            'invited_user_id' => $sourceUserId,
        ]);
    }

    private function insertRewardTransaction(
        int $userId,
        ?int $sourceUserId,
        string $rewardType,
        float $amountUsd,
        float $ratePercent,
        string $title,
        string $subtitle,
        string $status,
        ?string $contextRef
    ): void {
        $statement = $this->pdo->prepare(
            'INSERT INTO referral_reward_transactions
                (user_id, source_user_id, reward_type, amount_usd, rate_percent, title, subtitle, status, context_ref, created_at)
             VALUES
                (:user_id, :source_user_id, :reward_type, :amount_usd, :rate_percent, :title, :subtitle, :status, :context_ref, :created_at)'
        );
        $statement->execute([
            'user_id' => $userId,
            'source_user_id' => $sourceUserId,
            'reward_type' => $rewardType,
            'amount_usd' => $amountUsd,
            'rate_percent' => $ratePercent,
            'title' => $title,
            'subtitle' => $subtitle,
            'status' => $status,
            'context_ref' => $contextRef,
            'created_at' => $this->now(),
        ]);
    }

    private function settings(): array
    {
        return [
            'daily_target_usd' => (float) $this->settingValue('referral_daily_target_usd', '50'),
            'first_withdraw_usd' => (float) $this->settingValue('referral_first_withdraw_usd', '50'),
            'first_withdraw_days' => (int) $this->settingValue('referral_first_withdraw_days', '0'),
            'signup_reward_usd' => (float) $this->settingValue('referral_signup_reward_usd', '1'),
            'direct_recharge_percent' => (float) $this->settingValue('referral_direct_recharge_percent', '15'),
            'indirect_recharge_percent' => (float) $this->settingValue('referral_indirect_recharge_percent', '5'),
            'invite_link_base' => (string) $this->settingValue('referral_invite_link_base', 'https://halloparty.online/invite?code='),
            'header_asset' => (string) $this->settingValue('referral_header_asset', self::DEFAULT_INVITE_HEADER_ASSET),
            'reward_card_asset' => (string) $this->settingValue('referral_reward_card_asset', self::DEFAULT_REWARD_CARD_ASSET),
            'empty_asset' => (string) $this->settingValue('referral_empty_asset', self::DEFAULT_EMPTY_ASSET),
        ];
    }

    private function seedDefaults(): void
    {
        $defaults = [
            'referral_daily_target_usd' => '50',
            'referral_first_withdraw_usd' => '50',
            'referral_first_withdraw_days' => '0',
            'referral_signup_reward_usd' => '1',
            'referral_direct_recharge_percent' => '15',
            'referral_indirect_recharge_percent' => '5',
            'referral_invite_link_base' => 'https://halloparty.online/invite?code=',
            'referral_header_asset' => self::DEFAULT_INVITE_HEADER_ASSET,
            'referral_reward_card_asset' => self::DEFAULT_REWARD_CARD_ASSET,
            'referral_empty_asset' => self::DEFAULT_EMPTY_ASSET,
        ];

        foreach ($defaults as $key => $value) {
            if ($this->settingExists($key)) {
                continue;
            }
            $this->upsertSetting($key, $value);
        }
    }

    private function settingValue(string $key, string $default): string
    {
        $statement = $this->pdo->prepare('SELECT setting_value FROM app_settings WHERE setting_key = :setting_key LIMIT 1');
        $statement->execute(['setting_key' => $key]);
        $value = $statement->fetchColumn();

        if ($value === false) {
            $this->upsertSetting($key, $default);
            return $default;
        }

        return (string) $value;
    }

    private function settingExists(string $key): bool
    {
        $statement = $this->pdo->prepare('SELECT 1 FROM app_settings WHERE setting_key = :setting_key LIMIT 1');
        $statement->execute(['setting_key' => $key]);
        return $statement->fetch() !== false;
    }

    private function upsertSetting(string $key, string $value): void
    {
        $driver = (string) $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
        $sql = $driver === 'sqlite'
            ? 'INSERT INTO app_settings (setting_key, setting_value, updated_at)
               VALUES (:setting_key, :setting_value, :updated_at)
               ON CONFLICT(setting_key) DO UPDATE SET setting_value = excluded.setting_value, updated_at = excluded.updated_at'
            : 'INSERT INTO app_settings (setting_key, setting_value, updated_at)
               VALUES (:setting_key, :setting_value, :updated_at)
               ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), updated_at = VALUES(updated_at)';

        $statement = $this->pdo->prepare($sql);
        $statement->execute([
            'setting_key' => $key,
            'setting_value' => $value,
            'updated_at' => $this->now(),
        ]);
    }

    private function inviteLink(string $code, array $settings): string
    {
        $base = trim((string) $settings['invite_link_base']);
        if ($base === '') {
            $base = 'https://halloparty.online/invite?code=';
        }

        return $base . rawurlencode($code);
    }

    private function findUserByInviteCode(string $code): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM users WHERE invite_code = :invite_code LIMIT 1');
        $statement->execute(['invite_code' => $this->normalizeInviteCode($code)]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
    }

    private function findUserById(int $userId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM users WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        return $row === false ? null : $row;
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
        $user = $statement->fetch(PDO::FETCH_ASSOC);

        if ($user === false) {
            throw new ApiException('Unauthenticated.', 401);
        }

        if (($user['status'] ?? 'active') !== 'active') {
            throw new ApiException('This account is suspended.', 403);
        }

        return $user;
    }

    private function backfillInviteCodes(): void
    {
        $statement = $this->pdo->query('SELECT id FROM users WHERE invite_code IS NULL OR invite_code = "" LIMIT 500');
        foreach ($statement->fetchAll(PDO::FETCH_COLUMN) as $userId) {
            $this->ensureInviteCodeForUser((int) $userId);
        }
    }

    private function generateInviteCode(int $userId): string
    {
        $base = 'HP' . strtoupper(str_pad(base_convert((string) $userId, 10, 36), 6, '0', STR_PAD_LEFT));
        $code = $base;
        $suffix = 0;

        while ($this->inviteCodeExists($code, $userId)) {
            $suffix++;
            $code = $base . strtoupper(base_convert((string) $suffix, 10, 36));
        }

        return $code;
    }

    private function inviteCodeExists(string $code, int $exceptUserId): bool
    {
        $statement = $this->pdo->prepare(
            'SELECT id FROM users WHERE invite_code = :invite_code AND id != :id LIMIT 1'
        );
        $statement->execute([
            'invite_code' => $code,
            'id' => $exceptUserId,
        ]);

        return $statement->fetch() !== false;
    }

    private function normalizeInviteCode(string $code): string
    {
        return strtoupper(preg_replace('/[^A-Z0-9]/', '', strtoupper(trim($code))) ?? '');
    }

    private function displayNameForUser(array $user): string
    {
        $name = trim((string) ($user['nickname'] ?? ''));
        if ($name !== '') {
            return $name;
        }

        $email = trim((string) ($user['email'] ?? ''));
        if ($email !== '') {
            return strtok($email, '@') ?: 'Hallo Party User';
        }

        return 'Hallo Party User';
    }

    private function recentReferralsForAdminUser(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT user_referrals.*,
                    users.nickname AS invited_name
             FROM user_referrals
             LEFT JOIN users ON users.id = user_referrals.invited_user_id
             WHERE user_referrals.inviter_user_id = :user_id
             ORDER BY user_referrals.id DESC
             LIMIT 5'
        );
        $statement->execute(['user_id' => $userId]);

        return $statement->fetchAll(PDO::FETCH_ASSOC);
    }

    private function decimalString(mixed $value): string
    {
        return (string) max(0.0, round((float) $value, 2));
    }

    private function scalar(string $sql, array $params): mixed
    {
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);
        return $statement->fetchColumn();
    }

    private function ensureSchema(): void
    {
        $driver = (string) $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
        $isMysql = $driver === 'mysql';

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS app_settings (
            setting_key VARCHAR(120) PRIMARY KEY,
            setting_value TEXT NOT NULL,
            updated_at DATETIME NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS app_settings (
            setting_key TEXT PRIMARY KEY,
            setting_value TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )');

        $this->ensureColumn('users', 'invite_code', $isMysql ? 'VARCHAR(32) NULL' : 'TEXT NULL');
        $this->ensureColumn('users', 'referred_by_user_id', $isMysql ? 'INT UNSIGNED NULL' : 'INTEGER NULL');
        $this->ensureColumn('pending_registrations', 'referral_code', $isMysql ? 'VARCHAR(32) NULL' : 'TEXT NULL');

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS user_referrals (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            inviter_user_id INT UNSIGNED NOT NULL,
            invited_user_id INT UNSIGNED NULL,
            invite_code_snapshot VARCHAR(32) NOT NULL,
            status VARCHAR(30) NOT NULL DEFAULT "registered",
            signup_reward_usd DECIMAL(12,2) NOT NULL DEFAULT 0,
            recharge_reward_usd DECIMAL(12,2) NOT NULL DEFAULT 0,
            total_reward_usd DECIMAL(12,2) NOT NULL DEFAULT 0,
            registered_at DATETIME NULL,
            first_recharge_at DATETIME NULL,
            created_at DATETIME NOT NULL,
            updated_at DATETIME NOT NULL,
            UNIQUE KEY uq_user_referrals_invited_user (invited_user_id),
            KEY idx_user_referrals_inviter_status (inviter_user_id, status),
            KEY idx_user_referrals_code (invite_code_snapshot)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS user_referrals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inviter_user_id INTEGER NOT NULL,
            invited_user_id INTEGER NULL UNIQUE,
            invite_code_snapshot TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT "registered",
            signup_reward_usd REAL NOT NULL DEFAULT 0,
            recharge_reward_usd REAL NOT NULL DEFAULT 0,
            total_reward_usd REAL NOT NULL DEFAULT 0,
            registered_at TEXT NULL,
            first_recharge_at TEXT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        )');

        $this->pdo->exec($isMysql ? 'CREATE TABLE IF NOT EXISTS referral_reward_transactions (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id INT UNSIGNED NOT NULL,
            source_user_id INT UNSIGNED NULL,
            reward_type VARCHAR(40) NOT NULL,
            amount_usd DECIMAL(12,2) NOT NULL DEFAULT 0,
            rate_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
            title VARCHAR(190) NOT NULL,
            subtitle VARCHAR(255) NOT NULL DEFAULT "",
            status VARCHAR(30) NOT NULL DEFAULT "available",
            context_ref VARCHAR(120) NULL,
            created_at DATETIME NOT NULL,
            KEY idx_referral_rewards_user_status (user_id, status),
            KEY idx_referral_rewards_source (source_user_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci' : 'CREATE TABLE IF NOT EXISTS referral_reward_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            source_user_id INTEGER NULL,
            reward_type TEXT NOT NULL,
            amount_usd REAL NOT NULL DEFAULT 0,
            rate_percent REAL NOT NULL DEFAULT 0,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL DEFAULT "",
            status TEXT NOT NULL DEFAULT "available",
            context_ref TEXT NULL,
            created_at TEXT NOT NULL
        )');

        if ($isMysql) {
            $this->ensureIndex('users', 'idx_users_invite_code', 'CREATE UNIQUE INDEX idx_users_invite_code ON users (invite_code)');
            $this->ensureIndex('users', 'idx_users_referred_by', 'CREATE INDEX idx_users_referred_by ON users (referred_by_user_id)');
        } else {
            $this->pdo->exec('CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite_code ON users (invite_code)');
            $this->pdo->exec('CREATE INDEX IF NOT EXISTS idx_users_referred_by ON users (referred_by_user_id)');
        }
    }

    private function ensureColumn(string $table, string $column, string $definition): void
    {
        if ($this->hasColumn($table, $column)) {
            return;
        }

        $this->pdo->exec(sprintf('ALTER TABLE %s ADD COLUMN %s %s', $table, $column, $definition));
    }

    private function hasColumn(string $table, string $column): bool
    {
        $driver = (string) $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME);
        if ($driver === 'sqlite') {
            $statement = $this->pdo->query('PRAGMA table_info(' . $table . ')');
            foreach ($statement->fetchAll(PDO::FETCH_ASSOC) as $row) {
                if (($row['name'] ?? '') === $column) {
                    return true;
                }
            }
            return false;
        }

        $statement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = :table_name
               AND COLUMN_NAME = :column_name'
        );
        $statement->execute([
            'table_name' => $table,
            'column_name' => $column,
        ]);

        return (int) $statement->fetchColumn() > 0;
    }

    private function ensureIndex(string $table, string $index, string $createSql): void
    {
        $statement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM INFORMATION_SCHEMA.STATISTICS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = :table_name
               AND INDEX_NAME = :index_name'
        );
        $statement->execute([
            'table_name' => $table,
            'index_name' => $index,
        ]);

        if ((int) $statement->fetchColumn() === 0) {
            $this->pdo->exec($createSql);
        }
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
