<?php

declare(strict_types=1);

final class SocialService
{
    private const DEFAULT_AVATAR = 'assets/images/profile_avatar.png';

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function relationship(int $targetUserId, ?string $authorizationHeader): array
    {
        $viewer = $this->requireUser($authorizationHeader);
        $target = $this->requireActiveUser($targetUserId);

        return [
            'user' => $this->mapUserCard($target, (int) $viewer['id']),
            'relationship' => $this->relationshipStatus((int) $viewer['id'], $targetUserId),
        ];
    }

    public function follow(int $targetUserId, ?string $authorizationHeader): array
    {
        $viewer = $this->requireUser($authorizationHeader);
        $target = $this->requireActiveUser($targetUserId);
        $viewerId = (int) $viewer['id'];

        if ($viewerId === $targetUserId) {
            throw new ApiException('You cannot follow yourself.', 422);
        }

        $now = $this->now();
        $existing = $this->pdo->prepare(
            'SELECT id
             FROM user_follows
             WHERE follower_user_id = :follower_user_id
               AND followed_user_id = :followed_user_id
             LIMIT 1'
        );
        $existing->execute([
            'follower_user_id' => $viewerId,
            'followed_user_id' => $targetUserId,
        ]);
        $row = $existing->fetch();

        if ($row === false) {
            $insert = $this->pdo->prepare(
                'INSERT INTO user_follows
                    (follower_user_id, followed_user_id, status, created_at, updated_at)
                 VALUES
                    (:follower_user_id, :followed_user_id, :status, :created_at, :updated_at)'
            );
            $insert->execute([
                'follower_user_id' => $viewerId,
                'followed_user_id' => $targetUserId,
                'status' => 'active',
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        } else {
            $update = $this->pdo->prepare(
                'UPDATE user_follows
                 SET status = :status,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $update->execute([
                'status' => 'active',
                'updated_at' => $now,
                'id' => (int) $row['id'],
            ]);
        }

        $this->syncCounters($viewerId);
        $this->syncCounters($targetUserId);

        return [
            'user' => $this->mapUserCard($target, $viewerId),
            'relationship' => $this->relationshipStatus($viewerId, $targetUserId),
            'viewer_stats' => $this->stats($viewerId),
            'target_stats' => $this->stats($targetUserId),
        ];
    }

    public function unfollow(int $targetUserId, ?string $authorizationHeader): array
    {
        $viewer = $this->requireUser($authorizationHeader);
        $target = $this->requireActiveUser($targetUserId);
        $viewerId = (int) $viewer['id'];

        if ($viewerId === $targetUserId) {
            throw new ApiException('You cannot unfollow yourself.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE user_follows
             SET status = :status,
                 updated_at = :updated_at
             WHERE follower_user_id = :follower_user_id
               AND followed_user_id = :followed_user_id'
        );
        $statement->execute([
            'status' => 'inactive',
            'updated_at' => $this->now(),
            'follower_user_id' => $viewerId,
            'followed_user_id' => $targetUserId,
        ]);

        $this->syncCounters($viewerId);
        $this->syncCounters($targetUserId);

        return [
            'user' => $this->mapUserCard($target, $viewerId),
            'relationship' => $this->relationshipStatus($viewerId, $targetUserId),
            'viewer_stats' => $this->stats($viewerId),
            'target_stats' => $this->stats($targetUserId),
        ];
    }

    public function toggleFollow(int $targetUserId, ?string $authorizationHeader): array
    {
        $viewer = $this->requireUser($authorizationHeader);
        $viewerId = (int) $viewer['id'];
        $target = $this->requireActiveUser($targetUserId);

        if ($viewerId === $targetUserId) {
            return [
                'user' => $this->mapUserCard($target, $viewerId),
                'relationship' => $this->relationshipStatus($viewerId, $targetUserId),
                'viewer_stats' => $this->stats($viewerId),
                'target_stats' => $this->stats($targetUserId),
            ];
        }

        if ($this->isFollowing($viewerId, $targetUserId)) {
            return $this->unfollow($targetUserId, $authorizationHeader);
        }

        return $this->follow($targetUserId, $authorizationHeader);
    }

    public function listConnections(
        string $type,
        ?string $authorizationHeader,
        ?int $targetUserId = null
    ): array {
        $viewer = $this->requireUser($authorizationHeader);
        $viewerId = (int) $viewer['id'];
        $ownerId = $targetUserId !== null && $targetUserId > 0 ? $targetUserId : $viewerId;
        $this->requireActiveUser($ownerId);
        $type = in_array($type, ['following', 'followers', 'friends'], true) ? $type : 'following';

        $sql = match ($type) {
            'followers' => 'SELECT users.*
                            FROM user_follows rel
                            INNER JOIN users ON users.id = rel.follower_user_id
                            WHERE rel.followed_user_id = :owner_user_id
                              AND rel.status = "active"
                              AND users.status = "active"
                            ORDER BY rel.created_at DESC, users.id DESC',
            'friends' => 'SELECT users.*
                          FROM user_follows outgoing
                          INNER JOIN user_follows incoming
                              ON incoming.follower_user_id = outgoing.followed_user_id
                             AND incoming.followed_user_id = outgoing.follower_user_id
                             AND incoming.status = "active"
                          INNER JOIN users ON users.id = outgoing.followed_user_id
                          WHERE outgoing.follower_user_id = :owner_user_id
                            AND outgoing.status = "active"
                            AND users.status = "active"
                          ORDER BY outgoing.created_at DESC, users.id DESC',
            default => 'SELECT users.*
                        FROM user_follows rel
                        INNER JOIN users ON users.id = rel.followed_user_id
                        WHERE rel.follower_user_id = :owner_user_id
                          AND rel.status = "active"
                          AND users.status = "active"
                        ORDER BY rel.created_at DESC, users.id DESC',
        };

        $statement = $this->pdo->prepare($sql);
        $statement->execute(['owner_user_id' => $ownerId]);

        $users = [];
        foreach ($statement->fetchAll() as $row) {
            $users[] = $this->mapUserCard($row, $viewerId);
        }

        return [
            'type' => $type,
            'owner_user_id' => $ownerId,
            'stats' => $this->stats($ownerId),
            'users' => $users,
        ];
    }

    public function searchUsers(string $query, ?string $authorizationHeader): array
    {
        $viewer = $this->requireUser($authorizationHeader);
        $viewerId = (int) $viewer['id'];
        $query = trim($query);

        $sql = 'SELECT *
                FROM users
                WHERE id <> :viewer_user_id
                  AND status = "active"';
        $params = ['viewer_user_id' => $viewerId];

        if ($query !== '') {
            $sql .= ' AND (
                nickname LIKE :query
                OR email LIKE :query
                OR phone LIKE :query
                OR profile_handle LIKE :query
            )';
            $params['query'] = '%' . $query . '%';
        }

        $sql .= ' ORDER BY followers_count DESC, id DESC LIMIT 30';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $users = [];
        foreach ($statement->fetchAll() as $row) {
            $users[] = $this->mapUserCard($row, $viewerId);
        }

        return [
            'query' => $query,
            'users' => $users,
        ];
    }

    public function stats(int $userId): array
    {
        return [
            'following_count' => $this->countFollowing($userId),
            'followers_count' => $this->countFollowers($userId),
            'friends_count' => $this->countFriends($userId),
        ];
    }

    public function relationshipStatus(int $viewerUserId, int $targetUserId): array
    {
        $isSelf = $viewerUserId === $targetUserId;
        $isFollowing = !$isSelf && $this->isFollowing($viewerUserId, $targetUserId);
        $isFollowedBy = !$isSelf && $this->isFollowing($targetUserId, $viewerUserId);
        $isFriend = $isFollowing && $isFollowedBy;

        return [
            'target_user_id' => $targetUserId,
            'is_self' => $isSelf,
            'is_following' => $isFollowing,
            'is_followed_by' => $isFollowedBy,
            'is_friend' => $isFriend,
            'status' => $isSelf
                ? 'self'
                : ($isFriend ? 'friends' : ($isFollowing ? 'following' : ($isFollowedBy ? 'follows_you' : 'none'))),
        ];
    }

    public function followingIds(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT followed_user_id
             FROM user_follows
             WHERE follower_user_id = :user_id
               AND status = "active"'
        );
        $statement->execute(['user_id' => $userId]);

        return array_map('intval', $statement->fetchAll(PDO::FETCH_COLUMN) ?: []);
    }

    public function friendIds(int $userId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT outgoing.followed_user_id
             FROM user_follows outgoing
             INNER JOIN user_follows incoming
                 ON incoming.follower_user_id = outgoing.followed_user_id
                AND incoming.followed_user_id = outgoing.follower_user_id
                AND incoming.status = "active"
             WHERE outgoing.follower_user_id = :user_id
               AND outgoing.status = "active"'
        );
        $statement->execute(['user_id' => $userId]);

        return array_map('intval', $statement->fetchAll(PDO::FETCH_COLUMN) ?: []);
    }

    public function syncCounters(int $userId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE users
             SET following_count = :following_count,
                 followers_count = :followers_count,
                 friends_count = :friends_count,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $stats = $this->stats($userId);
        $statement->execute([
            ...$stats,
            'updated_at' => $this->now(),
            'id' => $userId,
        ]);
    }

    private function mapUserCard(array $user, int $viewerUserId): array
    {
        $userId = (int) $user['id'];

        return [
            'id' => $userId,
            'name' => $this->displayName($user),
            'nickname' => $this->displayName($user),
            'subtitle' => $this->subtitle($user),
            'profile_handle' => (string) (($user['profile_handle'] ?? '') ?: ('ID:' . $userId)),
            'avatar_asset' => (string) (($user['avatar_asset'] ?? '') ?: self::DEFAULT_AVATAR),
            'country' => (string) (($user['country'] ?? '') ?: 'Egypt'),
            'stats' => $this->stats($userId),
            'relationship' => $this->relationshipStatus($viewerUserId, $userId),
        ];
    }

    private function countFollowing(int $userId): int
    {
        $statement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM user_follows
             WHERE follower_user_id = :user_id
               AND status = "active"'
        );
        $statement->execute(['user_id' => $userId]);

        return (int) $statement->fetchColumn();
    }

    private function countFollowers(int $userId): int
    {
        $statement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM user_follows
             WHERE followed_user_id = :user_id
               AND status = "active"'
        );
        $statement->execute(['user_id' => $userId]);

        return (int) $statement->fetchColumn();
    }

    private function countFriends(int $userId): int
    {
        $statement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM user_follows outgoing
             INNER JOIN user_follows incoming
                 ON incoming.follower_user_id = outgoing.followed_user_id
                AND incoming.followed_user_id = outgoing.follower_user_id
                AND incoming.status = "active"
             WHERE outgoing.follower_user_id = :user_id
               AND outgoing.status = "active"'
        );
        $statement->execute(['user_id' => $userId]);

        return (int) $statement->fetchColumn();
    }

    private function isFollowing(int $followerUserId, int $followedUserId): bool
    {
        $statement = $this->pdo->prepare(
            'SELECT 1
             FROM user_follows
             WHERE follower_user_id = :follower_user_id
               AND followed_user_id = :followed_user_id
               AND status = "active"
             LIMIT 1'
        );
        $statement->execute([
            'follower_user_id' => $followerUserId,
            'followed_user_id' => $followedUserId,
        ]);

        return $statement->fetchColumn() !== false;
    }

    private function requireActiveUser(int $userId): array
    {
        if ($userId < 1) {
            throw new ApiException('Invalid user id.', 422);
        }

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM users
             WHERE id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $userId]);
        $user = $statement->fetch();

        if ($user === false) {
            throw new ApiException('User not found.', 404);
        }

        if (($user['status'] ?? 'active') !== 'active') {
            throw new ApiException('This account is suspended.', 403);
        }

        return $user;
    }

    private function requireUser(?string $authorizationHeader): array
    {
        if ($authorizationHeader === null || !preg_match('/Bearer\s+(.+)/i', $authorizationHeader, $matches)) {
            throw new ApiException('Authentication required.', 401);
        }

        $token = trim((string) ($matches[1] ?? ''));
        if ($token === '') {
            throw new ApiException('Authentication required.', 401);
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

        if ($user === false) {
            throw new ApiException('Authentication required.', 401);
        }

        if (($user['status'] ?? 'active') !== 'active') {
            throw new ApiException('This account is suspended.', 403);
        }

        return $user;
    }

    private function displayName(array $user): string
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

    private function subtitle(array $user): string
    {
        $handle = trim((string) ($user['profile_handle'] ?? ''));
        if ($handle !== '') {
            return $handle;
        }

        return 'ID:' . (int) $user['id'];
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
