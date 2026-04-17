<?php

declare(strict_types=1);

final class RoomService
{
    private const ALLOWED_MIC_COUNTS = [5, 9, 12, 15];

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function listRooms(): array
    {
        $statement = $this->pdo->query(
            'SELECT *
             FROM rooms
             WHERE status = "active"
             ORDER BY display_order ASC, id ASC'
        );

        $rooms = [];
        foreach ($statement->fetchAll() as $room) {
            $rooms[] = $this->mapRoom($room);
        }

        return $rooms;
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
            'requester_avatar_asset' => 'assets/images/profile_avatar.png',
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
                       ) AS pending_requests_count
                FROM rooms';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE card_title LIKE :search OR room_title LIKE :search OR host_name LIKE :search';
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
        string $hostName,
        string $roomCode,
        int $listenerCount,
        int $micCount,
        string $status
    ): void {
        if ($cardTitle === '' || $roomTitle === '' || $hostName === '' || $roomCode === '') {
            throw new ApiException('Missing required room fields.', 422);
        }

        if (!in_array($micCount, self::ALLOWED_MIC_COUNTS, true)) {
            throw new ApiException('Invalid mic count.', 422);
        }

        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid room status.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE rooms
             SET card_title = :card_title,
                 room_title = :room_title,
                 subtitle = :subtitle,
                 host_name = :host_name,
                 room_code = :room_code,
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
            'host_name' => $hostName,
            'room_code' => $roomCode,
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
            'host_name' => (string) $room['host_name'],
            'room_code' => (string) $room['room_code'],
            'card_image_asset' => (string) $room['card_image_asset'],
            'meta_icon_asset' => (string) $room['meta_icon_asset'],
            'host_avatar_asset' => (string) $room['host_avatar_asset'],
            'listener_count' => (int) $room['listener_count'],
            'mic_count' => (int) $room['mic_count'],
            'background_asset' => (string) $room['background_asset'],
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
}
