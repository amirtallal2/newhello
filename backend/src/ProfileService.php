<?php

declare(strict_types=1);

final class ProfileService
{
    private const DEFAULT_AVATAR_ASSET = 'assets/images/profile_avatar.png';
    private const DEFAULT_HANDLE = 'Shark.island';
    private const DEFAULT_SIGNATURE = 'ليس لديك المقدمة الشخصية';
    private const ALLOWED_AVATAR_ASSETS = [
        'assets/images/profile_avatar.png',
        'assets/images/post_author_avatar.png',
        'assets/images/live150_comment_avatar.png',
        'assets/images/profile_store_friend_yara.png',
        'assets/images/profile_store_friend_yara_alt.png',
        'assets/images/profile_store_friend_nona_avatar.png',
    ];

    public function __construct(
        private readonly PDO $pdo,
    ) {
    }

    public function summary(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $settings = $this->settingsRow((int) $user['id']);

        return [
            'user' => $this->normalizeUser($user),
            'stats' => $this->mapStats($user),
            'status' => $this->mapStatus($user),
            'settings' => $this->mapSettings($settings),
            'appearance' => $this->mapEquippedAppearance((int) $user['id']),
        ];
    }

    public function publicSummary(int $userId, ?string $authorizationHeader): array
    {
        $viewer = $this->requireUser($authorizationHeader);
        if ((int) $viewer['id'] === $userId) {
            return $this->summary($authorizationHeader);
        }

        return $this->summaryByUserId($userId);
    }

    public function updateProfile(
        ?string $authorizationHeader,
        string $nickname,
        ?string $email,
        ?string $phone,
        ?string $birthdate,
        ?string $gender,
        string $country,
        string $signatureText,
        string $profileHandle,
        ?string $avatarAsset,
        ?array $avatarUpload,
    ): array {
        $user = $this->requireUser($authorizationHeader);

        $nickname = trim($nickname);
        $email = $email !== null ? trim($email) : null;
        $phone = $phone !== null ? trim($phone) : null;
        $country = trim($country);
        $signatureText = trim($signatureText);
        $profileHandle = trim($profileHandle);
        $avatarAsset = $avatarAsset !== null ? trim($avatarAsset) : null;
        $gender = $gender !== null ? trim($gender) : null;

        if ($nickname === '' || mb_strlen($nickname) > 120) {
            throw new ApiException('Invalid nickname.', 422);
        }

        if ($email !== null && $email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiException('Invalid email address.', 422);
        }

        if ($phone !== null && $phone !== '' && !preg_match('/^\+?[0-9]{8,20}$/', $phone)) {
            throw new ApiException('Invalid phone number.', 422);
        }

        if ($country === '' || mb_strlen($country) > 120) {
            throw new ApiException('Invalid country.', 422);
        }

        if ($birthdate !== null && trim($birthdate) !== '' && !$this->isValidBirthdate(trim($birthdate))) {
            throw new ApiException('Invalid birthdate.', 422);
        }

        if ($gender !== null && $gender !== '' && mb_strlen($gender) > 40) {
            throw new ApiException('Invalid gender value.', 422);
        }

        if ($signatureText !== '' && mb_strlen($signatureText) > 160) {
            throw new ApiException('Profile signature is too long.', 422);
        }

        if ($profileHandle === '' || mb_strlen($profileHandle) > 60) {
            throw new ApiException('Invalid profile handle.', 422);
        }

        if ($avatarAsset !== null && $avatarAsset !== '' && !$this->isAllowedAvatarPath($avatarAsset)) {
            throw new ApiException('Invalid avatar selection.', 422);
        }

        $this->assertUniqueAccountFields((int) $user['id'], $email, $phone);

        if ($avatarUpload !== null) {
            $avatarAsset = $this->storeProfileImageDraft($avatarUpload);
        }

        $statement = $this->pdo->prepare(
            'UPDATE users
             SET nickname = :nickname,
                 email = :email,
                 phone = :phone,
                 birthdate = :birthdate,
                 gender = :gender,
                 country = :country,
                 signature_text = :signature_text,
                 profile_handle = :profile_handle,
                 avatar_asset = :avatar_asset,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'nickname' => $nickname,
            'email' => $email !== null && $email !== '' ? strtolower($email) : null,
            'phone' => $phone !== null && $phone !== '' ? $phone : null,
            'birthdate' => $birthdate !== null && trim($birthdate) !== '' ? trim($birthdate) : null,
            'gender' => $gender !== null && $gender !== '' ? $gender : null,
            'country' => $country,
            'signature_text' => $signatureText !== '' ? $signatureText : self::DEFAULT_SIGNATURE,
            'profile_handle' => $profileHandle,
            'avatar_asset' => $avatarAsset !== null && $avatarAsset !== '' ? $avatarAsset : self::DEFAULT_AVATAR_ASSET,
            'updated_at' => $this->now(),
            'id' => $user['id'],
        ]);

        return $this->summaryByUserId((int) $user['id']);
    }

    public function updateSettings(
        ?string $authorizationHeader,
        array $payload,
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $settings = $this->settingsRow((int) $user['id']);
        $updatedAt = $this->now();

        $statement = $this->pdo->prepare(
            'UPDATE user_settings
             SET private_profile = :private_profile,
                 allow_direct_messages = :allow_direct_messages,
                 show_online_status = :show_online_status,
                 receive_chat_notifications = :receive_chat_notifications,
                 receive_live_notifications = :receive_live_notifications,
                 receive_room_invites = :receive_room_invites,
                 receive_party_invites = :receive_party_invites,
                 preferred_language = :preferred_language,
                 updated_at = :updated_at
             WHERE user_id = :user_id'
        );
        $statement->execute([
            'private_profile' => $this->boolToDb($payload['private_profile'] ?? $settings['private_profile']),
            'allow_direct_messages' => $this->boolToDb($payload['allow_direct_messages'] ?? $settings['allow_direct_messages']),
            'show_online_status' => $this->boolToDb($payload['show_online_status'] ?? $settings['show_online_status']),
            'receive_chat_notifications' => $this->boolToDb($payload['receive_chat_notifications'] ?? $settings['receive_chat_notifications']),
            'receive_live_notifications' => $this->boolToDb($payload['receive_live_notifications'] ?? $settings['receive_live_notifications']),
            'receive_room_invites' => $this->boolToDb($payload['receive_room_invites'] ?? $settings['receive_room_invites']),
            'receive_party_invites' => $this->boolToDb($payload['receive_party_invites'] ?? $settings['receive_party_invites']),
            'preferred_language' => $this->sanitizeLanguage((string) ($payload['preferred_language'] ?? $settings['preferred_language'])),
            'updated_at' => $updatedAt,
            'user_id' => $user['id'],
        ]);

        return $this->summaryByUserId((int) $user['id']);
    }

    public function changePassword(
        ?string $authorizationHeader,
        string $currentPassword,
        string $newPassword,
    ): void {
        $user = $this->requireUser($authorizationHeader);

        if (!password_verify($currentPassword, (string) $user['password_hash'])) {
            throw new ApiException('Current password is incorrect.', 422);
        }

        if (mb_strlen(trim($newPassword)) < 6) {
            throw new ApiException('Password must be at least 6 characters.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE users
             SET password_hash = :password_hash,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'password_hash' => password_hash(trim($newPassword), PASSWORD_DEFAULT),
            'updated_at' => $this->now(),
            'id' => $user['id'],
        ]);
    }

    private function summaryByUserId(int $userId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM users WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $userId]);
        $user = $statement->fetch();

        if ($user === false) {
            throw new ApiException('User not found.', 404);
        }

        $settings = $this->settingsRow($userId);

        return [
            'user' => $this->normalizeUser($user),
            'stats' => $this->mapStats($user),
            'status' => $this->mapStatus($user),
            'settings' => $this->mapSettings($settings),
            'appearance' => $this->mapEquippedAppearance($userId),
        ];
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

    private function normalizeUser(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'email' => $user['email'],
            'phone' => $user['phone'],
            'nickname' => $user['nickname'] ?: 'بدون اسم',
            'birthdate' => $user['birthdate'],
            'gender' => $user['gender'],
            'country' => $user['country'] ?: 'Egypt',
            'status' => $user['status'],
            'auth_provider' => $user['auth_provider'] ?? 'password',
            'email_verified' => !empty($user['email_verified_at']),
            'phone_verified' => !empty($user['phone_verified_at']),
            'profile_handle' => $user['profile_handle'] ?: self::DEFAULT_HANDLE,
            'signature_text' => $user['signature_text'] ?: self::DEFAULT_SIGNATURE,
            'avatar_asset' => $user['avatar_asset'] ?: self::DEFAULT_AVATAR_ASSET,
            'agency_id' => $user['agency_id'] !== null ? (int) $user['agency_id'] : null,
            'agency_role' => $user['agency_role'] !== null ? (string) $user['agency_role'] : null,
        ];
    }

    private function mapStats(array $user): array
    {
        $userId = (int) ($user['id'] ?? 0);
        if ($userId > 0) {
            $stats = $this->connectionStats($userId);
            if ($stats !== null) {
                return $stats;
            }
        }

        return [
            'following_count' => (int) ($user['following_count'] ?? 0),
            'followers_count' => (int) ($user['followers_count'] ?? 0),
            'friends_count' => (int) ($user['friends_count'] ?? 0),
        ];
    }

    private function connectionStats(int $userId): ?array
    {
        try {
            $following = $this->pdo->prepare(
                'SELECT COUNT(*)
                 FROM user_follows
                 WHERE follower_user_id = :user_id
                   AND status = "active"'
            );
            $following->execute(['user_id' => $userId]);

            $followers = $this->pdo->prepare(
                'SELECT COUNT(*)
                 FROM user_follows
                 WHERE followed_user_id = :user_id
                   AND status = "active"'
            );
            $followers->execute(['user_id' => $userId]);

            $friends = $this->pdo->prepare(
                'SELECT COUNT(*)
                 FROM user_follows outgoing
                 INNER JOIN user_follows incoming
                     ON incoming.follower_user_id = outgoing.followed_user_id
                    AND incoming.followed_user_id = outgoing.follower_user_id
                    AND incoming.status = "active"
                 WHERE outgoing.follower_user_id = :user_id
                   AND outgoing.status = "active"'
            );
            $friends->execute(['user_id' => $userId]);

            return [
                'following_count' => (int) $following->fetchColumn(),
                'followers_count' => (int) $followers->fetchColumn(),
                'friends_count' => (int) $friends->fetchColumn(),
            ];
        } catch (Throwable) {
            return null;
        }
    }

    private function mapStatus(array $user): array
    {
        return [
            'level_current' => (int) ($user['level_current'] ?? 0),
            'level_next' => (int) ($user['level_next'] ?? 1),
            'level_progress_percent' => (int) ($user['level_progress_percent'] ?? 67),
            'vip_tier' => (string) (($user['vip_tier'] ?? '') ?: 'VIP 0'),
            'svip_tier' => (string) (($user['svip_tier'] ?? '') ?: 'SVIP 0'),
            'badges_count' => (int) ($user['badges_count'] ?? 0),
            'tasks_completed' => (int) ($user['tasks_completed'] ?? 0),
            'tasks_total' => max((int) ($user['tasks_total'] ?? 0), 1),
        ];
    }

    private function mapSettings(array $settings): array
    {
        return [
            'private_profile' => (bool) $settings['private_profile'],
            'allow_direct_messages' => (bool) $settings['allow_direct_messages'],
            'show_online_status' => (bool) $settings['show_online_status'],
            'receive_chat_notifications' => (bool) $settings['receive_chat_notifications'],
            'receive_live_notifications' => (bool) $settings['receive_live_notifications'],
            'receive_room_invites' => (bool) $settings['receive_room_invites'],
            'receive_party_invites' => (bool) $settings['receive_party_invites'],
            'preferred_language' => (string) $settings['preferred_language'],
        ];
    }

    private function mapEquippedAppearance(int $userId): array
    {
        $appearance = [
            'avatar_frame_asset_path' => null,
            'chat_frame_asset_path' => null,
            'profile_badge_asset_path' => null,
            'background_asset_path' => null,
            'entry_effect_asset_path' => null,
        ];

        try {
            $statement = $this->pdo->prepare(
                'SELECT category_key, preview_asset_path, dialog_preview_asset_path
                 FROM user_store_inventory
                 WHERE user_id = :user_id
                   AND status = :status
                   AND is_equipped = 1
                   AND (expires_at IS NULL OR expires_at > :now)
                 ORDER BY updated_at DESC, id DESC'
            );
            $statement->execute([
                'user_id' => $userId,
                'status' => 'active',
                'now' => $this->now(),
            ]);
        } catch (Throwable) {
            return $appearance;
        }

        foreach ($statement->fetchAll() as $item) {
            $categoryKey = (string) ($item['category_key'] ?? '');
            $previewAsset = trim((string) ($item['preview_asset_path'] ?? ''));
            $dialogAsset = trim((string) ($item['dialog_preview_asset_path'] ?? ''));
            $displayAsset = $dialogAsset !== '' ? $dialogAsset : $previewAsset;
            if ($previewAsset === '') {
                continue;
            }

            if (($categoryKey === 'animated_frames' || $categoryKey === 'frames') && $appearance['avatar_frame_asset_path'] === null) {
                $appearance['avatar_frame_asset_path'] = $previewAsset;
                continue;
            }

            if ($categoryKey === 'chat_frames' && $appearance['chat_frame_asset_path'] === null) {
                $appearance['chat_frame_asset_path'] = $displayAsset;
                continue;
            }

            if ($categoryKey === 'aristocracy' && $appearance['profile_badge_asset_path'] === null) {
                $appearance['profile_badge_asset_path'] = $displayAsset;
                continue;
            }

            if ($categoryKey === 'backgrounds' && $appearance['background_asset_path'] === null) {
                $appearance['background_asset_path'] = $displayAsset;
                continue;
            }

            if ($categoryKey === 'entry_effects' && $appearance['entry_effect_asset_path'] === null) {
                $appearance['entry_effect_asset_path'] = $displayAsset;
            }
        }

        return $appearance;
    }

    private function settingsRow(int $userId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM user_settings WHERE user_id = :user_id LIMIT 1');
        $statement->execute(['user_id' => $userId]);
        $row = $statement->fetch();

        if ($row !== false) {
            return $row;
        }

        $defaults = [
            'user_id' => $userId,
            'private_profile' => 0,
            'allow_direct_messages' => 1,
            'show_online_status' => 1,
            'receive_chat_notifications' => 1,
            'receive_live_notifications' => 1,
            'receive_room_invites' => 1,
            'receive_party_invites' => 1,
            'preferred_language' => 'ar',
            'updated_at' => $this->now(),
        ];

        $insert = $this->pdo->prepare(
            'INSERT INTO user_settings
                (user_id, private_profile, allow_direct_messages, show_online_status, receive_chat_notifications, receive_live_notifications, receive_room_invites, receive_party_invites, preferred_language, updated_at)
             VALUES
                (:user_id, :private_profile, :allow_direct_messages, :show_online_status, :receive_chat_notifications, :receive_live_notifications, :receive_room_invites, :receive_party_invites, :preferred_language, :updated_at)'
        );
        $insert->execute($defaults);

        return $defaults;
    }

    private function boolToDb(mixed $value): int
    {
        return filter_var($value, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
    }

    private function assertUniqueAccountFields(int $userId, ?string $email, ?string $phone): void
    {
        if ($email !== null && $email !== '') {
            $statement = $this->pdo->prepare(
                'SELECT id FROM users WHERE email = :email AND id != :id LIMIT 1'
            );
            $statement->execute([
                'email' => strtolower($email),
                'id' => $userId,
            ]);
            if ($statement->fetch() !== false) {
                throw new ApiException('Email is already in use.', 422);
            }
        }

        if ($phone !== null && $phone !== '') {
            $statement = $this->pdo->prepare(
                'SELECT id FROM users WHERE phone = :phone AND id != :id LIMIT 1'
            );
            $statement->execute([
                'phone' => $phone,
                'id' => $userId,
            ]);
            if ($statement->fetch() !== false) {
                throw new ApiException('Phone number is already in use.', 422);
            }
        }
    }

    private function isAllowedAvatarPath(string $avatarPath): bool
    {
        if (in_array($avatarPath, self::ALLOWED_AVATAR_ASSETS, true)) {
            return true;
        }

        return str_starts_with($avatarPath, '/storage/profile/');
    }

    private function storeProfileImageDraft(array $draft): string
    {
        $fileName = trim((string) ($draft['filename'] ?? 'profile-image'));
        $mimeType = trim((string) ($draft['mime_type'] ?? 'image/jpeg'));
        $content = trim((string) ($draft['content_base64'] ?? ''));

        if ($content === '') {
            throw new ApiException('Invalid profile image.', 422);
        }

        if (!in_array($mimeType, ['image/png', 'image/jpeg', 'image/jpg', 'image/webp'], true)) {
            throw new ApiException('Unsupported profile image type.', 422);
        }

        $decoded = base64_decode($content, true);
        if ($decoded === false) {
            throw new ApiException('Invalid profile image payload.', 422);
        }

        if (strlen($decoded) > 5 * 1024 * 1024) {
            throw new ApiException('Profile image is too large.', 422);
        }

        $extension = match ($mimeType) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $directory = dirname(__DIR__) . '/storage/profile';
        if (!is_dir($directory) && !mkdir($directory, 0777, true) && !is_dir($directory)) {
            throw new ApiException('Failed to create profile image storage.', 500);
        }

        $safeName = preg_replace('/[^a-zA-Z0-9_\-]/', '-', pathinfo($fileName, PATHINFO_FILENAME)) ?: 'profile';
        $relativePath = '/storage/profile/' . $safeName . '-' . bin2hex(random_bytes(6)) . '.' . $extension;
        $absolutePath = dirname(__DIR__) . $relativePath;

        if (file_put_contents($absolutePath, $decoded) === false) {
            throw new ApiException('Failed to store profile image.', 500);
        }

        return $relativePath;
    }

    private function sanitizeLanguage(string $language): string
    {
        $normalized = strtolower(trim($language));
        return in_array($normalized, ['ar', 'en'], true) ? $normalized : 'ar';
    }

    private function isValidBirthdate(string $birthdate): bool
    {
        $parsed = date_create($birthdate);
        return $parsed !== false && $parsed->format('Y-m-d') === $birthdate;
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
