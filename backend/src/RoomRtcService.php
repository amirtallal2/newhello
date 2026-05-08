<?php

declare(strict_types=1);

final class RoomRtcService
{
    private const ACTIVE_STATUS = 'joined';
    private const LEFT_STATUS = 'left';
    private const KICKED_STATUS = 'kicked';
    private const ROLE_HOST = 'host';
    private const ROLE_SPEAKER = 'speaker';
    private const ROLE_LISTENER = 'listener';

    public function __construct(
        private readonly PDO $pdo,
        private readonly array $config
    ) {
    }

    public function join(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->requireRoom($roomId);
        $user = $this->requireAuthenticatedUser($authorizationHeader);
        $this->cleanupStaleParticipants($roomId);
        $this->ensureRoomAudioAvailable($room);

        $userAccount = $this->userAccount((int) $user['id']);
        $role = $this->resolveUserRole($room, $user, $roomId);
        $seatNumber = $this->resolveAssignedSeatNumber($room, $user, $roomId, $role);
        $existing = $this->findParticipantByUserAccount($roomId, $userAccount);

        if ($existing !== null && (string) ($existing['status'] ?? '') === self::KICKED_STATUS) {
            throw new ApiException('You have been removed from this room.', 403);
        }

        $now = $this->now();
        $micMuted = $existing === null
            ? ($role === self::ROLE_LISTENER ? 1 : 0)
            : (int) ($existing['mic_muted'] ?? 0);

        if ($existing === null) {
            $statement = $this->pdo->prepare(
                'INSERT INTO room_audio_participants
                    (room_id, user_id, user_account, display_name, avatar_asset, role, seat_number, mic_muted, status, joined_at, last_seen_at, left_at, updated_at)
                 VALUES
                    (:room_id, :user_id, :user_account, :display_name, :avatar_asset, :role, :seat_number, :mic_muted, :status, :joined_at, :last_seen_at, :left_at, :updated_at)'
            );
            $statement->execute([
                'room_id' => $roomId,
                'user_id' => (int) $user['id'],
                'user_account' => $userAccount,
                'display_name' => $this->userDisplayName($user),
                'avatar_asset' => (string) ($user['avatar_asset'] ?? 'assets/images/profile_avatar.png'),
                'role' => $role,
                'seat_number' => $seatNumber,
                'mic_muted' => $micMuted,
                'status' => self::ACTIVE_STATUS,
                'joined_at' => $now,
                'last_seen_at' => $now,
                'left_at' => null,
                'updated_at' => $now,
            ]);
        } else {
            $statement = $this->pdo->prepare(
                'UPDATE room_audio_participants
                 SET user_id = :user_id,
                     display_name = :display_name,
                     avatar_asset = :avatar_asset,
                     role = :role,
                     seat_number = :seat_number,
                     mic_muted = :mic_muted,
                     status = :status,
                     last_seen_at = :last_seen_at,
                     left_at = :left_at,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'user_id' => (int) $user['id'],
                'display_name' => $this->userDisplayName($user),
                'avatar_asset' => (string) ($user['avatar_asset'] ?? 'assets/images/profile_avatar.png'),
                'role' => $role,
                'seat_number' => $seatNumber,
                'mic_muted' => $micMuted,
                'status' => self::ACTIVE_STATUS,
                'last_seen_at' => $now,
                'left_at' => null,
                'updated_at' => $now,
                'id' => (int) $existing['id'],
            ]);
        }

        $this->syncRoomListenerCount($roomId);
        return $this->buildSessionPayload($roomId, $userAccount);
    }

    public function leave(int $roomId, ?string $authorizationHeader): array
    {
        $user = $this->requireAuthenticatedUser($authorizationHeader);
        $participant = $this->requireParticipant($roomId, $this->userAccount((int) $user['id']));

        if ((string) ($participant['status'] ?? '') === self::KICKED_STATUS) {
            return [
                'room_id' => $roomId,
                'left' => true,
                'kicked' => true,
            ];
        }

        $statement = $this->pdo->prepare(
            'UPDATE room_audio_participants
             SET status = :status,
                 left_at = :left_at,
                 last_seen_at = :last_seen_at,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $now = $this->now();
        $statement->execute([
            'status' => self::LEFT_STATUS,
            'left_at' => $now,
            'last_seen_at' => $now,
            'updated_at' => $now,
            'id' => (int) $participant['id'],
        ]);

        $this->syncRoomListenerCount($roomId);

        return [
            'room_id' => $roomId,
            'left' => true,
        ];
    }

    public function endRoomAsHost(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->requireRoom($roomId);
        $user = $this->requireAuthenticatedUser($authorizationHeader);
        $userId = (int) $user['id'];
        $hostUserId = isset($room['host_user_id']) && $room['host_user_id'] !== null
            ? (int) $room['host_user_id']
            : null;
        $creatorUserId = isset($room['creator_user_id']) && $room['creator_user_id'] !== null
            ? (int) $room['creator_user_id']
            : null;

        if ($hostUserId !== $userId && $creatorUserId !== $userId) {
            throw new ApiException('Only the room host can close this room.', 403);
        }

        $now = $this->now();
        $statement = $this->pdo->prepare(
            'UPDATE rooms
             SET status = "hidden",
                 audio_enabled = 0,
                 listener_count = 0,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'updated_at' => $now,
            'id' => $roomId,
        ]);

        $rejectSeatRequests = $this->pdo->prepare(
            'UPDATE room_seat_requests
             SET status = "rejected",
                 updated_at = :updated_at
             WHERE room_id = :room_id
               AND status = "pending"'
        );
        $rejectSeatRequests->execute([
            'updated_at' => $now,
            'room_id' => $roomId,
        ]);

        $this->closeRoomAudio($roomId, self::LEFT_STATUS);

        return [
            'room_id' => $roomId,
            'ended' => true,
        ];
    }

    public function heartbeat(int $roomId, ?string $authorizationHeader): array
    {
        $user = $this->requireAuthenticatedUser($authorizationHeader);
        $userAccount = $this->userAccount((int) $user['id']);
        $participant = $this->requireParticipant($roomId, $userAccount);

        if ((string) ($participant['status'] ?? '') === self::KICKED_STATUS) {
            throw new ApiException('You have been removed from this room.', 403);
        }

        $room = $this->requireRoom($roomId);
        $this->ensureRoomAudioAvailable($room);

        $role = $this->resolveUserRole($room, $user, $roomId);
        $seatNumber = $this->resolveAssignedSeatNumber($room, $user, $roomId, $role);
        $now = $this->now();

        $statement = $this->pdo->prepare(
            'UPDATE room_audio_participants
             SET role = :role,
                 seat_number = :seat_number,
                 status = :status,
                 last_seen_at = :last_seen_at,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'role' => $role,
            'seat_number' => $seatNumber,
            'status' => self::ACTIVE_STATUS,
            'last_seen_at' => $now,
            'updated_at' => $now,
            'id' => (int) $participant['id'],
        ]);

        $this->cleanupStaleParticipants($roomId);
        $this->syncRoomListenerCount($roomId);
        return $this->buildSessionPayload($roomId, $userAccount);
    }

    public function issueToken(int $roomId, ?string $authorizationHeader): array
    {
        $user = $this->requireAuthenticatedUser($authorizationHeader);
        return $this->buildSessionPayload($roomId, $this->userAccount((int) $user['id']));
    }

    public function updateLocalMicrophone(int $roomId, ?string $authorizationHeader, bool $muted): array
    {
        $user = $this->requireAuthenticatedUser($authorizationHeader);
        $participant = $this->requireParticipant($roomId, $this->userAccount((int) $user['id']));
        $role = (string) ($participant['role'] ?? self::ROLE_LISTENER);

        if ($role === self::ROLE_LISTENER) {
            throw new ApiException('Listeners cannot publish microphone audio.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE room_audio_participants
             SET mic_muted = :mic_muted, last_seen_at = :last_seen_at, updated_at = :updated_at
             WHERE id = :id'
        );
        $now = $this->now();
        $statement->execute([
            'mic_muted' => $muted ? 1 : 0,
            'last_seen_at' => $now,
            'updated_at' => $now,
            'id' => (int) $participant['id'],
        ]);

        return $this->buildSessionPayload($roomId, $this->userAccount((int) $user['id']));
    }

    public function listParticipants(int $roomId): array
    {
        $this->cleanupStaleParticipants($roomId);
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM room_audio_participants
             WHERE room_id = :room_id AND status = :status
             ORDER BY
                CASE role
                    WHEN "host" THEN 0
                    WHEN "speaker" THEN 1
                    ELSE 2
                END ASC,
                CASE WHEN seat_number IS NULL THEN 999 ELSE seat_number END ASC,
                id ASC'
        );
        $statement->execute([
            'room_id' => $roomId,
            'status' => self::ACTIVE_STATUS,
        ]);

        return array_map(
            fn (array $participant): array => $this->normalizeParticipant($participant),
            $statement->fetchAll()
        );
    }

    public function adminUpdateRoomAudioSettings(
        int $roomId,
        bool $audioEnabled,
        ?int $hostUserId,
        string $agoraChannelName
    ): void {
        $room = $this->requireRoom($roomId);
        $agoraChannelName = $this->sanitizeChannelName($agoraChannelName);

        if ($agoraChannelName === '') {
            $agoraChannelName = $this->defaultChannelName($room);
        }

        if ($hostUserId !== null && $hostUserId > 0) {
            $statement = $this->pdo->prepare('SELECT id, nickname, avatar_asset FROM users WHERE id = :id LIMIT 1');
            $statement->execute(['id' => $hostUserId]);
            $host = $statement->fetch();
            if ($host === false) {
                throw new ApiException('Selected host user was not found.', 404);
            }

            $statement = $this->pdo->prepare(
                'UPDATE rooms
                 SET audio_enabled = :audio_enabled,
                     host_user_id = :host_user_id,
                     host_name = :host_name,
                     host_avatar_asset = :host_avatar_asset,
                     agora_channel_name = :agora_channel_name,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'audio_enabled' => $audioEnabled ? 1 : 0,
                'host_user_id' => $hostUserId,
                'host_name' => (string) ($host['nickname'] ?? $room['host_name']),
                'host_avatar_asset' => (string) ($host['avatar_asset'] ?? $room['host_avatar_asset']),
                'agora_channel_name' => $agoraChannelName,
                'updated_at' => $this->now(),
                'id' => $roomId,
            ]);

            $this->promoteHostParticipant($roomId, $hostUserId);
            if (!$audioEnabled) {
                $this->closeRoomAudio($roomId, self::LEFT_STATUS);
            }
            return;
        }

        $statement = $this->pdo->prepare(
            'UPDATE rooms
             SET audio_enabled = :audio_enabled,
                 host_user_id = NULL,
                 agora_channel_name = :agora_channel_name,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'audio_enabled' => $audioEnabled ? 1 : 0,
            'agora_channel_name' => $agoraChannelName,
            'updated_at' => $this->now(),
            'id' => $roomId,
        ]);

        if (!$audioEnabled) {
            $this->closeRoomAudio($roomId, self::LEFT_STATUS);
        }
    }

    public function adminUpdateParticipant(
        int $roomId,
        int $participantId,
        string $role,
        ?int $seatNumber,
        bool $micMuted
    ): void {
        if (!in_array($role, [self::ROLE_HOST, self::ROLE_SPEAKER, self::ROLE_LISTENER], true)) {
            throw new ApiException('Invalid participant role.', 422);
        }

        if ($seatNumber !== null && ($seatNumber < 1 || $seatNumber > 15)) {
            throw new ApiException('Invalid seat number.', 422);
        }

        if ($role === self::ROLE_LISTENER) {
            $seatNumber = null;
        }

        $participant = $this->findParticipantById($participantId);
        if ($participant === null || (int) $participant['room_id'] !== $roomId) {
            throw new ApiException('Participant not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'UPDATE room_audio_participants
             SET role = :role,
                 seat_number = :seat_number,
                 mic_muted = :mic_muted,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'role' => $role,
            'seat_number' => $seatNumber,
            'mic_muted' => $micMuted ? 1 : 0,
            'updated_at' => $this->now(),
            'id' => $participantId,
        ]);

        if ($role === self::ROLE_LISTENER && $participant['user_id'] !== null) {
            $this->clearApprovedSeatRequests($roomId, (int) $participant['user_id']);
        }

        if ($role === self::ROLE_HOST && $participant['user_id'] !== null) {
            $room = $this->requireRoom($roomId);
            $statement = $this->pdo->prepare(
                'UPDATE rooms
                 SET host_user_id = :host_user_id,
                     host_name = :host_name,
                     host_avatar_asset = :host_avatar_asset,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'host_user_id' => (int) $participant['user_id'],
                'host_name' => (string) ($participant['display_name'] ?? $room['host_name']),
                'host_avatar_asset' => (string) ($participant['avatar_asset'] ?? $room['host_avatar_asset']),
                'updated_at' => $this->now(),
                'id' => $roomId,
            ]);
        }
    }

    public function adminKickParticipant(int $roomId, int $participantId): void
    {
        $participant = $this->findParticipantById($participantId);
        if ($participant === null || (int) $participant['room_id'] !== $roomId) {
            throw new ApiException('Participant not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'UPDATE room_audio_participants
             SET status = :status, left_at = :left_at, updated_at = :updated_at
             WHERE id = :id'
        );
        $now = $this->now();
        $statement->execute([
            'status' => self::KICKED_STATUS,
            'left_at' => $now,
            'updated_at' => $now,
            'id' => $participantId,
        ]);

        $this->syncRoomListenerCount($roomId);
    }

    public function adminCloseRoomAudio(int $roomId): void
    {
        $this->closeRoomAudio($roomId, self::LEFT_STATUS);
    }

    public function refreshAudioPresence(?int $roomId = null): void
    {
        if ($roomId !== null) {
            $this->cleanupStaleParticipants($roomId);
            $this->syncRoomListenerCount($roomId);
            return;
        }

        $statement = $this->pdo->query('SELECT id FROM rooms');
        foreach ($statement->fetchAll() as $room) {
            $id = (int) $room['id'];
            $this->cleanupStaleParticipants($id);
            $this->syncRoomListenerCount($id);
        }
    }

    public function isConfigured(): bool
    {
        return trim((string) ($this->config['agora']['app_id'] ?? '')) !== '';
    }

    public function configurationStatus(): array
    {
        return [
            'configured' => $this->isConfigured(),
            'uses_tokens' => trim((string) ($this->config['agora']['app_certificate'] ?? '')) !== '',
            'token_expires_in_seconds' => (int) ($this->config['agora']['token_expire_seconds'] ?? 3600),
        ];
    }

    private function buildSessionPayload(int $roomId, string $userAccount): array
    {
        $room = $this->requireRoom($roomId);
        $participant = $this->requireParticipant($roomId, $userAccount);
        $this->ensureRoomAudioAvailable($room);
        $usesTokens = trim((string) ($this->config['agora']['app_certificate'] ?? '')) !== '';
        $appId = trim((string) ($this->config['agora']['app_id'] ?? ''));
        $tokenExpireInSeconds = max(300, (int) ($this->config['agora']['token_expire_seconds'] ?? 3600));
        $channelName = (string) ($room['agora_channel_name'] ?? '');
        if ($channelName === '') {
            $channelName = $this->defaultChannelName($room);
        }

        $role = (string) ($participant['role'] ?? self::ROLE_LISTENER);
        $token = '';
        if ($appId !== '' && $usesTokens) {
            $token = AgoraRtcTokenBuilder::buildTokenWithUserAccount(
                $appId,
                trim((string) ($this->config['agora']['app_certificate'] ?? '')),
                $channelName,
                $userAccount,
                $role === self::ROLE_LISTENER
                    ? AgoraRtcTokenBuilder::ROLE_SUBSCRIBER
                    : AgoraRtcTokenBuilder::ROLE_PUBLISHER,
                $tokenExpireInSeconds,
                $tokenExpireInSeconds
            );
        }

        $participants = $this->listParticipants($roomId);
        return [
            'enabled' => ((int) ($room['audio_enabled'] ?? 0)) === 1,
            'configured' => $appId !== '',
            'uses_tokens' => $usesTokens,
            'app_id' => $appId,
            'channel_name' => $channelName,
            'token' => $token,
            'token_expires_in_seconds' => $tokenExpireInSeconds,
            'user_account' => $userAccount,
            'role' => $role,
            'client_role' => $role === self::ROLE_LISTENER ? 'audience' : 'broadcaster',
            'seat_number' => $participant['seat_number'] === null ? null : (int) $participant['seat_number'],
            'mic_muted' => ((int) ($participant['mic_muted'] ?? 0)) === 1,
            'participants' => $participants,
        ];
    }

    private function promoteHostParticipant(int $roomId, int $hostUserId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE room_audio_participants
             SET role = :role, mic_muted = 0, updated_at = :updated_at
             WHERE room_id = :room_id AND user_id = :user_id'
        );
        $statement->execute([
            'role' => self::ROLE_HOST,
            'updated_at' => $this->now(),
            'room_id' => $roomId,
            'user_id' => $hostUserId,
        ]);
    }

    private function normalizeParticipant(array $participant): array
    {
        return [
            'id' => (int) $participant['id'],
            'room_id' => (int) $participant['room_id'],
            'user_id' => $participant['user_id'] === null ? null : (int) $participant['user_id'],
            'user_account' => (string) $participant['user_account'],
            'display_name' => (string) $participant['display_name'],
            'avatar_asset' => (string) ($participant['avatar_asset'] ?: 'assets/images/profile_avatar.png'),
            'role' => (string) $participant['role'],
            'seat_number' => $participant['seat_number'] === null ? null : (int) $participant['seat_number'],
            'mic_muted' => ((int) ($participant['mic_muted'] ?? 0)) === 1,
            'status' => (string) $participant['status'],
            'joined_at' => (string) $participant['joined_at'],
            'last_seen_at' => (string) $participant['last_seen_at'],
        ];
    }

    private function ensureRoomAudioAvailable(array $room): void
    {
        if ((string) ($room['status'] ?? 'active') !== 'active') {
            throw new ApiException('Room is not active.', 410);
        }

        if ((int) ($room['audio_enabled'] ?? 0) !== 1) {
            throw new ApiException('Audio is disabled for this room.', 422);
        }
    }

    private function requireRoom(int $roomId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM rooms WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $roomId]);
        $room = $statement->fetch();

        if ($room === false) {
            throw new ApiException('Room not found.', 404);
        }

        return $room;
    }

    private function findParticipantById(int $participantId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM room_audio_participants WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $participantId]);
        $participant = $statement->fetch();

        return $participant === false ? null : $participant;
    }

    private function requireParticipant(int $roomId, string $userAccount): array
    {
        $participant = $this->findParticipantByUserAccount($roomId, $userAccount);
        if ($participant === null) {
            throw new ApiException('Audio session was not found for this user.', 404);
        }

        return $participant;
    }

    private function findParticipantByUserAccount(int $roomId, string $userAccount): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM room_audio_participants
             WHERE room_id = :room_id AND user_account = :user_account
             LIMIT 1'
        );
        $statement->execute([
            'room_id' => $roomId,
            'user_account' => $userAccount,
        ]);
        $participant = $statement->fetch();

        return $participant === false ? null : $participant;
    }

    private function requireAuthenticatedUser(?string $authorizationHeader): array
    {
        if ($authorizationHeader === null || !preg_match('/Bearer\s+(.+)/i', $authorizationHeader, $matches)) {
            throw new ApiException('Authentication required.', 401);
        }

        $hashedToken = hash('sha256', trim((string) ($matches[1] ?? '')));
        $statement = $this->pdo->prepare(
            'SELECT users.*
             FROM auth_tokens
             INNER JOIN users ON users.id = auth_tokens.user_id
             WHERE auth_tokens.token_hash = :token_hash
               AND (auth_tokens.expires_at IS NULL OR auth_tokens.expires_at > :now)
             LIMIT 1'
        );
        $statement->execute([
            'token_hash' => $hashedToken,
            'now' => $this->now(),
        ]);
        $user = $statement->fetch();

        if ($user === false) {
            throw new ApiException('Authentication required.', 401);
        }

        return $user;
    }

    private function resolveUserRole(array $room, array $user, int $roomId): string
    {
        if (
            isset($room['host_user_id']) &&
            $room['host_user_id'] !== null &&
            (int) $room['host_user_id'] === (int) $user['id']
        ) {
            return self::ROLE_HOST;
        }

        $participant = $this->findParticipantByUserAccount($roomId, $this->userAccount((int) $user['id']));
        if ($participant !== null && in_array((string) ($participant['role'] ?? ''), [self::ROLE_HOST, self::ROLE_SPEAKER], true)) {
            return (string) $participant['role'];
        }

        $statement = $this->pdo->prepare(
            'SELECT seat_number
             FROM room_seat_requests
             WHERE room_id = :room_id AND user_id = :user_id AND status = :status
             ORDER BY updated_at DESC, id DESC
             LIMIT 1'
        );
        $statement->execute([
            'room_id' => $roomId,
            'user_id' => (int) $user['id'],
            'status' => 'approved',
        ]);
        $approved = $statement->fetch();

        return $approved === false ? self::ROLE_LISTENER : self::ROLE_SPEAKER;
    }

    private function resolveAssignedSeatNumber(array $room, array $user, int $roomId, string $role): ?int
    {
        if ($role === self::ROLE_LISTENER) {
            return null;
        }

        if ($role === self::ROLE_HOST) {
            return null;
        }

        $statement = $this->pdo->prepare(
            'SELECT seat_number
             FROM room_seat_requests
             WHERE room_id = :room_id AND user_id = :user_id AND status = :status
             ORDER BY updated_at DESC, id DESC
             LIMIT 1'
        );
        $statement->execute([
            'room_id' => $roomId,
            'user_id' => (int) $user['id'],
            'status' => 'approved',
        ]);
        $approved = $statement->fetch();
        if ($approved !== false && isset($approved['seat_number'])) {
            return (int) $approved['seat_number'];
        }

        $participant = $this->findParticipantByUserAccount($roomId, $this->userAccount((int) $user['id']));
        if ($participant !== null && $participant['seat_number'] !== null) {
            return (int) $participant['seat_number'];
        }

        return null;
    }

    private function cleanupStaleParticipants(int $roomId): void
    {
        $ttl = max(30, (int) ($this->config['agora']['presence_ttl_seconds'] ?? 90));
        $cutoff = gmdate('Y-m-d H:i:s', time() - $ttl);

        $statement = $this->pdo->prepare(
            'UPDATE room_audio_participants
             SET status = :left_status, left_at = :left_at, updated_at = :updated_at
             WHERE room_id = :room_id
               AND status = :active_status
               AND last_seen_at < :cutoff'
        );
        $now = $this->now();
        $statement->execute([
            'left_status' => self::LEFT_STATUS,
            'left_at' => $now,
            'updated_at' => $now,
            'room_id' => $roomId,
            'active_status' => self::ACTIVE_STATUS,
            'cutoff' => $cutoff,
        ]);
    }

    private function closeRoomAudio(int $roomId, string $status): void
    {
        $now = $this->now();
        $statement = $this->pdo->prepare(
            'UPDATE room_audio_participants
             SET status = :status,
                 mic_muted = 1,
                 left_at = :left_at,
                 last_seen_at = :last_seen_at,
                 updated_at = :updated_at
             WHERE room_id = :room_id
               AND status = :active_status'
        );
        $statement->execute([
            'status' => $status,
            'left_at' => $now,
            'last_seen_at' => $now,
            'updated_at' => $now,
            'room_id' => $roomId,
            'active_status' => self::ACTIVE_STATUS,
        ]);

        $this->syncRoomListenerCount($roomId);
    }

    private function clearApprovedSeatRequests(int $roomId, int $userId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE room_seat_requests
             SET status = :status,
                 updated_at = :updated_at
             WHERE room_id = :room_id
               AND user_id = :user_id
               AND status = :approved_status'
        );
        $statement->execute([
            'status' => 'rejected',
            'updated_at' => $this->now(),
            'room_id' => $roomId,
            'user_id' => $userId,
            'approved_status' => 'approved',
        ]);
    }

    private function syncRoomListenerCount(int $roomId): void
    {
        $statement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM room_audio_participants
             WHERE room_id = :room_id AND status = :status'
        );
        $statement->execute([
            'room_id' => $roomId,
            'status' => self::ACTIVE_STATUS,
        ]);
        $count = (int) $statement->fetchColumn();

        $statement = $this->pdo->prepare(
            'UPDATE rooms
             SET listener_count = :listener_count, updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'listener_count' => $count,
            'updated_at' => $this->now(),
            'id' => $roomId,
        ]);
    }

    private function sanitizeChannelName(string $value): string
    {
        $value = trim($value);
        $value = preg_replace('/[^a-zA-Z0-9!#$%&()+\\-:;<=>.?@\\[\\]^_{}|~,]/', '-', $value) ?? '';
        return substr($value, 0, 63);
    }

    private function defaultChannelName(array $room): string
    {
        $roomCode = preg_replace('/[^a-zA-Z0-9]/', '', (string) ($room['room_code'] ?? '')) ?? '';
        return 'voice-room-' . ($roomCode !== '' ? $roomCode : (string) $room['id']);
    }

    private function userAccount(int $userId): string
    {
        return 'user-' . $userId;
    }

    private function userDisplayName(array $user): string
    {
        $nickname = trim((string) ($user['nickname'] ?? ''));
        if ($nickname !== '') {
            return $nickname;
        }

        return trim((string) ($user['email'] ?? 'Guest'));
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
