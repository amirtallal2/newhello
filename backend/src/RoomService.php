<?php

declare(strict_types=1);

final class RoomService
{
    private const ALLOWED_MIC_COUNTS = [5, 9, 12, 15];
    private const ALLOWED_ROOM_TYPES = ['دردشة', 'غناء', 'حب', 'عائلة', 'مزيكا'];
    private const ALLOWED_LIST_SCOPES = ['hashtag', 'newest', 'friends'];
    private const DEFAULT_ROOM_CARD_IMAGE = 'assets/images/home_room_service.png';
    private const DEFAULT_ROOM_META_ICON = 'assets/images/profile_country_flag.png';
    private const DEFAULT_ROOM_BACKGROUND = 'assets/images/room_background.jpg';

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function listRooms(string $scope = 'newest', ?string $authorizationHeader = null): array
    {
        $scope = in_array($scope, self::ALLOWED_LIST_SCOPES, true) ? $scope : 'newest';
        $viewer = $this->resolveUserFromAuthorization($authorizationHeader);
        $viewerUserId = $viewer !== null ? (int) $viewer['id'] : null;
        $friendIds = $viewerUserId !== null ? $this->socialFriendIds($viewerUserId) : [];

        $statement = $this->pdo->query(
            'SELECT *
             FROM rooms
             WHERE status = "active"'
        );

        $rooms = [];
        foreach ($statement->fetchAll() as $room) {
            $hostUserId = isset($room['host_user_id']) && $room['host_user_id'] !== null
                ? (int) $room['host_user_id']
                : null;
            $creatorUserId = isset($room['creator_user_id']) && $room['creator_user_id'] !== null
                ? (int) $room['creator_user_id']
                : null;

            if (
                $scope === 'friends'
                && !in_array($hostUserId, $friendIds, true)
                && !in_array($creatorUserId, $friendIds, true)
            ) {
                continue;
            }

            $rooms[] = $room;
        }

        $hashtagWeights = $scope === 'hashtag'
            ? $this->buildHashtagWeights($rooms)
            : [];

        usort(
            $rooms,
            fn (array $left, array $right): int => $this->compareListRooms(
                $left,
                $right,
                $scope,
                $hashtagWeights
            )
        );

        return array_map(fn (array $room): array => $this->mapRoom($room), $rooms);
    }

    public function getRoom(int $roomId): array
    {
        $room = $this->findRoomById($roomId);

        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        return $this->mapRoom($room);
    }

    public function updateMicCount(int $roomId, int $micCount): array
    {
        if (!in_array($micCount, self::ALLOWED_MIC_COUNTS, true)) {
            throw new ApiException('Invalid mic count.', 422);
        }

        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'UPDATE rooms
             SET mic_count = :mic_count, updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'mic_count' => $micCount,
            'updated_at' => $this->now(),
            'id' => $roomId,
        ]);

        return $this->getRoom($roomId);
    }

    public function createRoom(
        string $roomName,
        string $roomType,
        string $sloganText,
        string $countryLabel,
        ?string $authorizationHeader,
        ?string $cardImageAsset = null,
        ?array $cardImageUpload = null
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $roomName = trim($roomName);
        $roomType = trim($roomType);
        $sloganText = trim($sloganText);
        $countryLabel = trim($countryLabel);

        if ($roomName === '') {
            throw new ApiException('Room name is required.', 422);
        }

        if (!in_array($roomType, self::ALLOWED_ROOM_TYPES, true)) {
            throw new ApiException('Invalid room type.', 422);
        }

        if ($countryLabel === '') {
            throw new ApiException('Country is required.', 422);
        }

        if (mb_strlen($roomName) > 190) {
            throw new ApiException('Room name is too long.', 422);
        }

        if (mb_strlen($sloganText) > 255) {
            throw new ApiException('Room slogan is too long.', 422);
        }

        if (mb_strlen($countryLabel) > 120) {
            throw new ApiException('Country label is too long.', 422);
        }

        $roomCode = $this->generateUniqueRoomCode();
        $hostName = $this->resolveHostName($user);
        $cardImagePath = $cardImageUpload !== null
            ? $this->storeRoomImageDraft($cardImageUpload)
            : $this->sanitizeRoomImagePath($cardImageAsset);
        $metaIconAsset = $this->metaIconForCountry($countryLabel);
        $hostAvatarAsset = $this->resolveHostAvatar($user);
        $displayOrder = (int) $this->pdo->query('SELECT COALESCE(MAX(display_order), 0) + 1 FROM rooms')->fetchColumn();
        $now = $this->now();

        $statement = $this->pdo->prepare(
            'INSERT INTO rooms
                (card_title, room_title, subtitle, host_name, host_user_id, creator_user_id, room_type, slogan_text, country_label, room_code, card_image_asset, meta_icon_asset, host_avatar_asset, listener_count, mic_count, background_asset, audio_enabled, agora_channel_name, status, display_order, created_at, updated_at)
             VALUES
                (:card_title, :room_title, :subtitle, :host_name, :host_user_id, :creator_user_id, :room_type, :slogan_text, :country_label, :room_code, :card_image_asset, :meta_icon_asset, :host_avatar_asset, :listener_count, :mic_count, :background_asset, :audio_enabled, :agora_channel_name, :status, :display_order, :created_at, :updated_at)'
        );
        $statement->execute([
            'card_title' => $roomName,
            'room_title' => $roomName,
            'subtitle' => $sloganText !== '' ? $sloganText : 'اهلا وسهلا بكم في غرفتي',
            'host_name' => $hostName,
            'host_user_id' => (int) $user['id'],
            'creator_user_id' => (int) $user['id'],
            'room_type' => $roomType,
            'slogan_text' => $sloganText,
            'country_label' => $countryLabel,
            'room_code' => $roomCode,
            'card_image_asset' => $cardImagePath,
            'meta_icon_asset' => $metaIconAsset,
            'host_avatar_asset' => $hostAvatarAsset,
            'listener_count' => 1,
            'mic_count' => 9,
            'background_asset' => self::DEFAULT_ROOM_BACKGROUND,
            'audio_enabled' => 1,
            'agora_channel_name' => 'voice-room-' . $roomCode,
            'status' => 'active',
            'display_order' => max(1, $displayOrder),
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return $this->getRoom((int) $this->pdo->lastInsertId());
    }

    public function createSeatRequest(int $roomId, int $seatNumber, ?string $authorizationHeader): array
    {
        if ($seatNumber < 1 || $seatNumber > 15) {
            throw new ApiException('Invalid seat number.', 422);
        }

        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        $user = $this->resolveUserFromAuthorization($authorizationHeader);
        $requesterName = $user['nickname'] ?? $user['email'] ?? 'Mohammed Ahmed';
        $requesterAvatar = $user['avatar_asset'] ?? 'assets/images/profile_avatar.png';

        $existing = $this->findPendingSeatRequest($roomId, $seatNumber, $requesterName);
        if ($existing !== null) {
            return $this->mapSeatRequest($existing);
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO room_seat_requests
                (room_id, user_id, requester_name, requester_avatar_asset, seat_number, status, created_at, updated_at)
             VALUES
                (:room_id, :user_id, :requester_name, :requester_avatar_asset, :seat_number, :status, :created_at, :updated_at)'
        );
        $now = $this->now();
        $statement->execute([
            'room_id' => $roomId,
            'user_id' => $user['id'] ?? null,
            'requester_name' => $requesterName,
            'requester_avatar_asset' => $requesterAvatar,
            'seat_number' => $seatNumber,
            'status' => 'pending',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $requestId = (int) $this->pdo->lastInsertId();

        return $this->getSeatRequestById($requestId);
    }

    public function listSeatRequests(int $roomId, ?int $seatNumber = null): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        $sql = 'SELECT *
                FROM room_seat_requests
                WHERE room_id = :room_id AND status = :status';
        $params = [
            'room_id' => $roomId,
            'status' => 'pending',
        ];

        if ($seatNumber !== null) {
            $sql .= ' AND seat_number = :seat_number';
            $params['seat_number'] = $seatNumber;
        }

        $sql .= ' ORDER BY created_at DESC, id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $requests = [];
        foreach ($statement->fetchAll() as $request) {
            $requests[] = $this->mapSeatRequest($request);
        }

        return $requests;
    }

    public function approveSeatRequest(int $roomId, int $requestId): array
    {
        return $this->changeSeatRequestStatus($roomId, $requestId, 'approved');
    }

    public function rejectSeatRequest(int $roomId, int $requestId): array
    {
        return $this->changeSeatRequestStatus($roomId, $requestId, 'rejected');
    }

    public function adminRoomStats(): array
    {
        return [
            'rooms' => (int) $this->pdo->query('SELECT COUNT(*) FROM rooms')->fetchColumn(),
            'active_rooms' => (int) $this->pdo->query('SELECT COUNT(*) FROM rooms WHERE status = "active"')->fetchColumn(),
            'pending_seat_requests' => (int) $this->pdo->query(
                'SELECT COUNT(*) FROM room_seat_requests WHERE status = "pending"'
            )->fetchColumn(),
        ];
    }

    public function adminListRooms(string $search = ''): array
    {
        $sql = 'SELECT rooms.*,
                       (
                           SELECT COUNT(*)
                           FROM room_seat_requests
                           WHERE room_id = rooms.id AND status = "pending"
                       ) AS pending_requests_count,
                       (
                           SELECT COUNT(*)
                           FROM room_audio_participants
                           WHERE room_id = rooms.id AND status = "joined"
                       ) AS active_audio_participants_count
                FROM rooms';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE card_title LIKE :search OR room_title LIKE :search OR host_name LIKE :search OR room_type LIKE :search OR country_label LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function updateRoomAdmin(
        int $roomId,
        string $cardTitle,
        string $roomTitle,
        string $subtitle,
        string $roomType,
        string $sloganText,
        string $countryLabel,
        string $hostName,
        string $roomCode,
        string $cardImageAsset,
        string $metaIconAsset,
        string $backgroundAsset,
        int $listenerCount,
        int $micCount,
        string $status
    ): void {
        if (
            $cardTitle === '' ||
            $roomTitle === '' ||
            $hostName === '' ||
            $roomCode === '' ||
            $roomType === '' ||
            $countryLabel === ''
        ) {
            throw new ApiException('Missing required room fields.', 422);
        }

        if (!in_array($micCount, self::ALLOWED_MIC_COUNTS, true)) {
            throw new ApiException('Invalid mic count.', 422);
        }

        if (!in_array($roomType, self::ALLOWED_ROOM_TYPES, true)) {
            throw new ApiException('Invalid room type.', 422);
        }

        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid room status.', 422);
        }

        $cardImageAsset = $this->sanitizeRoomImagePath($cardImageAsset);
        $metaIconAsset = $this->sanitizeAuxiliaryMediaPath($metaIconAsset, self::DEFAULT_ROOM_META_ICON);
        $backgroundAsset = $this->sanitizeAuxiliaryMediaPath($backgroundAsset, self::DEFAULT_ROOM_BACKGROUND);

        $statement = $this->pdo->prepare(
            'UPDATE rooms
             SET card_title = :card_title,
                 room_title = :room_title,
                 subtitle = :subtitle,
                 room_type = :room_type,
                 slogan_text = :slogan_text,
                 country_label = :country_label,
                 host_name = :host_name,
                 room_code = :room_code,
                 card_image_asset = :card_image_asset,
                 meta_icon_asset = :meta_icon_asset,
                 background_asset = :background_asset,
                 listener_count = :listener_count,
                 mic_count = :mic_count,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'card_title' => $cardTitle,
            'room_title' => $roomTitle,
            'subtitle' => $subtitle,
            'room_type' => $roomType,
            'slogan_text' => $sloganText,
            'country_label' => $countryLabel,
            'host_name' => $hostName,
            'room_code' => $roomCode,
            'card_image_asset' => $cardImageAsset,
            'meta_icon_asset' => $metaIconAsset,
            'background_asset' => $backgroundAsset,
            'listener_count' => max(0, $listenerCount),
            'mic_count' => $micCount,
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $roomId,
        ]);
    }

    private function changeSeatRequestStatus(int $roomId, int $requestId, string $status): array
    {
        $request = $this->findSeatRequestById($requestId);
        if ($request === null || (int) $request['room_id'] !== $roomId) {
            throw new ApiException('Seat request not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'UPDATE room_seat_requests
             SET status = :status, updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $requestId,
        ]);

        return $this->getSeatRequestById($requestId);
    }

    private function getSeatRequestById(int $requestId): array
    {
        $request = $this->findSeatRequestById($requestId);

        if ($request === null) {
            throw new ApiException('Seat request not found.', 404);
        }

        return $this->mapSeatRequest($request);
    }

    private function findRoomById(int $roomId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM rooms WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $roomId]);
        $room = $statement->fetch();

        return $room === false ? null : $room;
    }

    private function findSeatRequestById(int $requestId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM room_seat_requests WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $requestId]);
        $request = $statement->fetch();

        return $request === false ? null : $request;
    }

    private function compareListRooms(
        array $left,
        array $right,
        string $scope,
        array $hashtagWeights
    ): int {
        if ($scope === 'hashtag') {
            return $this->compareRoomScores(
                $this->hashtagScore($right, $hashtagWeights),
                $this->hashtagScore($left, $hashtagWeights),
                $right,
                $left
            );
        }

        if ($scope === 'friends') {
            return $this->compareRoomScores(
                $this->friendRoomScore($right),
                $this->friendRoomScore($left),
                $right,
                $left
            );
        }

        return $this->compareRoomScores(
            $this->newestRoomScore($right),
            $this->newestRoomScore($left),
            $right,
            $left
        );
    }

    private function compareRoomScores(int $rightScore, int $leftScore, array $right, array $left): int
    {
        if ($rightScore !== $leftScore) {
            return $rightScore <=> $leftScore;
        }

        $rightCreatedAt = strtotime((string) ($right['created_at'] ?? '')) ?: 0;
        $leftCreatedAt = strtotime((string) ($left['created_at'] ?? '')) ?: 0;
        if ($rightCreatedAt !== $leftCreatedAt) {
            return $rightCreatedAt <=> $leftCreatedAt;
        }

        return ((int) ($right['id'] ?? 0)) <=> ((int) ($left['id'] ?? 0));
    }

    private function newestRoomScore(array $room): int
    {
        $createdAt = strtotime((string) ($room['created_at'] ?? '')) ?: 0;
        return $createdAt + ((int) ($room['listener_count'] ?? 0) * 60);
    }

    private function friendRoomScore(array $room): int
    {
        $createdAt = strtotime((string) ($room['created_at'] ?? '')) ?: 0;
        return $createdAt
            + ((int) ($room['listener_count'] ?? 0) * 90)
            + ((int) ($room['mic_count'] ?? 0) * 30);
    }

    private function hashtagScore(array $room, array $hashtagWeights): int
    {
        $score = ((int) ($room['listener_count'] ?? 0) * 120)
            + ((int) ($room['mic_count'] ?? 0) * 35);

        foreach ($this->roomTokens($room) as $token) {
            $score += (int) ($hashtagWeights[$token] ?? 0);
        }

        $createdAt = strtotime((string) ($room['created_at'] ?? '')) ?: 0;
        $ageHours = max(0, (int) floor((time() - $createdAt) / 3600));
        $score += max(0, 72 - $ageHours) * 20;

        return $score;
    }

    private function buildHashtagWeights(array $rooms): array
    {
        $weights = [];
        foreach ($rooms as $room) {
            $roomWeight = 1 + max(0, (int) ($room['listener_count'] ?? 0));
            foreach (array_unique($this->roomTokens($room)) as $token) {
                $weights[$token] = ($weights[$token] ?? 0) + $roomWeight;
            }
        }

        return $weights;
    }

    /**
     * Treat room type, country and meaningful words as hashtag signals.
     *
     * This avoids needing a new table while still ranking active trends.
     */
    private function roomTokens(array $room): array
    {
        $text = implode(' ', [
            (string) ($room['room_type'] ?? ''),
            (string) ($room['country_label'] ?? ''),
            (string) ($room['card_title'] ?? ''),
            (string) ($room['room_title'] ?? ''),
            (string) ($room['subtitle'] ?? ''),
            (string) ($room['slogan_text'] ?? ''),
        ]);

        $text = mb_strtolower($text);
        $text = preg_replace('/[^\p{L}\p{N}#]+/u', ' ', $text) ?? '';
        $parts = preg_split('/\s+/u', trim($text)) ?: [];
        $stopWords = [
            'في' => true,
            'من' => true,
            'عن' => true,
            'على' => true,
            'الى' => true,
            'إلى' => true,
            'مع' => true,
            'انا' => true,
            'أريد' => true,
            'اريد' => true,
            'اهلا' => true,
            'وسهلا' => true,
            'مرحبا' => true,
            'روم' => true,
            'غرفة' => true,
            'الان' => true,
            'الآن' => true,
        ];

        $tokens = [];
        foreach ($parts as $part) {
            $token = trim($part, "# \t\n\r\0\x0B");
            if ($token === '' || mb_strlen($token) < 2 || isset($stopWords[$token])) {
                continue;
            }
            $tokens[] = $token;
        }

        return $tokens;
    }

    private function socialFriendIds(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT outgoing.followed_user_id
             FROM user_follows outgoing
             INNER JOIN user_follows incoming
                 ON incoming.follower_user_id = outgoing.followed_user_id
                AND incoming.followed_user_id = outgoing.follower_user_id
                AND incoming.status = "active"
             INNER JOIN users ON users.id = outgoing.followed_user_id
             WHERE outgoing.follower_user_id = :user_id
               AND outgoing.status = "active"
               AND users.status = "active"'
        );
        $statement->execute(['user_id' => $userId]);

        return array_map(
            static fn (mixed $value): int => (int) $value,
            $statement->fetchAll(PDO::FETCH_COLUMN)
        );
    }

    private function findPendingSeatRequest(int $roomId, int $seatNumber, string $requesterName): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM room_seat_requests
             WHERE room_id = :room_id
               AND seat_number = :seat_number
               AND requester_name = :requester_name
               AND status = :status
             LIMIT 1'
        );
        $statement->execute([
            'room_id' => $roomId,
            'seat_number' => $seatNumber,
            'requester_name' => $requesterName,
            'status' => 'pending',
        ]);
        $request = $statement->fetch();

        return $request === false ? null : $request;
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

    private function mapRoom(array $room): array
    {
        $pendingSeatNumbersStatement = $this->pdo->prepare(
            'SELECT DISTINCT seat_number
             FROM room_seat_requests
             WHERE room_id = :room_id AND status = :status
             ORDER BY seat_number ASC'
        );
        $pendingSeatNumbersStatement->execute([
            'room_id' => (int) $room['id'],
            'status' => 'pending',
        ]);

        $pendingSeatNumbers = array_map(
            static fn (mixed $value): int => (int) $value,
            $pendingSeatNumbersStatement->fetchAll(PDO::FETCH_COLUMN)
        );

        return [
            'id' => (int) $room['id'],
            'card_title' => (string) $room['card_title'],
            'room_title' => (string) $room['room_title'],
            'subtitle' => (string) $room['subtitle'],
            'room_type' => (string) ($room['room_type'] ?? 'غناء'),
            'slogan_text' => (string) ($room['slogan_text'] ?? ''),
            'country_label' => (string) ($room['country_label'] ?? 'مصر'),
            'host_name' => (string) $room['host_name'],
            'room_code' => (string) $room['room_code'],
            'card_image_asset' => (string) $room['card_image_asset'],
            'meta_icon_asset' => (string) $room['meta_icon_asset'],
            'host_avatar_asset' => (string) $room['host_avatar_asset'],
            'listener_count' => (int) $room['listener_count'],
            'mic_count' => (int) $room['mic_count'],
            'background_asset' => (string) $room['background_asset'],
            'audio_enabled' => ((int) ($room['audio_enabled'] ?? 0)) === 1,
            'agora_channel_name' => (string) ($room['agora_channel_name'] ?? ''),
            'host_user_id' => isset($room['host_user_id']) && $room['host_user_id'] !== null ? (int) $room['host_user_id'] : null,
            'creator_user_id' => isset($room['creator_user_id']) && $room['creator_user_id'] !== null ? (int) $room['creator_user_id'] : null,
            'status' => (string) $room['status'],
            'pending_request_seat_numbers' => $pendingSeatNumbers,
        ];
    }

    private function mapSeatRequest(array $request): array
    {
        return [
            'id' => (int) $request['id'],
            'room_id' => (int) $request['room_id'],
            'user_id' => $request['user_id'] === null ? null : (int) $request['user_id'],
            'requester_name' => (string) $request['requester_name'],
            'requester_avatar_asset' => (string) ($request['requester_avatar_asset'] ?: 'assets/images/profile_avatar.png'),
            'seat_number' => (int) $request['seat_number'],
            'status' => (string) $request['status'],
            'created_at' => (string) $request['created_at'],
            'updated_at' => (string) $request['updated_at'],
        ];
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }

    private function requireUser(?string $authorizationHeader): array
    {
        $user = $this->resolveUserFromAuthorization($authorizationHeader);
        if ($user === null) {
            throw new ApiException('Authentication required.', 401);
        }

        return $user;
    }

    private function resolveHostName(array $user): string
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

    private function resolveHostAvatar(array $user): string
    {
        $avatar = trim((string) ($user['avatar_asset'] ?? ''));
        return $avatar !== '' ? $avatar : 'assets/images/profile_avatar.png';
    }

    private function sanitizeRoomImagePath(?string $path): string
    {
        $path = trim((string) $path);
        if ($path === '') {
            return self::DEFAULT_ROOM_CARD_IMAGE;
        }

        if (
            str_starts_with($path, '/storage/rooms/') ||
            str_starts_with($path, 'assets/')
        ) {
            return $path;
        }

        return self::DEFAULT_ROOM_CARD_IMAGE;
    }

    private function sanitizeAuxiliaryMediaPath(?string $path, string $fallback): string
    {
        $path = trim((string) $path);
        if ($path === '') {
            return $fallback;
        }

        if (str_starts_with($path, 'assets/') || str_starts_with($path, '/storage/')) {
            return $path;
        }

        return $fallback;
    }

    private function metaIconForCountry(string $countryLabel): string
    {
        return in_array(trim($countryLabel), ['مصر', 'Egypt'], true)
            ? 'assets/images/home_egypt_flag.png'
            : self::DEFAULT_ROOM_META_ICON;
    }

    private function storeRoomImageDraft(array $draft): string
    {
        $fileName = trim((string) ($draft['filename'] ?? 'room-image'));
        $mimeType = trim((string) ($draft['mime_type'] ?? 'image/jpeg'));
        $content = trim((string) ($draft['content_base64'] ?? ''));

        if ($content === '') {
            throw new ApiException('Invalid room image.', 422);
        }

        if (!in_array($mimeType, ['image/png', 'image/jpeg', 'image/jpg', 'image/webp'], true)) {
            throw new ApiException('Unsupported room image type.', 422);
        }

        $decoded = base64_decode($content, true);
        if ($decoded === false) {
            throw new ApiException('Invalid room image payload.', 422);
        }

        if (strlen($decoded) > 5 * 1024 * 1024) {
            throw new ApiException('Room image is too large.', 422);
        }

        $extension = match ($mimeType) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $directory = dirname(__DIR__) . '/storage/rooms';
        if (!is_dir($directory) && !mkdir($directory, 0777, true) && !is_dir($directory)) {
            throw new ApiException('Failed to create room image storage.', 500);
        }

        $safeName = preg_replace('/[^a-zA-Z0-9_\-]/', '-', pathinfo($fileName, PATHINFO_FILENAME)) ?: 'room';
        $relativePath = '/storage/rooms/' . $safeName . '-' . bin2hex(random_bytes(6)) . '.' . $extension;
        $absolutePath = dirname(__DIR__) . $relativePath;

        if (file_put_contents($absolutePath, $decoded) === false) {
            throw new ApiException('Failed to store room image.', 500);
        }

        return $relativePath;
    }

    private function generateUniqueRoomCode(): string
    {
        for ($attempt = 0; $attempt < 12; $attempt++) {
            $candidate = (string) random_int(1000000000, 9999999999);
            $statement = $this->pdo->prepare('SELECT id FROM rooms WHERE room_code = :room_code LIMIT 1');
            $statement->execute(['room_code' => $candidate]);
            if ($statement->fetch() === false) {
                return $candidate;
            }
        }

        throw new ApiException('Failed to generate room code.', 500);
    }
}
