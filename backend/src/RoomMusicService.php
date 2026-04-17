<?php

declare(strict_types=1);

final class RoomMusicService
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    public function catalog(string $sourceType = ''): array
    {
        $sql = 'SELECT *
                FROM music_tracks
                WHERE status = "active"';
        $params = [];

        if ($sourceType !== '') {
            $this->assertValidSourceType($sourceType);
            $sql .= ' AND source_type = :source_type';
            $params['source_type'] = $sourceType;
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $tracks = [];
        foreach ($statement->fetchAll() as $track) {
            $tracks[] = $this->mapTrack($track);
        }

        return $tracks;
    }

    public function roomPlaylist(int $roomId): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'SELECT room_music_playlist_entries.*,
                    music_tracks.title,
                    music_tracks.artist_name,
                    music_tracks.source_type,
                    music_tracks.cover_asset,
                    music_tracks.duration_seconds
             FROM room_music_playlist_entries
             INNER JOIN music_tracks ON music_tracks.id = room_music_playlist_entries.track_id
             WHERE room_music_playlist_entries.room_id = :room_id
               AND room_music_playlist_entries.status = "queued"
             ORDER BY room_music_playlist_entries.sort_order ASC, room_music_playlist_entries.id ASC'
        );
        $statement->execute(['room_id' => $roomId]);

        $entries = [];
        foreach ($statement->fetchAll() as $entry) {
            $entries[] = $this->mapPlaylistEntry($entry);
        }

        return [
            'room_id' => $roomId,
            'entries' => $entries,
        ];
    }

    public function addTrackToRoom(
        int $roomId,
        int $trackId,
        ?string $authorizationHeader
    ): array {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        $track = $this->findTrackById($trackId);
        if ($track === null || (string) $track['status'] !== 'active') {
            throw new ApiException('Track not found.', 404);
        }

        $user = $this->resolveUserFromAuthorization($authorizationHeader);
        if ($user === null) {
            throw new ApiException('Authentication required to add music.', 401);
        }

        $statement = $this->pdo->prepare(
            'SELECT COALESCE(MAX(sort_order), 0) + 1
             FROM room_music_playlist_entries
             WHERE room_id = :room_id AND status = "queued"'
        );
        $statement->execute(['room_id' => $roomId]);
        $sortOrder = (int) $statement->fetchColumn();

        $insert = $this->pdo->prepare(
            'INSERT INTO room_music_playlist_entries
                (room_id, track_id, added_by_user_id, added_by_name, source_type, sort_order, status, created_at, updated_at)
             VALUES
                (:room_id, :track_id, :added_by_user_id, :added_by_name, :source_type, :sort_order, :status, :created_at, :updated_at)'
        );
        $now = $this->now();
        $insert->execute([
            'room_id' => $roomId,
            'track_id' => $trackId,
            'added_by_user_id' => $user['id'],
            'added_by_name' => (string) ($user['nickname'] ?: $user['email'] ?: 'Mohammed Ahmed'),
            'source_type' => $track['source_type'],
            'sort_order' => $sortOrder,
            'status' => 'queued',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return $this->roomPlaylist($roomId);
    }

    public function removePlaylistEntry(int $roomId, int $entryId): array
    {
        $entry = $this->findPlaylistEntryById($entryId);
        if ($entry === null || (int) $entry['room_id'] !== $roomId) {
            throw new ApiException('Playlist entry not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'UPDATE room_music_playlist_entries
             SET status = :status, updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => 'removed',
            'updated_at' => $this->now(),
            'id' => $entryId,
        ]);

        return $this->roomPlaylist($roomId);
    }

    public function adminMusicStats(): array
    {
        return [
            'tracks' => (int) $this->pdo->query('SELECT COUNT(*) FROM music_tracks')->fetchColumn(),
            'active_tracks' => (int) $this->pdo->query('SELECT COUNT(*) FROM music_tracks WHERE status = "active"')->fetchColumn(),
            'playlist_entries' => (int) $this->pdo->query(
                'SELECT COUNT(*) FROM room_music_playlist_entries WHERE status = "queued"'
            )->fetchColumn(),
        ];
    }

    public function adminListTracks(string $search = ''): array
    {
        $sql = 'SELECT * FROM music_tracks';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE title LIKE :search OR artist_name LIKE :search OR source_type LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function updateTrackAdmin(
        int $trackId,
        string $title,
        string $artistName,
        string $sourceType,
        int $durationSeconds,
        string $status
    ): void {
        if ($title === '' || $artistName === '' || $durationSeconds < 10) {
            throw new ApiException('Invalid music track data.', 422);
        }

        $this->assertValidSourceType($sourceType);

        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid track status.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE music_tracks
             SET title = :title,
                 artist_name = :artist_name,
                 source_type = :source_type,
                 duration_seconds = :duration_seconds,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'title' => $title,
            'artist_name' => $artistName,
            'source_type' => $sourceType,
            'duration_seconds' => $durationSeconds,
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $trackId,
        ]);
    }

    public function adminRoomPlaylist(int $roomId): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Room not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'SELECT room_music_playlist_entries.*,
                    music_tracks.title,
                    music_tracks.artist_name,
                    music_tracks.cover_asset,
                    music_tracks.duration_seconds
             FROM room_music_playlist_entries
             INNER JOIN music_tracks ON music_tracks.id = room_music_playlist_entries.track_id
             WHERE room_music_playlist_entries.room_id = :room_id
               AND room_music_playlist_entries.status = "queued"
             ORDER BY room_music_playlist_entries.sort_order ASC, room_music_playlist_entries.id ASC'
        );
        $statement->execute(['room_id' => $roomId]);

        return $statement->fetchAll();
    }

    public function adminRemoveRoomPlaylistEntry(int $roomId, int $entryId): void
    {
        $entry = $this->findPlaylistEntryById($entryId);
        if ($entry === null || (int) $entry['room_id'] !== $roomId) {
            throw new ApiException('Playlist entry not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'UPDATE room_music_playlist_entries
             SET status = :status, updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => 'removed',
            'updated_at' => $this->now(),
            'id' => $entryId,
        ]);
    }

    private function mapTrack(array $track): array
    {
        return [
            'id' => (int) $track['id'],
            'title' => (string) $track['title'],
            'artist_name' => (string) $track['artist_name'],
            'source_type' => (string) $track['source_type'],
            'source_label' => $this->sourceLabel((string) $track['source_type']),
            'cover_asset' => (string) $track['cover_asset'],
            'duration_seconds' => (int) $track['duration_seconds'],
            'duration_label' => $this->formatDuration((int) $track['duration_seconds']),
            'status' => (string) $track['status'],
        ];
    }

    private function mapPlaylistEntry(array $entry): array
    {
        return [
            'id' => (int) $entry['id'],
            'room_id' => (int) $entry['room_id'],
            'track_id' => (int) $entry['track_id'],
            'title' => (string) $entry['title'],
            'artist_name' => (string) $entry['artist_name'],
            'source_type' => (string) $entry['source_type'],
            'source_label' => $this->sourceLabel((string) $entry['source_type']),
            'cover_asset' => (string) $entry['cover_asset'],
            'duration_seconds' => (int) $entry['duration_seconds'],
            'duration_label' => $this->formatDuration((int) $entry['duration_seconds']),
            'added_by_name' => (string) $entry['added_by_name'],
            'sort_order' => (int) $entry['sort_order'],
            'status' => (string) $entry['status'],
            'created_at' => (string) $entry['created_at'],
        ];
    }

    private function assertValidSourceType(string $sourceType): void
    {
        if (!in_array($sourceType, ['friends', 'whatsapp'], true)) {
            throw new ApiException('Invalid music source type.', 422);
        }
    }

    private function sourceLabel(string $sourceType): string
    {
        return match ($sourceType) {
            'friends' => 'الاصدقاء',
            'whatsapp' => 'واتساب',
            default => $sourceType,
        };
    }

    private function formatDuration(int $durationSeconds): string
    {
        $minutes = intdiv(max(0, $durationSeconds), 60);
        $seconds = max(0, $durationSeconds) % 60;

        return sprintf('%d:%02d', $minutes, $seconds);
    }

    private function findRoomById(int $roomId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM rooms WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $roomId]);
        $room = $statement->fetch();

        return $room === false ? null : $room;
    }

    private function findTrackById(int $trackId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM music_tracks WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $trackId]);
        $track = $statement->fetch();

        return $track === false ? null : $track;
    }

    private function findPlaylistEntryById(int $entryId): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT * FROM room_music_playlist_entries WHERE id = :id LIMIT 1'
        );
        $statement->execute(['id' => $entryId]);
        $entry = $statement->fetch();

        return $entry === false ? null : $entry;
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
