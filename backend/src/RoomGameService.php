<?php

declare(strict_types=1);

final class RoomGameService
{
    private const STATUS_ACTIVE = 'active';
    private const STATUS_HIDDEN = 'hidden';
    private const SESSION_ACTIVE = 'active';
    private const SESSION_CLOSED = 'closed';
    private const PLAYER_ACTIVE = 'active';
    private const PLAYER_LEFT = 'left';

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function catalog(int $roomId): array
    {
        $this->requireRoom($roomId);

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM room_games_catalog
             WHERE status = :status
             ORDER BY display_order ASC, id ASC'
        );
        $statement->execute(['status' => self::STATUS_ACTIVE]);

        $games = [];
        foreach ($statement->fetchAll() as $game) {
            $games[] = $this->mapCatalogGame($roomId, $game);
        }

        return [
            'room_id' => $roomId,
            'games' => $games,
        ];
    }

    public function lobby(int $roomId, int $gameId, ?string $authorizationHeader): array
    {
        $this->requireRoom($roomId);
        $game = $this->requireGame($gameId);
        $viewer = $this->resolveUserFromAuthorization($authorizationHeader);
        $session = $this->activeSessionRow($roomId, $gameId);

        return [
            'room_id' => $roomId,
            'game' => $this->mapGame($game),
            'active_session' => $session === null ? null : $this->mapSession($session, $viewer),
        ];
    }

    public function joinGame(int $roomId, int $gameId, ?string $authorizationHeader): array
    {
        $this->requireRoom($roomId);
        $game = $this->requireGame($gameId);
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];
        $now = $this->now();

        $this->pdo->beginTransaction();

        try {
            $session = $this->activeSessionRow($roomId, $gameId, true);

            if ($session === null) {
                $insertSession = $this->pdo->prepare(
                    'INSERT INTO room_game_sessions
                        (room_id, game_id, host_user_id, host_name, status, player_count, max_players, created_at, updated_at)
                     VALUES
                        (:room_id, :game_id, :host_user_id, :host_name, :status, :player_count, :max_players, :created_at, :updated_at)'
                );
                $insertSession->execute([
                    'room_id' => $roomId,
                    'game_id' => $gameId,
                    'host_user_id' => $userId,
                    'host_name' => $this->displayNameForUser($user),
                    'status' => self::SESSION_ACTIVE,
                    'player_count' => 1,
                    'max_players' => (int) $game['max_players'],
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
                $sessionId = (int) $this->pdo->lastInsertId();
                $this->insertPlayer($sessionId, $userId, $this->displayNameForUser($user), 1, $now);
            } else {
                $sessionId = (int) $session['id'];
                $player = $this->findActivePlayer($sessionId, $userId, true);
                if ($player === null) {
                    $currentCount = (int) $session['player_count'];
                    $maxPlayers = (int) $session['max_players'];
                    if ($currentCount >= $maxPlayers) {
                        throw new ApiException('الجلسة ممتلئة حاليا.', 422);
                    }

                    $seatNumber = $this->nextSeatNumber($sessionId) ?? ($currentCount + 1);
                    $this->insertPlayer(
                        $sessionId,
                        $userId,
                        $this->displayNameForUser($user),
                        $seatNumber,
                        $now
                    );

                    $updateSession = $this->pdo->prepare(
                        'UPDATE room_game_sessions
                         SET player_count = player_count + 1,
                             updated_at = :updated_at
                         WHERE id = :id'
                    );
                    $updateSession->execute([
                        'updated_at' => $now,
                        'id' => $sessionId,
                    ]);
                }
            }

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            if ($this->pdo->inTransaction()) {
                $this->pdo->rollBack();
            }
            throw $throwable;
        }

        return $this->lobby($roomId, $gameId, $authorizationHeader);
    }

    public function leaveSession(int $roomId, int $sessionId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $session = $this->requireSession($roomId, $sessionId);
        $userId = (int) $user['id'];
        $now = $this->now();

        $this->pdo->beginTransaction();

        try {
            $player = $this->findActivePlayer($sessionId, $userId, true);
            if ($player === null) {
                throw new ApiException('أنت غير منضم إلى هذه الجلسة.', 422);
            }

            $leavePlayer = $this->pdo->prepare(
                'UPDATE room_game_session_players
                 SET status = :status, left_at = :left_at
                 WHERE id = :id'
            );
            $leavePlayer->execute([
                'status' => self::PLAYER_LEFT,
                'left_at' => $now,
                'id' => (int) $player['id'],
            ]);

            $remainingPlayers = $this->countActivePlayers($sessionId);
            $updateSession = $this->pdo->prepare(
                'UPDATE room_game_sessions
                 SET player_count = :player_count,
                     status = :status,
                     ended_at = :ended_at,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $updateSession->execute([
                'player_count' => $remainingPlayers,
                'status' => $remainingPlayers > 0 ? self::SESSION_ACTIVE : self::SESSION_CLOSED,
                'ended_at' => $remainingPlayers > 0 ? null : $now,
                'updated_at' => $now,
                'id' => $sessionId,
            ]);

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            if ($this->pdo->inTransaction()) {
                $this->pdo->rollBack();
            }
            throw $throwable;
        }

        return $this->lobby($roomId, (int) $session['game_id'], $authorizationHeader);
    }

    public function adminStats(): array
    {
        return [
            'catalog_games' => (int) $this->pdo->query('SELECT COUNT(*) FROM room_games_catalog')->fetchColumn(),
            'active_games' => (int) $this->pdo->query('SELECT COUNT(*) FROM room_games_catalog WHERE status = "active"')->fetchColumn(),
            'active_sessions' => (int) $this->pdo->query('SELECT COUNT(*) FROM room_game_sessions WHERE status = "active"')->fetchColumn(),
            'active_players' => (int) $this->pdo->query('SELECT COUNT(*) FROM room_game_session_players WHERE status = "active"')->fetchColumn(),
        ];
    }

    public function adminListGames(string $search = ''): array
    {
        $sql = 'SELECT *
                FROM room_games_catalog
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (name LIKE :search OR game_key LIKE :search OR category_key LIKE :search)';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminUpdateGame(
        int $gameId,
        string $name,
        string $categoryKey,
        int $minPlayers,
        int $maxPlayers,
        string $status,
        int $displayOrder
    ): void {
        $name = trim($name);
        $categoryKey = trim($categoryKey);

        if ($gameId < 1 || $name === '') {
            throw new ApiException('Invalid game data.', 422);
        }

        if (!in_array($categoryKey, ['luck', 'board'], true)) {
            throw new ApiException('Invalid game category.', 422);
        }

        if ($minPlayers < 1 || $maxPlayers < $minPlayers) {
            throw new ApiException('Invalid players limits.', 422);
        }

        if (!in_array($status, [self::STATUS_ACTIVE, self::STATUS_HIDDEN], true)) {
            throw new ApiException('Invalid game status.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE room_games_catalog
             SET name = :name,
                 category_key = :category_key,
                 min_players = :min_players,
                 max_players = :max_players,
                 status = :status,
                 display_order = :display_order,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'name' => $name,
            'category_key' => $categoryKey,
            'min_players' => $minPlayers,
            'max_players' => $maxPlayers,
            'status' => $status,
            'display_order' => $displayOrder,
            'updated_at' => $this->now(),
            'id' => $gameId,
        ]);
    }

    public function adminListSessions(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT room_game_sessions.*,
                       rooms.card_title AS room_title,
                       room_games_catalog.name AS game_name,
                       room_games_catalog.icon_asset
                FROM room_game_sessions
                INNER JOIN rooms ON rooms.id = room_game_sessions.room_id
                INNER JOIN room_games_catalog ON room_games_catalog.id = room_game_sessions.game_id
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                rooms.card_title LIKE :search
                OR room_game_sessions.host_name LIKE :search
                OR room_games_catalog.name LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $status = $status === self::SESSION_CLOSED ? self::SESSION_CLOSED : self::SESSION_ACTIVE;
            $sql .= ' AND room_game_sessions.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY room_game_sessions.created_at DESC, room_game_sessions.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminCloseSession(int $sessionId): void
    {
        $session = $this->findSessionById($sessionId);
        if ($session === null) {
            throw new ApiException('Game session not found.', 404);
        }

        $now = $this->now();
        $this->pdo->beginTransaction();

        try {
            $playerStatement = $this->pdo->prepare(
                'UPDATE room_game_session_players
                 SET status = :status, left_at = COALESCE(left_at, :left_at)
                 WHERE session_id = :session_id AND status = :active_status'
            );
            $playerStatement->execute([
                'status' => self::PLAYER_LEFT,
                'left_at' => $now,
                'session_id' => $sessionId,
                'active_status' => self::PLAYER_ACTIVE,
            ]);

            $sessionStatement = $this->pdo->prepare(
                'UPDATE room_game_sessions
                 SET status = :status,
                     player_count = 0,
                     ended_at = :ended_at,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $sessionStatement->execute([
                'status' => self::SESSION_CLOSED,
                'ended_at' => $now,
                'updated_at' => $now,
                'id' => $sessionId,
            ]);

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            if ($this->pdo->inTransaction()) {
                $this->pdo->rollBack();
            }
            throw $throwable;
        }
    }

    private function mapCatalogGame(int $roomId, array $game): array
    {
        $activeSession = $this->activeSessionRow($roomId, (int) $game['id']);

        return [
            ...$this->mapGame($game),
            'active_session' => $activeSession === null ? null : $this->mapSessionSummary($activeSession),
        ];
    }

    private function mapGame(array $game): array
    {
        return [
            'id' => (int) $game['id'],
            'game_key' => (string) $game['game_key'],
            'name' => (string) $game['name'],
            'category_key' => (string) $game['category_key'],
            'category_label' => $this->categoryLabel((string) $game['category_key']),
            'icon_asset' => (string) $game['icon_asset'],
            'description_text' => (string) $game['description_text'],
            'min_players' => (int) $game['min_players'],
            'max_players' => (int) $game['max_players'],
            'status' => (string) $game['status'],
        ];
    }

    private function mapSession(array $session, ?array $viewer): array
    {
        $viewerId = $viewer === null ? 0 : (int) $viewer['id'];
        $players = $this->sessionPlayers((int) $session['id']);

        return [
            ...$this->mapSessionSummary($session),
            'host_name' => (string) $session['host_name'],
            'players' => $players,
            'is_joined' => $viewerId > 0
                ? array_values(array_filter(
                    $players,
                    static fn (array $player): bool => (int) $player['user_id'] === $viewerId
                )) !== []
                : false,
        ];
    }

    private function mapSessionSummary(array $session): array
    {
        return [
            'id' => (int) $session['id'],
            'room_id' => (int) $session['room_id'],
            'game_id' => (int) $session['game_id'],
            'player_count' => (int) $session['player_count'],
            'max_players' => (int) $session['max_players'],
            'status' => (string) $session['status'],
            'status_label' => (string) $session['status'] === self::SESSION_ACTIVE ? 'نشطة الآن' : 'منتهية',
            'created_at' => (string) $session['created_at'],
        ];
    }

    private function sessionPlayers(int $sessionId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM room_game_session_players
             WHERE session_id = :session_id AND status = :status
             ORDER BY seat_number ASC, id ASC'
        );
        $statement->execute([
            'session_id' => $sessionId,
            'status' => self::PLAYER_ACTIVE,
        ]);

        $players = [];
        foreach ($statement->fetchAll() as $player) {
            $players[] = [
                'id' => (int) $player['id'],
                'user_id' => (int) $player['user_id'],
                'player_name' => (string) $player['player_name'],
                'seat_number' => (int) $player['seat_number'],
                'joined_at' => (string) $player['joined_at'],
            ];
        }

        return $players;
    }

    private function insertPlayer(int $sessionId, int $userId, string $playerName, int $seatNumber, string $now): void
    {
        $insertPlayer = $this->pdo->prepare(
            'INSERT INTO room_game_session_players
                (session_id, user_id, player_name, seat_number, status, joined_at)
             VALUES
                (:session_id, :user_id, :player_name, :seat_number, :status, :joined_at)'
        );
        $insertPlayer->execute([
            'session_id' => $sessionId,
            'user_id' => $userId,
            'player_name' => $playerName,
            'seat_number' => $seatNumber,
            'status' => self::PLAYER_ACTIVE,
            'joined_at' => $now,
        ]);
    }

    private function nextSeatNumber(int $sessionId): ?int
    {
        $statement = $this->pdo->prepare(
            'SELECT seat_number
             FROM room_game_session_players
             WHERE session_id = :session_id AND status = :status
             ORDER BY seat_number ASC'
        );
        $statement->execute([
            'session_id' => $sessionId,
            'status' => self::PLAYER_ACTIVE,
        ]);
        $seats = array_map(static fn ($value): int => (int) $value, $statement->fetchAll(PDO::FETCH_COLUMN));

        $candidate = 1;
        foreach ($seats as $seat) {
            if ($seat !== $candidate) {
                return $candidate;
            }
            $candidate++;
        }

        return $candidate;
    }

    private function countActivePlayers(int $sessionId): int
    {
        $statement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM room_game_session_players
             WHERE session_id = :session_id AND status = :status'
        );
        $statement->execute([
            'session_id' => $sessionId,
            'status' => self::PLAYER_ACTIVE,
        ]);

        return (int) $statement->fetchColumn();
    }

    private function activeSessionRow(int $roomId, int $gameId, bool $forUpdate = false): ?array
    {
        $sql = 'SELECT *
                FROM room_game_sessions
                WHERE room_id = :room_id
                  AND game_id = :game_id
                  AND status = :status
                ORDER BY id DESC
                LIMIT 1';

        if ($forUpdate && $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME) !== 'sqlite') {
            $sql .= ' FOR UPDATE';
        }

        $statement = $this->pdo->prepare($sql);
        $statement->execute([
            'room_id' => $roomId,
            'game_id' => $gameId,
            'status' => self::SESSION_ACTIVE,
        ]);
        $session = $statement->fetch();

        return $session === false ? null : $session;
    }

    private function findActivePlayer(int $sessionId, int $userId, bool $forUpdate = false): ?array
    {
        $sql = 'SELECT *
                FROM room_game_session_players
                WHERE session_id = :session_id
                  AND user_id = :user_id
                  AND status = :status
                LIMIT 1';

        if ($forUpdate && $this->pdo->getAttribute(PDO::ATTR_DRIVER_NAME) !== 'sqlite') {
            $sql .= ' FOR UPDATE';
        }

        $statement = $this->pdo->prepare($sql);
        $statement->execute([
            'session_id' => $sessionId,
            'user_id' => $userId,
            'status' => self::PLAYER_ACTIVE,
        ]);
        $player = $statement->fetch();

        return $player === false ? null : $player;
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

    private function requireGame(int $gameId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM room_games_catalog WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $gameId]);
        $game = $statement->fetch();

        if ($game === false) {
            throw new ApiException('Game not found.', 404);
        }

        if ((string) $game['status'] !== self::STATUS_ACTIVE) {
            throw new ApiException('اللعبة غير متاحة حاليا.', 422);
        }

        return $game;
    }

    private function requireSession(int $roomId, int $sessionId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM room_game_sessions
             WHERE id = :id AND room_id = :room_id
             LIMIT 1'
        );
        $statement->execute([
            'id' => $sessionId,
            'room_id' => $roomId,
        ]);
        $session = $statement->fetch();

        if ($session === false) {
            throw new ApiException('Game session not found.', 404);
        }

        return $session;
    }

    private function findSessionById(int $sessionId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM room_game_sessions WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $sessionId]);
        $session = $statement->fetch();

        return $session === false ? null : $session;
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
               AND (auth_tokens.expires_at IS NULL OR auth_tokens.expires_at > :now)
             LIMIT 1'
        );
        $statement->execute([
            'token_hash' => TokenManager::hash($token),
            'now' => $this->now(),
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
        return $email !== '' ? $email : 'مستخدم Hallo Party';
    }

    private function categoryLabel(string $categoryKey): string
    {
        return match ($categoryKey) {
            'luck' => 'العاب الحظ',
            'board' => 'العاب اللوح',
            default => $categoryKey,
        };
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
