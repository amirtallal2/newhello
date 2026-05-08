<?php

declare(strict_types=1);

final class LiveService
{
    private const VALID_SCOPES = ['live', 'newest', 'friends'];
    private const VALID_STATUSES = ['active', 'hidden'];
    private const VALID_PERMISSION_VALUES = ['عند الطلب', 'شبكتي'];
    private const VALID_BATTLE_DURATIONS = ['3د', '5د', '15د', '30د', '60د'];
    private const VALID_REPORT_STATUSES = ['new', 'reviewed', 'resolved', 'rejected'];
    private const VALID_NOTIFICATION_STATUSES = ['active', 'hidden'];
    private const VALID_INVITE_STATUSES = ['sent', 'accepted', 'rejected', 'ended'];
    private const VALID_PK_STATUSES = ['idle', 'matching', 'active'];
    private const VALID_ACTION_STATUSES = ['active', 'hidden'];
    private const VALID_ACTION_BEHAVIORS = [
        'beauty',
        'sticker',
        'interface',
        'mute',
        'notifications',
        'welcome_message',
        'viewers',
        'room_admin',
        'supporters',
        'entry_ranking',
        'gift',
        'pk',
        'share',
        'report',
        'game',
        'custom',
    ];

    public function __construct(
        private readonly PDO $pdo,
        private readonly array $config = []
    )
    {
    }

    public function listRooms(
        string $scope = 'live',
        string $query = '',
        ?string $authorizationHeader = null
    ): array
    {
        $this->expireEndedPkBattles();
        $this->expireStaleViewers();
        $this->syncActiveRoomViewerCounts();

        $scope = in_array($scope, self::VALID_SCOPES, true) ? $scope : 'live';
        $query = trim($query);
        $viewer = $this->resolveOptionalUser($authorizationHeader);
        $viewerUserId = $viewer !== null ? (int) $viewer['id'] : null;
        $followingIds = $viewerUserId !== null ? $this->socialFollowingIds($viewerUserId) : [];
        $friendIds = $viewerUserId !== null ? $this->socialFriendIds($viewerUserId) : [];

        $sql = 'SELECT *
                FROM live_rooms
                WHERE status = :status';
        $params = ['status' => 'active'];

        if ($query !== '') {
            $sql .= ' AND (
                title LIKE :query
                OR host_name LIKE :query
                OR host_id_label LIKE :query
            )';
            $params['query'] = '%' . $query . '%';
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';

        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $rooms = [];
        foreach ($statement->fetchAll() as $room) {
            $hostUserId = isset($room['host_user_id']) && $room['host_user_id'] !== null
                ? (int) $room['host_user_id']
                : null;

            if ($scope === 'friends' && ($hostUserId === null || !in_array($hostUserId, $friendIds, true))) {
                continue;
            }

            $rooms[] = $room;
        }

        usort(
            $rooms,
            fn (array $left, array $right): int => $this->compareRoomCards(
                $left,
                $right,
                $scope,
                $followingIds,
                $friendIds
            )
        );

        return array_map(
            fn (array $room): array => $this->mapRoomCard($room, $viewerUserId, $followingIds, $friendIds),
            $rooms
        );
    }

    public function getRoom(int $roomId): array
    {
        $this->expireEndedPkBattles($roomId);
        $this->expireStaleViewers($roomId);
        $this->refreshRoomViewerCount($roomId);

        $room = $this->findRoomById($roomId);

        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        return $this->mapRoomDetails($room);
    }

    public function joinRtc(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        if ((string) $room['status'] !== 'active') {
            throw new ApiException('Live room is not active.', 410);
        }

        $user = $this->requireUser($authorizationHeader);
        $this->touchViewerPresence($room, $user);
        $this->refreshRoomViewerCount($roomId);

        return $this->buildRtcPayloadForUser($room, $user);
    }

    public function issueRtcToken(int $roomId, ?string $authorizationHeader): array
    {
        return $this->buildRtcPayload($roomId, $authorizationHeader);
    }

    public function heartbeatRtc(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        if ((string) $room['status'] !== 'active') {
            throw new ApiException('Live room is not active.', 410);
        }

        $user = $this->requireUser($authorizationHeader);
        $this->touchViewerPresence($room, $user);
        $this->refreshRoomViewerCount($roomId);

        return [
            'room_id' => $roomId,
            'active' => true,
        ];
    }

    public function leaveRtc(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $user = $this->requireUser($authorizationHeader);
        $this->markViewerOffline($roomId, (int) $user['id']);
        $this->refreshRoomViewerCount($roomId);

        return [
            'room_id' => $roomId,
            'left' => true,
            'room' => $this->getRoom($roomId),
        ];
    }

    public function endRoom(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $user = $this->requireUser($authorizationHeader);
        $this->requireHostForRoom($room, $user);

        $now = $this->now();
        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET status = :status,
                 video_enabled = :video_enabled,
                 viewer_count = 0,
                 ended_at = :ended_at,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => 'hidden',
            'video_enabled' => 0,
            'ended_at' => $now,
            'updated_at' => $now,
            'id' => $roomId,
        ]);

        $this->markRoomViewersOffline($roomId, $now);

        return [
            'room_id' => $roomId,
            'ended' => true,
        ];
    }

    public function createRoom(string $title, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $title = trim($title);

        if ($title === '') {
            $title = 'لايف ' . $this->displayNameForUser($user);
        }

        if (mb_strlen($title) > 80) {
            throw new ApiException('Live title is too long.', 422);
        }

        $roomCode = (string) time() . '-' . (int) $user['id'] . '-' . random_int(1000, 9999);
        $channelName = $this->sanitizeChannelName('live-video-' . $roomCode);
        $displayOrder = $this->nextRoomDisplayOrder();
        $now = $this->now();

        $this->pdo->beginTransaction();

        try {
            $insertRoom = $this->pdo->prepare(
                'INSERT INTO live_rooms
                    (title, host_name, host_id_label, host_user_id, video_enabled, agora_channel_name,
                     poster_asset, background_asset, left_video_asset, right_video_asset,
                     viewer_count, coin_count, battle_timer_label, listing_scope,
                     contribution_diamonds_total, contribution_sender_count,
                     pk_talk_permission, pk_party_invite_permission, pk_voice_room_invite_permission,
                     pk_chat_permission, pk_battle_duration, status, display_order, ended_at, created_at, updated_at)
                 VALUES
                    (:title, :host_name, :host_id_label, :host_user_id, :video_enabled, :agora_channel_name,
                     :poster_asset, :background_asset, :left_video_asset, :right_video_asset,
                     :viewer_count, :coin_count, :battle_timer_label, :listing_scope,
                     :contribution_diamonds_total, :contribution_sender_count,
                     :pk_talk_permission, :pk_party_invite_permission, :pk_voice_room_invite_permission,
                     :pk_chat_permission, :pk_battle_duration, :status, :display_order, :ended_at, :created_at, :updated_at)'
            );
            $insertRoom->execute([
                'title' => $title,
                'host_name' => $this->displayNameForUser($user),
                'host_id_label' => 'ID:' . (int) $user['id'],
                'host_user_id' => (int) $user['id'],
                'video_enabled' => 1,
                'agora_channel_name' => $channelName,
                'poster_asset' => 'assets/images/home149_card1.png',
                'background_asset' => 'assets/images/live150_background.png',
                'left_video_asset' => 'assets/images/live150_video_left.png',
                'right_video_asset' => 'assets/images/live150_video_right.png',
                'viewer_count' => 1,
                'coin_count' => 0,
                'battle_timer_label' => '11:50',
                'listing_scope' => 'live',
                'contribution_diamonds_total' => 0,
                'contribution_sender_count' => 0,
                'pk_talk_permission' => 'عند الطلب',
                'pk_party_invite_permission' => 'عند الطلب',
                'pk_voice_room_invite_permission' => 'عند الطلب',
                'pk_chat_permission' => 'عند الطلب',
                'pk_battle_duration' => '30د',
                'status' => 'active',
                'display_order' => $displayOrder,
                'ended_at' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $roomId = (int) $this->pdo->lastInsertId();
            $insertViewer = $this->pdo->prepare(
                'INSERT INTO live_room_viewers
                    (room_id, user_id, user_account, client_role, rank_order, viewer_name, avatar_asset, is_top_supporter, is_online, last_seen_at, left_at, created_at, updated_at)
                 VALUES
                    (:room_id, :user_id, :user_account, :client_role, :rank_order, :viewer_name, :avatar_asset, :is_top_supporter, :is_online, :last_seen_at, :left_at, :created_at, :updated_at)'
            );
            $insertViewer->execute([
                'room_id' => $roomId,
                'user_id' => (int) $user['id'],
                'user_account' => $this->liveUserAccount((int) $user['id']),
                'client_role' => 'broadcaster',
                'rank_order' => 1,
                'viewer_name' => $this->displayNameForUser($user),
                'avatar_asset' => (string) ($user['avatar_asset'] ?: 'assets/images/profile_avatar.png'),
                'is_top_supporter' => 0,
                'is_online' => 1,
                'last_seen_at' => $now,
                'left_at' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'room' => $this->getRoom($roomId),
            'rtc' => $this->buildRtcPayload($roomId, $authorizationHeader),
        ];
    }

    public function addComment(int $roomId, string $messageText, ?string $authorizationHeader): array
    {
        $this->ensureLiveCommentUserSchema();
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $messageText = trim($messageText);
        if ($messageText === '' || mb_strlen($messageText) > 300) {
            throw new ApiException('Invalid live comment.', 422);
        }

        $user = $this->requireUser($authorizationHeader);
        $avatarAsset = (string) (($user['avatar_asset'] ?? '') ?: 'assets/images/live150_comment_avatar.png');
        $statement = $this->pdo->prepare(
            'INSERT INTO live_room_comments
                (room_id, commenter_user_id, commenter_name, avatar_asset, message_text, display_order, created_at)
             VALUES
                (:room_id, :commenter_user_id, :commenter_name, :avatar_asset, :message_text, :display_order, :created_at)'
        );
        $statement->execute([
            'room_id' => $roomId,
            'commenter_user_id' => (int) $user['id'],
            'commenter_name' => $this->displayNameForUser($user),
            'avatar_asset' => $avatarAsset,
            'message_text' => $messageText,
            'display_order' => $this->nextCommentDisplayOrder($roomId),
            'created_at' => $this->now(),
        ]);

        return $this->getRoom($roomId);
    }

    public function listNotifications(?int $roomId = null): array
    {
        $sql = 'SELECT live_room_notifications.*,
                       live_rooms.title AS room_title
                FROM live_room_notifications
                INNER JOIN live_rooms ON live_rooms.id = live_room_notifications.room_id
                WHERE live_room_notifications.status = :status';
        $params = ['status' => 'active'];

        if ($roomId !== null) {
            $sql .= ' AND live_room_notifications.room_id = :room_id';
            $params['room_id'] = $roomId;
        }

        $sql .= ' ORDER BY live_room_notifications.display_order ASC, live_room_notifications.id DESC';

        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $notifications = [];
        foreach ($statement->fetchAll() as $row) {
            $notifications[] = $this->mapNotification($row);
        }

        return $notifications;
    }

    public function listActionButtons(?string $authorizationHeader = null): array
    {
        $this->ensureLiveActionSchema();

        $statement = $this->pdo->prepare(
            'SELECT *
             FROM live_action_buttons
             WHERE status = :status
             ORDER BY section_order ASC, section_key ASC, display_order ASC, id ASC'
        );
        $statement->execute(['status' => 'active']);

        $sections = [];
        foreach ($statement->fetchAll() as $row) {
            $sectionKey = (string) $row['section_key'];
            if (!isset($sections[$sectionKey])) {
                $sections[$sectionKey] = [
                    'key' => $sectionKey,
                    'title' => (string) $row['section_title'],
                    'actions' => [],
                ];
            }

            $sections[$sectionKey]['actions'][] = $this->mapActionButton($row);
        }

        return array_values($sections);
    }

    public function recordAction(
        int $roomId,
        int $actionId,
        string $actionKey,
        ?string $authorizationHeader
    ): array {
        $this->ensureLiveActionSchema();

        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        if ((string) $room['status'] !== 'active') {
            throw new ApiException('Live room is not active.', 410);
        }

        $action = $this->findActionButton($actionId, $actionKey);
        if ($action === null || (string) $action['status'] !== 'active') {
            throw new ApiException('Live action not found.', 404);
        }

        $user = $this->requireUser($authorizationHeader);
        if (((int) ($action['requires_host'] ?? 0)) === 1) {
            $this->requireHostForRoom($room, $user);
        }

        $metadata = [
            'behavior' => (string) $action['behavior'],
            'section_key' => (string) $action['section_key'],
            'section_title' => (string) $action['section_title'],
        ];
        $statement = $this->pdo->prepare(
            'INSERT INTO live_room_action_events
                (room_id, user_id, action_button_id, action_key, action_label_snapshot, metadata_json, created_at)
             VALUES
                (:room_id, :user_id, :action_button_id, :action_key, :action_label_snapshot, :metadata_json, :created_at)'
        );
        $statement->execute([
            'room_id' => $roomId,
            'user_id' => (int) $user['id'],
            'action_button_id' => (int) $action['id'],
            'action_key' => (string) $action['action_key'],
            'action_label_snapshot' => (string) $action['label'],
            'metadata_json' => json_encode($metadata, JSON_UNESCAPED_UNICODE),
            'created_at' => $this->now(),
        ]);

        return [
            'event_id' => (int) $this->pdo->lastInsertId(),
            'action' => $this->mapActionButton($action),
            'message' => 'تم تنفيذ ' . (string) $action['label'],
        ];
    }

    public function reportRoom(int $roomId, string $reasonText, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $reasonText = trim($reasonText);
        if ($reasonText === '' || mb_strlen($reasonText) > 300) {
            throw new ApiException('Invalid report reason.', 422);
        }

        $user = $this->requireUser($authorizationHeader);
        $statement = $this->pdo->prepare(
            'INSERT INTO live_room_reports
                (room_id, reporter_user_id, reporter_name, reason_text, status, created_at, updated_at)
             VALUES
                (:room_id, :reporter_user_id, :reporter_name, :reason_text, :status, :created_at, :updated_at)'
        );
        $statement->execute([
            'room_id' => $roomId,
            'reporter_user_id' => (int) $user['id'],
            'reporter_name' => $this->displayNameForUser($user),
            'reason_text' => $reasonText,
            'status' => 'new',
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);

        return [
            'report_id' => (int) $this->pdo->lastInsertId(),
            'status' => 'new',
        ];
    }

    public function pkRecipients(string $query, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $query = trim($query);

        $sql = 'SELECT id, email, phone, nickname
                FROM users
                WHERE id <> :user_id
                  AND status = :status';
        $params = [
            'user_id' => (int) $user['id'],
            'status' => 'active',
        ];

        if ($query !== '') {
            $sql .= ' AND (
                nickname LIKE :query
                OR email LIKE :query
                OR phone LIKE :query
            )';
            $params['query'] = '%' . $query . '%';
        }

        $sql .= ' ORDER BY nickname ASC, id ASC LIMIT 20';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $recipients = [];
        foreach ($statement->fetchAll() as $recipient) {
            $recipients[] = [
                'id' => (int) $recipient['id'],
                'name' => (string) ($recipient['nickname'] ?: $recipient['email']),
                'subtitle' => (string) ($recipient['phone'] ?: $recipient['email']),
                'avatar_asset' => 'assets/images/profile_avatar.png',
            ];
        }

        return $recipients;
    }

    public function sendPkInvite(int $roomId, int $recipientUserId, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        if ((string) $room['status'] !== 'active') {
            throw new ApiException('Live room is not active.', 410);
        }

        if ((string) ($room['pk_status'] ?? 'idle') === 'active') {
            throw new ApiException('This live room already has an active PK battle.', 422);
        }

        $sender = $this->requireUser($authorizationHeader);
        if (isset($room['host_user_id']) && $room['host_user_id'] !== null) {
            $this->requireHostForRoom($room, $sender);
        }

        if ((int) $sender['id'] === $recipientUserId) {
            throw new ApiException('You cannot send a PK invite to yourself.', 422);
        }

        $recipient = $this->findUserById($recipientUserId);
        if ($recipient === null) {
            throw new ApiException('PK recipient not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO live_pk_invites
                (room_id, sender_user_id, sender_name, recipient_user_id, recipient_name_snapshot, status, created_at, updated_at)
             VALUES
                (:room_id, :sender_user_id, :sender_name, :recipient_user_id, :recipient_name_snapshot, :status, :created_at, :updated_at)'
        );
        $statement->execute([
            'room_id' => $roomId,
            'sender_user_id' => (int) $sender['id'],
            'sender_name' => $this->displayNameForUser($sender),
            'recipient_user_id' => (int) $recipient['id'],
            'recipient_name_snapshot' => (string) ($recipient['nickname'] ?: $recipient['email']),
            'status' => 'sent',
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);

        $inviteId = (int) $this->pdo->lastInsertId();
        $this->setRoomPkMatching($roomId);

        return [
            'invite_id' => $inviteId,
            'recipient_name' => (string) ($recipient['nickname'] ?: $recipient['email']),
            'status' => 'sent',
        ];
    }

    public function listPkInvites(?string $authorizationHeader, string $status = 'sent'): array
    {
        $user = $this->requireUser($authorizationHeader);
        if (!in_array($status, self::VALID_INVITE_STATUSES, true)) {
            $status = 'sent';
        }

        $statement = $this->pdo->prepare(
            'SELECT live_pk_invites.*,
                    live_rooms.title AS room_title,
                    live_rooms.status AS room_status
             FROM live_pk_invites
             INNER JOIN live_rooms ON live_rooms.id = live_pk_invites.room_id
             WHERE live_pk_invites.recipient_user_id = :recipient_user_id
               AND live_pk_invites.status = :status
               AND live_rooms.status = "active"
             ORDER BY live_pk_invites.id DESC'
        );
        $statement->execute([
            'recipient_user_id' => (int) $user['id'],
            'status' => $status,
        ]);

        $invites = [];
        foreach ($statement->fetchAll() as $invite) {
            $invites[] = $this->mapPkInvite($invite);
        }

        return $invites;
    }

    public function acceptPkInvite(int $inviteId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $invite = $this->findPkInviteById($inviteId);
        if ($invite === null) {
            throw new ApiException('PK invite not found.', 404);
        }

        if ((int) $invite['recipient_user_id'] !== (int) $user['id']) {
            throw new ApiException('You cannot accept this PK invite.', 403);
        }

        if ((string) $invite['status'] !== 'sent') {
            throw new ApiException('This PK invite is no longer pending.', 422);
        }

        $room = $this->findRoomById((int) $invite['room_id']);
        if ($room === null || (string) $room['status'] !== 'active') {
            throw new ApiException('Live room is not active.', 410);
        }

        if ((string) ($room['pk_status'] ?? 'idle') === 'active') {
            throw new ApiException('This live room already has an active PK battle.', 422);
        }

        $now = $this->now();
        $endsAt = $this->pkEndsAt((string) ($room['pk_battle_duration'] ?? '30د'));
        $this->pdo->beginTransaction();

        try {
            $updateInvite = $this->pdo->prepare(
                'UPDATE live_pk_invites
                 SET status = "accepted",
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $updateInvite->execute([
                'updated_at' => $now,
                'id' => $inviteId,
            ]);

            $updateOtherInvites = $this->pdo->prepare(
                'UPDATE live_pk_invites
                 SET status = "rejected",
                     updated_at = :updated_at
                 WHERE room_id = :room_id
                   AND status = "sent"
                   AND id <> :id'
            );
            $updateOtherInvites->execute([
                'updated_at' => $now,
                'room_id' => (int) $invite['room_id'],
                'id' => $inviteId,
            ]);

            $updateRoom = $this->pdo->prepare(
                'UPDATE live_rooms
                 SET pk_status = "active",
                     active_pk_invite_id = :active_pk_invite_id,
                     pk_guest_user_id = :pk_guest_user_id,
                     pk_guest_name = :pk_guest_name,
                     pk_started_at = :pk_started_at,
                     pk_ends_at = :pk_ends_at,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $updateRoom->execute([
                'active_pk_invite_id' => $inviteId,
                'pk_guest_user_id' => (int) $user['id'],
                'pk_guest_name' => $this->displayNameForUser($user),
                'pk_started_at' => $now,
                'pk_ends_at' => $endsAt,
                'updated_at' => $now,
                'id' => (int) $invite['room_id'],
            ]);

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        $room = $this->findRoomById((int) $invite['room_id']);
        if ($room !== null) {
            $this->touchViewerPresence($room, $user);
            $this->refreshRoomViewerCount((int) $invite['room_id']);
        }

        return [
            'invite_id' => $inviteId,
            'status' => 'accepted',
            'room' => $this->getRoom((int) $invite['room_id']),
            'rtc' => $this->buildRtcPayload((int) $invite['room_id'], $authorizationHeader),
        ];
    }

    public function rejectPkInvite(int $inviteId, ?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $invite = $this->findPkInviteById($inviteId);
        if ($invite === null) {
            throw new ApiException('PK invite not found.', 404);
        }

        if ((int) $invite['recipient_user_id'] !== (int) $user['id']) {
            throw new ApiException('You cannot reject this PK invite.', 403);
        }

        if ((string) $invite['status'] !== 'sent') {
            throw new ApiException('This PK invite is no longer pending.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE live_pk_invites
             SET status = "rejected",
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'updated_at' => $this->now(),
            'id' => $inviteId,
        ]);

        $this->clearRoomMatchingIfNoPendingInvites((int) $invite['room_id']);

        return [
            'invite_id' => $inviteId,
            'status' => 'rejected',
        ];
    }

    public function startPkMatching(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        if ((string) $room['status'] !== 'active') {
            throw new ApiException('Live room is not active.', 410);
        }

        $user = $this->requireUser($authorizationHeader);
        $this->requireHostForRoom($room, $user);

        if ((string) ($room['pk_status'] ?? 'idle') === 'active') {
            throw new ApiException('This live room already has an active PK battle.', 422);
        }

        $this->setRoomPkMatching($roomId);

        return [
            'room' => $this->getRoom($roomId),
        ];
    }

    public function endPkBattle(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $user = $this->requireUser($authorizationHeader);
        $this->requireHostOrPkGuestForRoom($room, $user);
        $this->endPkBattleForRoom($roomId);

        return [
            'room' => $this->getRoom($roomId),
        ];
    }

    public function sendPkTap(int $roomId, string $side, ?string $authorizationHeader): array
    {
        $this->ensurePkTapSchema();
        $side = $side === 'guest' ? 'guest' : 'host';
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        if ((string) $room['status'] !== 'active') {
            throw new ApiException('Live room is not active.', 410);
        }

        if ((string) ($room['pk_status'] ?? 'idle') !== 'active') {
            throw new ApiException('PK battle is not active yet.', 422);
        }

        if (!empty($room['pk_ends_at']) && strtotime((string) $room['pk_ends_at']) <= time()) {
            throw new ApiException('PK battle has ended.', 422);
        }

        if ($side === 'guest' && empty($room['pk_guest_user_id'])) {
            throw new ApiException('PK guest is not ready yet.', 422);
        }

        $user = $this->requireUser($authorizationHeader);
        $statement = $this->pdo->prepare(
            'INSERT INTO live_pk_taps
                (room_id, user_id, side, tap_count, created_at)
             VALUES
                (:room_id, :user_id, :side, :tap_count, :created_at)'
        );
        $statement->execute([
            'room_id' => $roomId,
            'user_id' => (int) $user['id'],
            'side' => $side,
            'tap_count' => 1,
            'created_at' => $this->now(),
        ]);

        return [
            'room' => $this->getRoom($roomId),
        ];
    }

    public function sendGift(
        int $roomId,
        int $giftId,
        int $quantity,
        ?string $authorizationHeader
    ): array {
        if ($quantity < 1 || $quantity > 999) {
            throw new ApiException('Invalid gift quantity.', 422);
        }

        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $gift = $this->findGiftById($giftId);
        if ($gift === null || (string) $gift['status'] !== 'active') {
            throw new ApiException('Gift not found.', 404);
        }

        $user = $this->requireUser($authorizationHeader);
        $wallet = $this->walletRowForUser((int) $user['id']);
        $unitPrice = (int) $gift['price_coins'];
        $totalPrice = $unitPrice * $quantity;
        $recipient = $this->resolveLiveGiftRecipient($room);

        if ((int) ($recipient['user_id'] ?? 0) > 0 && (int) $recipient['user_id'] === (int) $user['id']) {
            throw new ApiException('You cannot send gifts to your own live.', 422);
        }

        $commissionPercent = $this->giftPlatformCommissionPercent();
        $earnings = $this->calculateGiftEarnings(
            $totalPrice,
            $commissionPercent,
            (int) ($recipient['user_id'] ?? 0),
            (int) $user['id']
        );

        if ((int) $wallet['coins_balance'] < $totalPrice) {
            throw new ApiException('Insufficient coin balance.', 422);
        }

        $this->pdo->beginTransaction();

        try {
            $updateWallet = $this->pdo->prepare(
                'UPDATE user_wallets
                 SET coins_balance = coins_balance - :amount,
                     updated_at = :updated_at
                 WHERE user_id = :user_id'
            );
            $updateWallet->execute([
                'amount' => $totalPrice,
                'updated_at' => $this->now(),
                'user_id' => (int) $user['id'],
            ]);

            $insertGift = $this->pdo->prepare(
                'INSERT INTO live_room_gift_transactions
                    (room_id, sender_user_id, sender_name, sender_avatar_asset, recipient_user_id, recipient_name_snapshot, gift_id, gift_name_snapshot, quantity, unit_price_coins, total_price_coins, platform_fee_coins, creator_earning_diamonds, platform_commission_percent, created_at)
                 VALUES
                    (:room_id, :sender_user_id, :sender_name, :sender_avatar_asset, :recipient_user_id, :recipient_name_snapshot, :gift_id, :gift_name_snapshot, :quantity, :unit_price_coins, :total_price_coins, :platform_fee_coins, :creator_earning_diamonds, :platform_commission_percent, :created_at)'
            );
            $insertGift->execute([
                'room_id' => $roomId,
                'sender_user_id' => (int) $user['id'],
                'sender_name' => $this->displayNameForUser($user),
                'sender_avatar_asset' => (string) ($user['avatar_asset'] ?: 'assets/images/profile_avatar.png'),
                'recipient_user_id' => $recipient['user_id'],
                'recipient_name_snapshot' => $recipient['name'],
                'gift_id' => $giftId,
                'gift_name_snapshot' => (string) $gift['name'],
                'quantity' => $quantity,
                'unit_price_coins' => $unitPrice,
                'total_price_coins' => $totalPrice,
                'platform_fee_coins' => $earnings['platform_fee_coins'],
                'creator_earning_diamonds' => $earnings['creator_earning_diamonds'],
                'platform_commission_percent' => $commissionPercent,
                'created_at' => $this->now(),
            ]);
            $giftTransactionId = (int) $this->pdo->lastInsertId();

            $insertWalletTransaction = $this->pdo->prepare(
                'INSERT INTO wallet_transactions
                    (user_id, wallet_type, direction, amount, status, title, subtitle, context_type, context_ref, created_at)
                 VALUES
                    (:user_id, :wallet_type, :direction, :amount, :status, :title, :subtitle, :context_type, :context_ref, :created_at)'
            );
            $insertWalletTransaction->execute([
                'user_id' => (int) $user['id'],
                'wallet_type' => 'coins',
                'direction' => 'out',
                'amount' => $totalPrice,
                'status' => 'success',
                'title' => 'إرسال هدية لايف',
                'subtitle' => (string) $gift['name'] . ' x' . $quantity,
                'context_type' => 'live_gift',
                'context_ref' => (string) $giftTransactionId,
                'created_at' => $this->now(),
            ]);

            if ((int) ($recipient['user_id'] ?? 0) > 0 && $earnings['creator_earning_diamonds'] > 0) {
                $this->creditGiftRecipient(
                    (int) $recipient['user_id'],
                    $earnings['creator_earning_diamonds'],
                    'ربح هدية لايف',
                    (string) $gift['name'] . ' من ' . $this->displayNameForUser($user),
                    'live_gift_earning',
                    $giftTransactionId
                );
            }

            $totals = $this->giftContributionTotals($roomId, $totalPrice);
            $updateRoom = $this->pdo->prepare(
                'UPDATE live_rooms
                 SET coin_count = coin_count + :coin_delta,
                     contribution_diamonds_total = :contribution_diamonds_total,
                     contribution_sender_count = :contribution_sender_count,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $updateRoom->execute([
                'coin_delta' => $totalPrice,
                'contribution_diamonds_total' => $totals['total_diamonds'],
                'contribution_sender_count' => $totals['sender_count'],
                'updated_at' => $this->now(),
                'id' => $roomId,
            ]);

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'wallet' => $this->walletSummaryForUser((int) $user['id']),
            'room' => $this->getRoom($roomId),
            'supporters' => $this->roomSupporters($roomId),
        ];
    }

    public function roomSupporters(int $roomId): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        return $this->mapSupporters($roomId);
    }

    public function updatePkSettings(
        int $roomId,
        string $talkPermission,
        string $partyInvitePermission,
        string $voiceRoomInvitePermission,
        string $chatPermission,
        string $battleDuration,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $room = $this->findRoomById($roomId);

        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        if (isset($room['host_user_id']) && $room['host_user_id'] !== null) {
            $this->requireHostForRoom($room, $user);
        }

        foreach ([
            $talkPermission,
            $partyInvitePermission,
            $voiceRoomInvitePermission,
            $chatPermission,
        ] as $value) {
            if (!in_array($value, self::VALID_PERMISSION_VALUES, true)) {
                throw new ApiException('Invalid PK permission value.', 422);
            }
        }

        if (!in_array($battleDuration, self::VALID_BATTLE_DURATIONS, true)) {
            throw new ApiException('Invalid PK battle duration.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET pk_talk_permission = :pk_talk_permission,
                 pk_party_invite_permission = :pk_party_invite_permission,
                 pk_voice_room_invite_permission = :pk_voice_room_invite_permission,
                 pk_chat_permission = :pk_chat_permission,
                 pk_battle_duration = :pk_battle_duration,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'pk_talk_permission' => $talkPermission,
            'pk_party_invite_permission' => $partyInvitePermission,
            'pk_voice_room_invite_permission' => $voiceRoomInvitePermission,
            'pk_chat_permission' => $chatPermission,
            'pk_battle_duration' => $battleDuration,
            'updated_at' => $this->now(),
            'id' => $roomId,
        ]);

        return $this->getRoom($roomId);
    }

    public function adminStats(): array
    {
        return [
            'rooms' => (int) $this->pdo->query('SELECT COUNT(*) FROM live_rooms')->fetchColumn(),
            'active_rooms' => (int) $this->pdo->query(
                'SELECT COUNT(*) FROM live_rooms WHERE status = "active"'
            )->fetchColumn(),
            'viewers' => (int) $this->pdo->query('SELECT COUNT(*) FROM live_room_viewers')->fetchColumn(),
            'comments' => (int) $this->pdo->query('SELECT COUNT(*) FROM live_room_comments')->fetchColumn(),
            'reports' => (int) $this->pdo->query('SELECT COUNT(*) FROM live_room_reports')->fetchColumn(),
            'gift_transactions' => (int) $this->pdo->query('SELECT COUNT(*) FROM live_room_gift_transactions')->fetchColumn(),
            'pk_invites' => (int) $this->pdo->query('SELECT COUNT(*) FROM live_pk_invites')->fetchColumn(),
            'notifications' => (int) $this->pdo->query('SELECT COUNT(*) FROM live_room_notifications')->fetchColumn(),
        ];
    }

    public function adminListRooms(string $search = ''): array
    {
        $sql = 'SELECT *,
                       (
                           SELECT COUNT(*)
                           FROM live_room_viewers
                           WHERE live_room_viewers.room_id = live_rooms.id
                             AND live_room_viewers.is_online = 1
                       ) AS viewers_count,
                       (
                           SELECT COUNT(*)
                           FROM live_room_comments
                           WHERE live_room_comments.room_id = live_rooms.id
                       ) AS comments_count
                FROM live_rooms';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE title LIKE :search OR host_name LIKE :search OR host_id_label LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function updateRoomAdmin(
        int $roomId,
        string $title,
        string $hostName,
        string $hostIdLabel,
        ?int $hostUserId,
        bool $videoEnabled,
        string $agoraChannelName,
        int $viewerCount,
        int $coinCount,
        string $listingScope,
        string $status,
        int $contributionDiamondsTotal,
        int $contributionSenderCount,
        string $pkTalkPermission,
        string $pkPartyInvitePermission,
        string $pkVoiceRoomInvitePermission,
        string $pkChatPermission,
        string $pkBattleDuration
    ): void {
        if ($title === '' || $hostName === '' || $hostIdLabel === '') {
            throw new ApiException('Missing required live room fields.', 422);
        }

        $agoraChannelName = $this->sanitizeChannelName($agoraChannelName);
        if ($agoraChannelName === '') {
            $agoraChannelName = 'live-room-' . $roomId;
        }

        if (!in_array($listingScope, self::VALID_SCOPES, true)) {
            throw new ApiException('Invalid live room scope.', 422);
        }

        if (!in_array($status, self::VALID_STATUSES, true)) {
            throw new ApiException('Invalid live room status.', 422);
        }

        foreach ([
            $pkTalkPermission,
            $pkPartyInvitePermission,
            $pkVoiceRoomInvitePermission,
            $pkChatPermission,
        ] as $value) {
            if (!in_array($value, self::VALID_PERMISSION_VALUES, true)) {
                throw new ApiException('Invalid PK permission value.', 422);
            }
        }

        if (!in_array($pkBattleDuration, self::VALID_BATTLE_DURATIONS, true)) {
            throw new ApiException('Invalid PK battle duration.', 422);
        }

        $now = $this->now();
        $isActive = $status === 'active';
        $safeViewerCount = $isActive ? max(0, $viewerCount) : 0;
        $safeVideoEnabled = $isActive && $videoEnabled;

        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET title = :title,
                 host_name = :host_name,
                 host_id_label = :host_id_label,
                 host_user_id = :host_user_id,
                 video_enabled = :video_enabled,
                 agora_channel_name = :agora_channel_name,
                 viewer_count = :viewer_count,
                 coin_count = :coin_count,
                 listing_scope = :listing_scope,
                 status = :status,
                 ended_at = :ended_at,
                 contribution_diamonds_total = :contribution_diamonds_total,
                 contribution_sender_count = :contribution_sender_count,
                 pk_talk_permission = :pk_talk_permission,
                 pk_party_invite_permission = :pk_party_invite_permission,
                 pk_voice_room_invite_permission = :pk_voice_room_invite_permission,
                 pk_chat_permission = :pk_chat_permission,
                 pk_battle_duration = :pk_battle_duration,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'title' => $title,
            'host_name' => $hostName,
            'host_id_label' => $hostIdLabel,
            'host_user_id' => $hostUserId !== null && $hostUserId > 0 ? $hostUserId : null,
            'video_enabled' => $safeVideoEnabled ? 1 : 0,
            'agora_channel_name' => $agoraChannelName,
            'viewer_count' => $safeViewerCount,
            'coin_count' => max(0, $coinCount),
            'listing_scope' => $listingScope,
            'status' => $status,
            'ended_at' => $isActive ? null : $now,
            'contribution_diamonds_total' => max(0, $contributionDiamondsTotal),
            'contribution_sender_count' => max(0, $contributionSenderCount),
            'pk_talk_permission' => $pkTalkPermission,
            'pk_party_invite_permission' => $pkPartyInvitePermission,
            'pk_voice_room_invite_permission' => $pkVoiceRoomInvitePermission,
            'pk_chat_permission' => $pkChatPermission,
            'pk_battle_duration' => $pkBattleDuration,
            'updated_at' => $now,
            'id' => $roomId,
        ]);

        if (!$isActive) {
            $this->markRoomViewersOffline($roomId, $now);
        }
    }

    public function adminSetRoomStatus(int $roomId, string $status): void
    {
        if (!in_array($status, self::VALID_STATUSES, true)) {
            throw new ApiException('Invalid live room status.', 422);
        }

        $now = $this->now();
        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET status = :status,
                 video_enabled = CASE WHEN :status_for_video = \'active\' THEN video_enabled ELSE 0 END,
                 viewer_count = CASE WHEN :status_for_count = \'active\' THEN viewer_count ELSE 0 END,
                 ended_at = CASE WHEN :status_for_ended = \'active\' THEN NULL ELSE :ended_at END,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => $status,
            'status_for_video' => $status,
            'status_for_count' => $status,
            'status_for_ended' => $status,
            'ended_at' => $now,
            'updated_at' => $now,
            'id' => $roomId,
        ]);

        if ($status !== 'active') {
            $this->markRoomViewersOffline($roomId, $now);
        }
    }

    public function adminEndPkBattle(int $roomId): void
    {
        $this->endPkBattleForRoom($roomId);
    }

    public function adminViewers(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM live_room_viewers
             WHERE room_id = :room_id
             ORDER BY rank_order ASC, id ASC'
        );
        $statement->execute(['room_id' => $roomId]);

        return $statement->fetchAll();
    }

    public function adminComments(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM live_room_comments
             WHERE room_id = :room_id
             ORDER BY display_order ASC, id ASC'
        );
        $statement->execute(['room_id' => $roomId]);

        return $statement->fetchAll();
    }

    public function adminListReports(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT live_room_reports.*,
                       live_rooms.title AS room_title
                FROM live_room_reports
                INNER JOIN live_rooms ON live_rooms.id = live_room_reports.room_id
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                live_rooms.title LIKE :search
                OR reporter_name LIKE :search
                OR reason_text LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $sql .= ' AND live_room_reports.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY live_room_reports.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminUpdateReportStatus(int $reportId, string $status): void
    {
        if (!in_array($status, self::VALID_REPORT_STATUSES, true)) {
            throw new ApiException('Invalid live report status.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE live_room_reports
             SET status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $reportId,
        ]);
    }

    public function adminListNotifications(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT live_room_notifications.*,
                       live_rooms.title AS room_title
                FROM live_room_notifications
                INNER JOIN live_rooms ON live_rooms.id = live_room_notifications.room_id
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                live_rooms.title LIKE :search
                OR title_text LIKE :search
                OR body_text LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $sql .= ' AND live_room_notifications.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY live_room_notifications.display_order ASC, live_room_notifications.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function createNotificationAdmin(
        int $roomId,
        string $titleText,
        string $bodyText,
        string $status,
        int $displayOrder
    ): void {
        $titleText = trim($titleText);
        $bodyText = trim($bodyText);
        if ($titleText === '' || $bodyText === '') {
            throw new ApiException('Invalid live notification data.', 422);
        }

        if (!in_array($status, self::VALID_NOTIFICATION_STATUSES, true)) {
            throw new ApiException('Invalid live notification status.', 422);
        }

        if ($this->findRoomById($roomId) === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO live_room_notifications
                (room_id, title_text, body_text, status, display_order, created_at, updated_at)
             VALUES
                (:room_id, :title_text, :body_text, :status, :display_order, :created_at, :updated_at)'
        );
        $statement->execute([
            'room_id' => $roomId,
            'title_text' => $titleText,
            'body_text' => $bodyText,
            'status' => $status,
            'display_order' => max(0, $displayOrder),
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);
    }

    public function updateNotificationAdmin(
        int $notificationId,
        int $roomId,
        string $titleText,
        string $bodyText,
        string $status,
        int $displayOrder
    ): void {
        $titleText = trim($titleText);
        $bodyText = trim($bodyText);
        if ($titleText === '' || $bodyText === '') {
            throw new ApiException('Invalid live notification data.', 422);
        }

        if (!in_array($status, self::VALID_NOTIFICATION_STATUSES, true)) {
            throw new ApiException('Invalid live notification status.', 422);
        }

        if ($this->findRoomById($roomId) === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'UPDATE live_room_notifications
             SET room_id = :room_id,
                 title_text = :title_text,
                 body_text = :body_text,
                 status = :status,
                 display_order = :display_order,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'room_id' => $roomId,
            'title_text' => $titleText,
            'body_text' => $bodyText,
            'status' => $status,
            'display_order' => max(0, $displayOrder),
            'updated_at' => $this->now(),
            'id' => $notificationId,
        ]);
    }

    public function adminListActionButtons(string $search = '', string $status = 'all'): array
    {
        $this->ensureLiveActionSchema();

        $sql = 'SELECT *
                FROM live_action_buttons
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                section_title LIKE :search
                OR label LIKE :search
                OR action_key LIKE :search
                OR behavior LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $sql .= ' AND status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY section_order ASC, section_key ASC, display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function saveActionButtonAdmin(
        int $actionId,
        string $sectionKey,
        string $sectionTitle,
        int $sectionOrder,
        string $actionKey,
        string $label,
        string $iconKind,
        string $iconAsset,
        string $behavior,
        string $detailTitle,
        string $detailBody,
        bool $requiresHost,
        string $status,
        int $displayOrder
    ): void {
        $this->ensureLiveActionSchema();

        $sectionKey = $this->safeKey($sectionKey, 'section');
        $actionKey = $this->safeKey($actionKey, 'action');
        $sectionTitle = trim($sectionTitle);
        $label = trim($label);
        $iconKind = $this->safeKey($iconKind, 'custom');
        $iconAsset = trim($iconAsset);
        $detailTitle = trim($detailTitle);
        $detailBody = trim($detailBody);

        if ($sectionTitle === '' || $label === '') {
            throw new ApiException('Missing live action data.', 422);
        }

        if (!in_array($behavior, self::VALID_ACTION_BEHAVIORS, true)) {
            $behavior = 'custom';
        }

        if (!in_array($status, self::VALID_ACTION_STATUSES, true)) {
            $status = 'active';
        }

        if ($actionId > 0) {
            $statement = $this->pdo->prepare(
                'UPDATE live_action_buttons
                 SET section_key = :section_key,
                     section_title = :section_title,
                     section_order = :section_order,
                     action_key = :action_key,
                     label = :label,
                     icon_kind = :icon_kind,
                     icon_asset = :icon_asset,
                     behavior = :behavior,
                     detail_title = :detail_title,
                     detail_body = :detail_body,
                     requires_host = :requires_host,
                     status = :status,
                     display_order = :display_order,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'section_key' => $sectionKey,
                'section_title' => $sectionTitle,
                'section_order' => max(0, $sectionOrder),
                'action_key' => $actionKey,
                'label' => $label,
                'icon_kind' => $iconKind,
                'icon_asset' => $iconAsset,
                'behavior' => $behavior,
                'detail_title' => $detailTitle,
                'detail_body' => $detailBody,
                'requires_host' => $requiresHost ? 1 : 0,
                'status' => $status,
                'display_order' => max(0, $displayOrder),
                'updated_at' => $this->now(),
                'id' => $actionId,
            ]);
            return;
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO live_action_buttons
                (section_key, section_title, section_order, action_key, label, icon_kind, icon_asset,
                 behavior, detail_title, detail_body, requires_host, status, display_order, created_at, updated_at)
             VALUES
                (:section_key, :section_title, :section_order, :action_key, :label, :icon_kind, :icon_asset,
                 :behavior, :detail_title, :detail_body, :requires_host, :status, :display_order, :created_at, :updated_at)'
        );
        $now = $this->now();
        $statement->execute([
            'section_key' => $sectionKey,
            'section_title' => $sectionTitle,
            'section_order' => max(0, $sectionOrder),
            'action_key' => $actionKey,
            'label' => $label,
            'icon_kind' => $iconKind,
            'icon_asset' => $iconAsset,
            'behavior' => $behavior,
            'detail_title' => $detailTitle,
            'detail_body' => $detailBody,
            'requires_host' => $requiresHost ? 1 : 0,
            'status' => $status,
            'display_order' => max(0, $displayOrder),
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    public function adminListActionEvents(string $search = ''): array
    {
        $this->ensureLiveActionSchema();

        $sql = 'SELECT live_room_action_events.*,
                       live_rooms.title AS room_title,
                       users.nickname AS user_nickname,
                       users.email AS user_email
                FROM live_room_action_events
                INNER JOIN live_rooms ON live_rooms.id = live_room_action_events.room_id
                LEFT JOIN users ON users.id = live_room_action_events.user_id';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE (
                live_rooms.title LIKE :search
                OR action_label_snapshot LIKE :search
                OR action_key LIKE :search
                OR users.nickname LIKE :search
                OR users.email LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY live_room_action_events.id DESC LIMIT 80';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminListGiftTransactions(string $search = ''): array
    {
        $sql = 'SELECT live_room_gift_transactions.*,
                       live_rooms.title AS room_title,
                       gifts.asset_path
                FROM live_room_gift_transactions
                INNER JOIN live_rooms ON live_rooms.id = live_room_gift_transactions.room_id
                INNER JOIN gifts ON gifts.id = live_room_gift_transactions.gift_id';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE (
                live_room_gift_transactions.sender_name LIKE :search
                OR live_room_gift_transactions.recipient_name_snapshot LIKE :search
                OR live_rooms.title LIKE :search
                OR live_room_gift_transactions.gift_name_snapshot LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY live_room_gift_transactions.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminListPkInvites(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT live_pk_invites.*,
                       live_rooms.title AS room_title
                FROM live_pk_invites
                INNER JOIN live_rooms ON live_rooms.id = live_pk_invites.room_id
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                live_rooms.title LIKE :search
                OR sender_name LIKE :search
                OR recipient_name_snapshot LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $sql .= ' AND live_pk_invites.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY live_pk_invites.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminUpdatePkInviteStatus(int $inviteId, string $status): void
    {
        if (!in_array($status, self::VALID_INVITE_STATUSES, true)) {
            throw new ApiException('Invalid PK invite status.', 422);
        }

        $invite = $this->findPkInviteById($inviteId);
        if ($invite === null) {
            throw new ApiException('PK invite not found.', 404);
        }

        $statement = $this->pdo->prepare(
            'UPDATE live_pk_invites
             SET status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $inviteId,
        ]);

        if ($status === 'accepted') {
            $recipient = $this->findUserById((int) $invite['recipient_user_id']);
            $room = $this->findRoomById((int) $invite['room_id']);
            if ($recipient !== null && $room !== null && (string) $room['status'] === 'active') {
                $this->activatePkBattleForInvite($invite, $recipient);
            }
        } elseif ($status === 'ended' && (int) ($invite['room_id'] ?? 0) > 0) {
            $room = $this->findRoomById((int) $invite['room_id']);
            if ($room !== null && (int) ($room['active_pk_invite_id'] ?? 0) === $inviteId) {
                $this->endPkBattleForRoom((int) $invite['room_id']);
            }
        } elseif ($status === 'rejected') {
            $this->clearRoomMatchingIfNoPendingInvites((int) $invite['room_id']);
        }
    }

    public function adminRoomNotifications(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM live_room_notifications
             WHERE room_id = :room_id
             ORDER BY display_order ASC, id DESC'
        );
        $statement->execute(['room_id' => $roomId]);

        return $statement->fetchAll();
    }

    public function adminRoomReports(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM live_room_reports
             WHERE room_id = :room_id
             ORDER BY id DESC'
        );
        $statement->execute(['room_id' => $roomId]);

        return $statement->fetchAll();
    }

    public function adminRoomGiftTransactions(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT live_room_gift_transactions.*, gifts.asset_path
             FROM live_room_gift_transactions
             INNER JOIN gifts ON gifts.id = live_room_gift_transactions.gift_id
             WHERE room_id = :room_id
             ORDER BY live_room_gift_transactions.id DESC'
        );
        $statement->execute(['room_id' => $roomId]);

        return $statement->fetchAll();
    }

    public function adminRoomPkInvites(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM live_pk_invites
             WHERE room_id = :room_id
             ORDER BY id DESC'
        );
        $statement->execute(['room_id' => $roomId]);

        return $statement->fetchAll();
    }

    private function ensureLiveActionSchema(): void
    {
        $this->pdo->exec(
            'CREATE TABLE IF NOT EXISTS live_action_buttons (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                section_key VARCHAR(80) NOT NULL,
                section_title VARCHAR(120) NOT NULL,
                section_order INT NOT NULL DEFAULT 0,
                action_key VARCHAR(120) NOT NULL,
                label VARCHAR(160) NOT NULL,
                icon_kind VARCHAR(80) NOT NULL DEFAULT "custom",
                icon_asset VARCHAR(255) NOT NULL DEFAULT "",
                behavior VARCHAR(80) NOT NULL DEFAULT "custom",
                detail_title VARCHAR(180) NOT NULL DEFAULT "",
                detail_body TEXT NULL,
                requires_host TINYINT(1) NOT NULL DEFAULT 0,
                status VARCHAR(20) NOT NULL DEFAULT "active",
                display_order INT NOT NULL DEFAULT 0,
                created_at DATETIME NOT NULL,
                updated_at DATETIME NOT NULL,
                UNIQUE KEY uq_live_action_key (action_key),
                KEY idx_live_action_section (section_key, section_order, display_order),
                KEY idx_live_action_status (status)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
        );

        $this->pdo->exec(
            'CREATE TABLE IF NOT EXISTS live_room_action_events (
                id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                room_id INT UNSIGNED NOT NULL,
                user_id INT UNSIGNED NULL,
                action_button_id INT UNSIGNED NULL,
                action_key VARCHAR(120) NOT NULL,
                action_label_snapshot VARCHAR(160) NOT NULL,
                metadata_json TEXT NULL,
                created_at DATETIME NOT NULL,
                KEY idx_live_action_events_room (room_id, created_at),
                KEY idx_live_action_events_action (action_key, created_at),
                CONSTRAINT fk_live_action_events_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
        );

        $count = (int) $this->pdo->query('SELECT COUNT(*) FROM live_action_buttons')->fetchColumn();
        if ($count > 0) {
            return;
        }

        $this->seedDefaultLiveActions();
    }

    private function ensurePkTapSchema(): void
    {
        $this->pdo->exec(
            'CREATE TABLE IF NOT EXISTS live_pk_taps (
                id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                room_id INT UNSIGNED NOT NULL,
                user_id INT UNSIGNED NULL,
                side VARCHAR(20) NOT NULL,
                tap_count INT NOT NULL DEFAULT 1,
                created_at DATETIME NOT NULL,
                KEY idx_live_pk_taps_room_side (room_id, side, created_at),
                KEY idx_live_pk_taps_user (user_id, created_at),
                CONSTRAINT fk_live_pk_taps_room FOREIGN KEY (room_id) REFERENCES live_rooms(id) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'
        );
    }

    private function seedDefaultLiveActions(): void
    {
        $now = $this->now();
        $defaults = [
            ['broadcast', 'ادارة البث', 10, 'beauty', 'جمال', 'beauty', 'assets/images/live153_beauty.png', 'beauty', 'جمال البث', 'يفعل تحسينات الصورة أثناء البث الحقيقي عبر Agora.', 1, 10],
            ['broadcast', 'ادارة البث', 10, 'sticker', 'ملصق', 'sticker', 'assets/images/live153_sticker.png', 'sticker', 'ملصقات اللايف', 'يمكنك التحكم في ملصقات وطبقات البث من لوحة التحكم.', 1, 20],
            ['broadcast', 'ادارة البث', 10, 'interface', 'واجهة', 'interface', '', 'interface', 'واجهة البث', 'تحكم في مظهر واجهة اللايف والطبقات المعروضة للمشاهدين.', 1, 30],
            ['broadcast', 'ادارة البث', 10, 'mute', 'كتم الصوت', 'mute', '', 'mute', 'كتم الصوت', 'يكتم أو يشغل صوت اللايف حسب دور المستخدم.', 0, 40],
            ['broadcast', 'ادارة البث', 10, 'headset_monitor', "مراقب سماعة\nالاذن", 'headset', '', 'custom', 'مراقب سماعة الأذن', 'يسجل فتح أداة مراقبة الصوت ويمكن تعديل تفاصيلها من الأدمن.', 1, 50],
            ['room', 'ادارة الغرفة', 20, 'room_notice', 'نشرة الغرفة', 'announcement', '', 'notifications', 'نشرة الغرفة', 'يعرض إشعارات اللايف المرتبطة بالغرفة من لوحة التحكم.', 0, 10],
            ['room', 'ادارة الغرفة', 20, 'welcome_message', "اعدادات رسالة\nالترحيب", 'welcome', '', 'welcome_message', 'رسالة الترحيب', 'رسالة الترحيب يتم التحكم فيها من الأدمن وتظهر للمستخدمين داخل اللايف.', 1, 20],
            ['room', 'ادارة الغرفة', 20, 'new_user', 'مستخدم جديد', 'new_user', '', 'viewers', 'المشاهدون', 'يفتح قائمة المشاهدين الحاليين بداتا حقيقية.', 0, 30],
            ['room', 'ادارة الغرفة', 20, 'room_admin', 'مسؤول الغرفة', 'admin', '', 'room_admin', 'مسؤول الغرفة', 'إدارة مسؤولين ومشرفي اللايف من لوحة التحكم.', 1, 40],
            ['room', 'ادارة الغرفة', 20, 'entry_rank', "القيمة في ترتيب\nالدخولية", 'ranking', '', 'supporters', 'ترتيب الدخولية', 'يفتح ترتيب الداعمين والمساهمات في الجولة الحالية.', 0, 50],
            ['games', 'مركز الالعاب', 30, 'valorant_1', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 10],
            ['games', 'مركز الالعاب', 30, 'valorant_2', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 20],
            ['games', 'مركز الالعاب', 30, 'valorant_3', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 30],
            ['games', 'مركز الالعاب', 30, 'valorant_4', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 40],
            ['games', 'مركز الالعاب', 30, 'valorant_5', 'Valorant', 'game', 'assets/images/live153_game.png', 'game', 'Valorant', 'زر لعبة قابل للإدارة من لوحة التحكم، ويتم تسجيل كل استخدام له.', 0, 50],
        ];

        $statement = $this->pdo->prepare(
            'INSERT INTO live_action_buttons
                (section_key, section_title, section_order, action_key, label, icon_kind, icon_asset, behavior,
                 detail_title, detail_body, requires_host, status, display_order, created_at, updated_at)
             VALUES
                (:section_key, :section_title, :section_order, :action_key, :label, :icon_kind, :icon_asset, :behavior,
                 :detail_title, :detail_body, :requires_host, "active", :display_order, :created_at, :updated_at)'
        );

        foreach ($defaults as $action) {
            $statement->execute([
                'section_key' => $action[0],
                'section_title' => $action[1],
                'section_order' => $action[2],
                'action_key' => $action[3],
                'label' => $action[4],
                'icon_kind' => $action[5],
                'icon_asset' => $action[6],
                'behavior' => $action[7],
                'detail_title' => $action[8],
                'detail_body' => $action[9],
                'requires_host' => $action[10],
                'display_order' => $action[11],
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    private function findActionButton(int $actionId, string $actionKey): ?array
    {
        if ($actionId > 0) {
            $statement = $this->pdo->prepare('SELECT * FROM live_action_buttons WHERE id = :id LIMIT 1');
            $statement->execute(['id' => $actionId]);
            $row = $statement->fetch();
            if ($row !== false) {
                return $row;
            }
        }

        $actionKey = $this->safeKey($actionKey, '');
        if ($actionKey === '') {
            return null;
        }

        $statement = $this->pdo->prepare('SELECT * FROM live_action_buttons WHERE action_key = :action_key LIMIT 1');
        $statement->execute(['action_key' => $actionKey]);
        $row = $statement->fetch();

        return $row === false ? null : $row;
    }

    private function mapActionButton(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'section_key' => (string) $row['section_key'],
            'section_title' => (string) $row['section_title'],
            'action_key' => (string) $row['action_key'],
            'label' => (string) $row['label'],
            'icon_kind' => (string) $row['icon_kind'],
            'icon_asset' => (string) ($row['icon_asset'] ?? ''),
            'behavior' => (string) $row['behavior'],
            'detail_title' => (string) ($row['detail_title'] ?? ''),
            'detail_body' => (string) ($row['detail_body'] ?? ''),
            'requires_host' => ((int) ($row['requires_host'] ?? 0)) === 1,
        ];
    }

    private function safeKey(string $value, string $fallback): string
    {
        $value = strtolower(trim($value));
        $value = preg_replace('/[^a-z0-9_-]+/', '_', $value) ?: '';
        $value = trim($value, '_-');

        return $value === '' ? $fallback : $value;
    }

    private function mapRoomCard(
        array $room,
        ?int $viewerUserId = null,
        array $followingIds = [],
        array $friendIds = []
    ): array {
        $hostUserId = isset($room['host_user_id']) && $room['host_user_id'] !== null
            ? (int) $room['host_user_id']
            : null;
        $isSelf = $viewerUserId !== null && $hostUserId !== null && $viewerUserId === $hostUserId;
        $isFollowing = !$isSelf && $hostUserId !== null && in_array($hostUserId, $followingIds, true);
        $isFriend = !$isSelf && $hostUserId !== null && in_array($hostUserId, $friendIds, true);

        return [
            'id' => (int) $room['id'],
            'title' => (string) $room['title'],
            'poster_asset' => (string) $room['poster_asset'],
            'viewer_count' => (int) $room['viewer_count'],
            'host_user_id' => $hostUserId,
            'host_name' => (string) $room['host_name'],
            'relationship' => [
                'is_self' => $isSelf,
                'is_following' => $isFollowing,
                'is_friend' => $isFriend,
                'status' => $isSelf ? 'self' : ($isFriend ? 'friends' : ($isFollowing ? 'following' : 'none')),
            ],
        ];
    }

    private function compareRoomCards(
        array $left,
        array $right,
        string $scope,
        array $followingIds,
        array $friendIds
    ): int {
        if ($scope === 'newest') {
            $leftTime = strtotime((string) ($left['created_at'] ?? '')) ?: 0;
            $rightTime = strtotime((string) ($right['created_at'] ?? '')) ?: 0;

            return [$rightTime, (int) $right['id']] <=> [$leftTime, (int) $left['id']];
        }

        $leftScore = $this->roomAlgorithmScore($left, $followingIds, $friendIds);
        $rightScore = $this->roomAlgorithmScore($right, $followingIds, $friendIds);

        if ($leftScore === $rightScore) {
            return [(int) $left['display_order'], (int) $left['id']]
                <=> [(int) $right['display_order'], (int) $right['id']];
        }

        return $rightScore <=> $leftScore;
    }

    private function roomAlgorithmScore(array $room, array $followingIds, array $friendIds): int
    {
        $hostUserId = isset($room['host_user_id']) && $room['host_user_id'] !== null
            ? (int) $room['host_user_id']
            : null;

        $score = max(0, 1000 - (int) ($room['display_order'] ?? 0));
        $score += (int) ($room['viewer_count'] ?? 0) * 4;
        $score += (int) floor(((int) ($room['coin_count'] ?? 0)) / 5);

        if ($hostUserId !== null && in_array($hostUserId, $friendIds, true)) {
            $score += 10000;
        } elseif ($hostUserId !== null && in_array($hostUserId, $followingIds, true)) {
            $score += 5000;
        }

        if (($room['pk_status'] ?? 'idle') === 'active') {
            $score += 1300;
        } elseif (($room['pk_status'] ?? 'idle') === 'matching') {
            $score += 650;
        }

        return $score;
    }

    private function mapRoomDetails(array $room): array
    {
        $pkTapTotals = $this->pkTapTotals($room);
        $hostAvatarAsset = 'assets/images/profile_avatar.png';
        if (isset($room['host_user_id']) && $room['host_user_id'] !== null) {
            $host = $this->findUserById((int) $room['host_user_id']);
            if ($host !== null && !empty($host['avatar_asset'])) {
                $hostAvatarAsset = (string) $host['avatar_asset'];
            }
        }
        $secondsRemaining = 0;
        if (!empty($room['pk_ends_at'])) {
            $secondsRemaining = max(0, strtotime((string) $room['pk_ends_at']) - time());
        }
        $winnerSide = '';
        if ($pkTapTotals['host_score'] > $pkTapTotals['guest_score']) {
            $winnerSide = 'host';
        } elseif ($pkTapTotals['guest_score'] > $pkTapTotals['host_score']) {
            $winnerSide = 'guest';
        } elseif ($pkTapTotals['host_score'] > 0 || $pkTapTotals['guest_score'] > 0) {
            $winnerSide = 'tie';
        }

        return [
            'id' => (int) $room['id'],
            'title' => (string) $room['title'],
            'host_name' => (string) $room['host_name'],
            'host_id_label' => (string) $room['host_id_label'],
            'host_user_id' => isset($room['host_user_id']) && $room['host_user_id'] !== null
                ? (int) $room['host_user_id']
                : null,
            'host_avatar_asset' => $hostAvatarAsset,
            'video_enabled' => ((int) ($room['video_enabled'] ?? 1)) === 1,
            'agora_channel_name' => (string) ($room['agora_channel_name'] ?? ('live-room-' . $room['id'])),
            'viewer_count' => (int) $room['viewer_count'],
            'coin_count' => (int) $room['coin_count'],
            'listing_scope' => (string) $room['listing_scope'],
            'status' => (string) $room['status'],
            'ended_at' => isset($room['ended_at']) ? (string) ($room['ended_at'] ?? '') : '',
            'background_asset' => (string) $room['background_asset'],
            'left_video_asset' => (string) $room['left_video_asset'],
            'right_video_asset' => (string) $room['right_video_asset'],
            'battle_timer_label' => (string) $room['battle_timer_label'],
            'contribution_diamonds_total' => (int) $room['contribution_diamonds_total'],
            'contribution_sender_count' => (int) $room['contribution_sender_count'],
            'pk_settings' => [
                'talk_permission' => (string) $room['pk_talk_permission'],
                'party_invite_permission' => (string) $room['pk_party_invite_permission'],
                'voice_room_invite_permission' => (string) $room['pk_voice_room_invite_permission'],
                'chat_permission' => (string) $room['pk_chat_permission'],
                'battle_duration' => (string) $room['pk_battle_duration'],
            ],
            'pk_state' => [
                'status' => (string) ($room['pk_status'] ?? 'idle'),
                'active_invite_id' => isset($room['active_pk_invite_id']) && $room['active_pk_invite_id'] !== null
                    ? (int) $room['active_pk_invite_id']
                    : null,
                'guest_user_id' => isset($room['pk_guest_user_id']) && $room['pk_guest_user_id'] !== null
                    ? (int) $room['pk_guest_user_id']
                    : null,
                'guest_name' => (string) ($room['pk_guest_name'] ?? ''),
                'started_at' => (string) ($room['pk_started_at'] ?? ''),
                'ends_at' => (string) ($room['pk_ends_at'] ?? ''),
                'host_tap_count' => $pkTapTotals['host_tap_count'],
                'guest_tap_count' => $pkTapTotals['guest_tap_count'],
                'host_score' => $pkTapTotals['host_score'],
                'guest_score' => $pkTapTotals['guest_score'],
                'seconds_remaining' => $secondsRemaining,
                'winner_side' => $winnerSide,
            ],
            'viewers' => $this->mapViewers((int) $room['id']),
            'comments' => $this->mapComments((int) $room['id']),
            'supporters' => $this->mapSupporters((int) $room['id']),
            'recent_gifts' => $this->mapRecentGiftEvents((int) $room['id']),
        ];
    }

    private function mapPkInvite(array $invite): array
    {
        return [
            'id' => (int) $invite['id'],
            'room_id' => (int) $invite['room_id'],
            'room_title' => (string) ($invite['room_title'] ?? ''),
            'sender_user_id' => isset($invite['sender_user_id']) && $invite['sender_user_id'] !== null
                ? (int) $invite['sender_user_id']
                : null,
            'sender_name' => (string) $invite['sender_name'],
            'recipient_user_id' => (int) $invite['recipient_user_id'],
            'recipient_name' => (string) $invite['recipient_name_snapshot'],
            'status' => (string) $invite['status'],
            'created_at_label' => date('Y-m-d H:i', strtotime((string) $invite['created_at'])),
        ];
    }

    private function mapViewers(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM live_room_viewers
             WHERE room_id = :room_id
               AND is_online = 1
             ORDER BY client_role DESC, rank_order ASC, last_seen_at DESC, id ASC'
        );
        $statement->execute(['room_id' => $roomId]);

        $viewers = [];
        foreach ($statement->fetchAll() as $viewer) {
            $viewers[] = [
                'id' => (int) $viewer['id'],
                'rank' => (int) $viewer['rank_order'],
                'name' => (string) $viewer['viewer_name'],
                'avatar_asset' => (string) $viewer['avatar_asset'],
                'is_top_supporter' => ((int) $viewer['is_top_supporter']) === 1,
                'client_role' => (string) ($viewer['client_role'] ?? 'audience'),
                'is_online' => ((int) ($viewer['is_online'] ?? 0)) === 1,
            ];
        }

        return $viewers;
    }

    private function mapComments(int $roomId): array
    {
        $this->ensureLiveCommentUserSchema();
        $statement = $this->pdo->prepare(
            'SELECT live_room_comments.*,
                    users.avatar_asset AS user_avatar_asset
             FROM live_room_comments
             LEFT JOIN users ON users.id = live_room_comments.commenter_user_id
             WHERE live_room_comments.room_id = :room_id
             ORDER BY live_room_comments.display_order ASC, live_room_comments.id ASC'
        );
        $statement->execute(['room_id' => $roomId]);

        $comments = [];
        foreach ($statement->fetchAll() as $comment) {
            $avatar = (string) (($comment['user_avatar_asset'] ?? '') ?: $comment['avatar_asset']);
            $comments[] = [
                'id' => (int) $comment['id'],
                'user_id' => $comment['commenter_user_id'] === null
                    ? null
                    : (int) $comment['commenter_user_id'],
                'name' => (string) $comment['commenter_name'],
                'message' => (string) $comment['message_text'],
                'avatar_asset' => $avatar,
            ];
        }

        return $comments;
    }

    private function ensureLiveCommentUserSchema(): void
    {
        try {
            $statement = $this->pdo->query("SHOW COLUMNS FROM live_room_comments LIKE 'commenter_user_id'");
            if ($statement !== false && $statement->fetch() !== false) {
                return;
            }

            $this->pdo->exec(
                'ALTER TABLE live_room_comments
                 ADD COLUMN commenter_user_id INT UNSIGNED NULL AFTER room_id'
            );
            $this->pdo->exec(
                'CREATE INDEX idx_live_room_comments_user
                 ON live_room_comments (commenter_user_id)'
            );
        } catch (Throwable) {
        }
    }

    private function mapSupporters(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT sender_name,
                    sender_avatar_asset,
                    SUM(total_price_coins) AS total_coins,
                    COUNT(*) AS send_count
             FROM live_room_gift_transactions
             WHERE room_id = :room_id
             GROUP BY sender_name, sender_avatar_asset
             ORDER BY total_coins DESC, send_count DESC, sender_name ASC
             LIMIT 20'
        );
        $statement->execute(['room_id' => $roomId]);

        $supporters = [];
        foreach (array_values($statement->fetchAll()) as $index => $row) {
            $supporters[] = [
                'rank' => $index + 1,
                'name' => (string) $row['sender_name'],
                'avatar_asset' => (string) ($row['sender_avatar_asset'] ?: 'assets/images/profile_avatar.png'),
                'total_coins' => (int) $row['total_coins'],
                'coins_label' => ((int) $row['total_coins']) . ' Coin',
                'is_top_supporter' => $index === 0,
            ];
        }

        return $supporters;
    }

    private function mapRecentGiftEvents(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT live_room_gift_transactions.*,
                    gifts.name AS gift_name,
                    gifts.category AS gift_category,
                    gifts.asset_path,
                    gifts.animation_path,
                    gifts.sound_path,
                    gifts.is_animated,
                    gifts.effect_duration_ms,
                    gifts.price_coins
             FROM live_room_gift_transactions
             INNER JOIN gifts ON gifts.id = live_room_gift_transactions.gift_id
             WHERE live_room_gift_transactions.room_id = :room_id
             ORDER BY live_room_gift_transactions.id DESC
             LIMIT 8'
        );
        $statement->execute(['room_id' => $roomId]);

        $events = [];
        foreach ($statement->fetchAll() as $row) {
            $events[] = [
                'id' => (int) $row['id'],
                'sender_name' => (string) $row['sender_name'],
                'sender_avatar_asset' => (string) ($row['sender_avatar_asset'] ?: 'assets/images/profile_avatar.png'),
                'recipient_name' => (string) ($row['recipient_name_snapshot'] ?? ''),
                'quantity' => (int) $row['quantity'],
                'total_price_coins' => (int) $row['total_price_coins'],
                'platform_fee_coins' => (int) ($row['platform_fee_coins'] ?? 0),
                'creator_earning_diamonds' => (int) ($row['creator_earning_diamonds'] ?? 0),
                'created_at_label' => date('H:i', strtotime((string) $row['created_at'])),
                'gift' => [
                    'id' => (int) $row['gift_id'],
                    'name' => (string) ($row['gift_name'] ?: $row['gift_name_snapshot']),
                    'category' => (string) ($row['gift_category'] ?? ''),
                    'asset_path' => (string) $row['asset_path'],
                    'animation_path' => (string) ($row['animation_path'] ?? ''),
                    'sound_path' => (string) ($row['sound_path'] ?? ''),
                    'is_animated' => ((int) ($row['is_animated'] ?? 0)) === 1,
                    'effect_duration_ms' => (int) ($row['effect_duration_ms'] ?? 1800),
                    'price_coins' => (int) ($row['price_coins'] ?? $row['unit_price_coins']),
                ],
            ];
        }

        return $events;
    }

    private function mapNotification(array $row): array
    {
        return [
            'id' => (int) $row['id'],
            'room_id' => (int) $row['room_id'],
            'room_title' => (string) ($row['room_title'] ?? ''),
            'title' => (string) $row['title_text'],
            'message' => (string) $row['body_text'],
            'created_at_label' => date('Y-m-d H:i', strtotime((string) $row['created_at'])),
        ];
    }

    private function giftContributionTotals(int $roomId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT COALESCE(SUM(creator_earning_diamonds), 0) AS total_diamonds,
                    COUNT(DISTINCT sender_name) AS sender_count
             FROM live_room_gift_transactions
             WHERE room_id = :room_id'
        );
        $statement->execute(['room_id' => $roomId]);
        $row = $statement->fetch() ?: ['total_diamonds' => 0, 'sender_count' => 0];

        return [
            'total_diamonds' => (int) $row['total_diamonds'],
            'sender_count' => (int) $row['sender_count'],
        ];
    }

    private function pkTapTotals(array $room): array
    {
        $this->ensurePkTapSchema();
        $roomId = (int) $room['id'];
        $since = (string) ($room['pk_started_at'] ?? '');
        $where = 'room_id = :room_id';
        $params = ['room_id' => $roomId];

        if ($since !== '') {
            $where .= ' AND created_at >= :since';
            $params['since'] = $since;
        }

        $statement = $this->pdo->prepare(
            'SELECT side, COALESCE(SUM(tap_count), 0) AS taps
             FROM live_pk_taps
             WHERE ' . $where . '
             GROUP BY side'
        );
        $statement->execute($params);

        $hostTaps = 0;
        $guestTaps = 0;
        foreach ($statement->fetchAll() as $row) {
            if ((string) $row['side'] === 'guest') {
                $guestTaps = (int) $row['taps'];
            } else {
                $hostTaps = (int) $row['taps'];
            }
        }

        $giftWhere = 'room_id = :room_id';
        $giftParams = ['room_id' => $roomId];
        if ($since !== '') {
            $giftWhere .= ' AND created_at >= :since';
            $giftParams['since'] = $since;
        }
        $giftStatement = $this->pdo->prepare(
            'SELECT COALESCE(SUM(total_price_coins), 0)
             FROM live_room_gift_transactions
             WHERE ' . $giftWhere
        );
        $giftStatement->execute($giftParams);
        $hostGiftScore = (int) $giftStatement->fetchColumn();

        return [
            'host_tap_count' => $hostTaps,
            'guest_tap_count' => $guestTaps,
            'host_score' => $hostTaps + $hostGiftScore,
            'guest_score' => $guestTaps,
        ];
    }

    private function resolveLiveGiftRecipient(array $room): array
    {
        if (isset($room['host_user_id']) && $room['host_user_id'] !== null) {
            $host = $this->findUserById((int) $room['host_user_id']);

            return [
                'user_id' => (int) $room['host_user_id'],
                'name' => $host === null
                    ? (string) ($room['host_name'] ?? 'صاحب اللايف')
                    : $this->displayNameForUser($host),
            ];
        }

        return [
            'user_id' => null,
            'name' => (string) ($room['host_name'] ?? 'صاحب اللايف'),
        ];
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
        $this->walletRowForUser($recipientUserId);

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

    private function findRoomById(int $roomId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM live_rooms WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $roomId]);
        $room = $statement->fetch();

        return $room === false ? null : $room;
    }

    private function buildRtcPayload(int $roomId, ?string $authorizationHeader): array
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            throw new ApiException('Live room not found.', 404);
        }

        $user = $this->requireUser($authorizationHeader);
        return $this->buildRtcPayloadForUser($room, $user);
    }

    private function buildRtcPayloadForUser(array $room, array $user): array
    {
        $appId = trim((string) ($this->config['agora']['app_id'] ?? ''));
        $appCertificate = trim((string) ($this->config['agora']['app_certificate'] ?? ''));
        $tokenExpireInSeconds = max(300, (int) ($this->config['agora']['token_expire_seconds'] ?? 3600));
        $channelName = trim((string) ($room['agora_channel_name'] ?? ''));
        if ($channelName === '') {
            $channelName = 'live-room-' . (int) $room['id'];
        }

        $isHost = isset($room['host_user_id'])
            && $room['host_user_id'] !== null
            && (int) $room['host_user_id'] === (int) $user['id'];
        $isPkGuest = (string) ($room['pk_status'] ?? 'idle') === 'active'
            && isset($room['pk_guest_user_id'])
            && $room['pk_guest_user_id'] !== null
            && (int) $room['pk_guest_user_id'] === (int) $user['id'];
        $canBroadcast = $isHost || $isPkGuest;
        $usesTokens = $appCertificate !== '';
        $userAccount = $this->liveUserAccount((int) $user['id']);
        $token = '';

        if ($appId !== '' && $usesTokens) {
            $token = AgoraRtcTokenBuilder::buildTokenWithUserAccount(
                $appId,
                $appCertificate,
                $channelName,
                $userAccount,
                $canBroadcast
                    ? AgoraRtcTokenBuilder::ROLE_PUBLISHER
                    : AgoraRtcTokenBuilder::ROLE_SUBSCRIBER,
                $tokenExpireInSeconds,
                $tokenExpireInSeconds
            );
        }

        return [
            'enabled' => ((int) ($room['video_enabled'] ?? 1)) === 1,
            'configured' => $appId !== '',
            'uses_tokens' => $usesTokens,
            'app_id' => $appId,
            'channel_name' => $channelName,
            'token' => $token,
            'token_expires_in_seconds' => $tokenExpireInSeconds,
            'user_account' => $userAccount,
            'role' => $isHost ? 'host' : ($isPkGuest ? 'pk_guest' : 'viewer'),
            'client_role' => $canBroadcast ? 'broadcaster' : 'audience',
        ];
    }

    private function touchViewerPresence(array $room, array $user): void
    {
        $roomId = (int) $room['id'];
        $userId = (int) $user['id'];
        $isHost = isset($room['host_user_id'])
            && $room['host_user_id'] !== null
            && (int) $room['host_user_id'] === $userId;
        $isPkGuest = (string) ($room['pk_status'] ?? 'idle') === 'active'
            && isset($room['pk_guest_user_id'])
            && $room['pk_guest_user_id'] !== null
            && (int) $room['pk_guest_user_id'] === $userId;
        $clientRole = ($isHost || $isPkGuest) ? 'broadcaster' : 'audience';
        $now = $this->now();

        $existing = $this->pdo->prepare(
            'SELECT id
             FROM live_room_viewers
             WHERE room_id = :room_id
               AND user_id = :user_id
             LIMIT 1'
        );
        $existing->execute([
            'room_id' => $roomId,
            'user_id' => $userId,
        ]);
        $viewerId = $existing->fetchColumn();

        if ($viewerId !== false) {
            $update = $this->pdo->prepare(
                'UPDATE live_room_viewers
                 SET user_account = :user_account,
                     client_role = :client_role,
                     viewer_name = :viewer_name,
                     avatar_asset = :avatar_asset,
                     is_online = 1,
                     last_seen_at = :last_seen_at,
                     left_at = NULL,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $update->execute([
                'user_account' => $this->liveUserAccount($userId),
                'client_role' => $clientRole,
                'viewer_name' => $this->displayNameForUser($user),
                'avatar_asset' => (string) ($user['avatar_asset'] ?: 'assets/images/profile_avatar.png'),
                'last_seen_at' => $now,
                'updated_at' => $now,
                'id' => (int) $viewerId,
            ]);
            return;
        }

        $insert = $this->pdo->prepare(
            'INSERT INTO live_room_viewers
                (room_id, user_id, user_account, client_role, rank_order, viewer_name, avatar_asset, is_top_supporter, is_online, last_seen_at, left_at, created_at, updated_at)
             VALUES
                (:room_id, :user_id, :user_account, :client_role, :rank_order, :viewer_name, :avatar_asset, :is_top_supporter, :is_online, :last_seen_at, :left_at, :created_at, :updated_at)'
        );
        $insert->execute([
            'room_id' => $roomId,
            'user_id' => $userId,
            'user_account' => $this->liveUserAccount($userId),
            'client_role' => $clientRole,
            'rank_order' => $this->nextViewerRank($roomId),
            'viewer_name' => $this->displayNameForUser($user),
            'avatar_asset' => (string) ($user['avatar_asset'] ?: 'assets/images/profile_avatar.png'),
            'is_top_supporter' => 0,
            'is_online' => 1,
            'last_seen_at' => $now,
            'left_at' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
    }

    private function markViewerOffline(int $roomId, int $userId): void
    {
        $now = $this->now();
        $statement = $this->pdo->prepare(
            'UPDATE live_room_viewers
             SET is_online = 0,
                 left_at = :left_at,
                 updated_at = :updated_at
             WHERE room_id = :room_id
               AND user_id = :user_id'
        );
        $statement->execute([
            'left_at' => $now,
            'updated_at' => $now,
            'room_id' => $roomId,
            'user_id' => $userId,
        ]);
    }

    private function markRoomViewersOffline(int $roomId, string $leftAt): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE live_room_viewers
             SET is_online = 0,
                 left_at = :left_at,
                 updated_at = :updated_at
             WHERE room_id = :room_id'
        );
        $statement->execute([
            'left_at' => $leftAt,
            'updated_at' => $leftAt,
            'room_id' => $roomId,
        ]);
    }

    private function expireStaleViewers(?int $roomId = null): void
    {
        $ttl = max(30, (int) ($this->config['agora']['presence_ttl_seconds'] ?? 90));
        $cutoff = gmdate('Y-m-d H:i:s', time() - $ttl);
        $sql = 'UPDATE live_room_viewers
                SET is_online = 0,
                    left_at = COALESCE(left_at, :left_at),
                    updated_at = :updated_at
                WHERE is_online = 1
                  AND last_seen_at IS NOT NULL
                  AND last_seen_at < :cutoff';
        $params = [
            'left_at' => $this->now(),
            'updated_at' => $this->now(),
            'cutoff' => $cutoff,
        ];

        if ($roomId !== null) {
            $sql .= ' AND room_id = :room_id';
            $params['room_id'] = $roomId;
        }

        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);
    }

    private function refreshRoomViewerCount(int $roomId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET viewer_count = (
                    SELECT COUNT(*)
                    FROM live_room_viewers
                    WHERE room_id = :viewer_room_id
                      AND is_online = 1
                 ),
                 updated_at = :updated_at
             WHERE id = :room_id'
        );
        $statement->execute([
            'viewer_room_id' => $roomId,
            'updated_at' => $this->now(),
            'room_id' => $roomId,
        ]);
    }

    private function syncActiveRoomViewerCounts(): void
    {
        $statement = $this->pdo->query('SELECT id FROM live_rooms WHERE status = "active"');
        foreach ($statement->fetchAll() as $row) {
            $this->refreshRoomViewerCount((int) $row['id']);
        }
    }

    private function expireEndedPkBattles(?int $roomId = null): void
    {
        $now = $this->now();
        $sql = 'SELECT id, active_pk_invite_id
                FROM live_rooms
                WHERE pk_status = "active"
                  AND pk_ends_at IS NOT NULL
                  AND pk_ends_at <> ""
                  AND pk_ends_at <= :now';
        $params = ['now' => $now];

        if ($roomId !== null) {
            $sql .= ' AND id = :room_id';
            $params['room_id'] = $roomId;
        }

        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        foreach ($statement->fetchAll() as $row) {
            $this->endPkBattleForRoom((int) $row['id']);
        }
    }

    private function nextViewerRank(int $roomId): int
    {
        $statement = $this->pdo->prepare(
            'SELECT COALESCE(MAX(rank_order), 0) + 1
             FROM live_room_viewers
             WHERE room_id = :room_id'
        );
        $statement->execute(['room_id' => $roomId]);

        return (int) ($statement->fetchColumn() ?: 1);
    }

    private function liveUserAccount(int $userId): string
    {
        return 'live-user-' . $userId;
    }

    private function findPkInviteById(int $inviteId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM live_pk_invites WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $inviteId]);
        $invite = $statement->fetch();

        return $invite === false ? null : $invite;
    }

    private function setRoomPkMatching(int $roomId): void
    {
        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET pk_status = "matching",
                 active_pk_invite_id = NULL,
                 pk_guest_user_id = NULL,
                 pk_guest_name = NULL,
                 pk_started_at = NULL,
                 pk_ends_at = NULL,
                 updated_at = :updated_at
             WHERE id = :id
               AND COALESCE(pk_status, "idle") <> "active"'
        );
        $statement->execute([
            'updated_at' => $this->now(),
            'id' => $roomId,
        ]);
    }

    private function activatePkBattleForInvite(array $invite, array $recipient): void
    {
        $room = $this->findRoomById((int) $invite['room_id']);
        if ($room === null || (string) $room['status'] !== 'active') {
            return;
        }

        $now = $this->now();
        $endsAt = $this->pkEndsAt((string) ($room['pk_battle_duration'] ?? '30د'));
        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET pk_status = "active",
                 active_pk_invite_id = :active_pk_invite_id,
                 pk_guest_user_id = :pk_guest_user_id,
                 pk_guest_name = :pk_guest_name,
                 pk_started_at = :pk_started_at,
                 pk_ends_at = :pk_ends_at,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'active_pk_invite_id' => (int) $invite['id'],
            'pk_guest_user_id' => (int) $recipient['id'],
            'pk_guest_name' => $this->displayNameForUser($recipient),
            'pk_started_at' => $now,
            'pk_ends_at' => $endsAt,
            'updated_at' => $now,
            'id' => (int) $invite['room_id'],
        ]);
    }

    private function clearRoomMatchingIfNoPendingInvites(int $roomId): void
    {
        $countStatement = $this->pdo->prepare(
            'SELECT COUNT(*)
             FROM live_pk_invites
             WHERE room_id = :room_id
               AND status = "sent"'
        );
        $countStatement->execute(['room_id' => $roomId]);

        if ((int) $countStatement->fetchColumn() > 0) {
            return;
        }

        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET pk_status = "idle",
                 updated_at = :updated_at
             WHERE id = :id
               AND COALESCE(pk_status, "idle") = "matching"'
        );
        $statement->execute([
            'updated_at' => $this->now(),
            'id' => $roomId,
        ]);
    }

    private function endPkBattleForRoom(int $roomId): void
    {
        $room = $this->findRoomById($roomId);
        if ($room === null) {
            return;
        }

        $activeInviteId = isset($room['active_pk_invite_id']) && $room['active_pk_invite_id'] !== null
            ? (int) $room['active_pk_invite_id']
            : 0;
        $now = $this->now();

        if ($activeInviteId > 0) {
            $updateInvite = $this->pdo->prepare(
                'UPDATE live_pk_invites
                 SET status = "ended",
                     updated_at = :updated_at
                 WHERE id = :id
                   AND status = "accepted"'
            );
            $updateInvite->execute([
                'updated_at' => $now,
                'id' => $activeInviteId,
            ]);
        }

        $statement = $this->pdo->prepare(
            'UPDATE live_rooms
             SET pk_status = "idle",
                 active_pk_invite_id = NULL,
                 pk_guest_user_id = NULL,
                 pk_guest_name = NULL,
                 pk_started_at = NULL,
                 pk_ends_at = NULL,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'updated_at' => $now,
            'id' => $roomId,
        ]);
    }

    private function pkEndsAt(string $duration): string
    {
        $minutes = (int) (preg_replace('/\D+/', '', $duration) ?: '30');
        $minutes = max(1, min(180, $minutes));

        return gmdate('Y-m-d H:i:s', time() + ($minutes * 60));
    }

    private function requireHostForRoom(array $room, array $user): void
    {
        if (!isset($room['host_user_id']) || $room['host_user_id'] === null) {
            throw new ApiException('This live room does not have a host user assigned.', 403);
        }

        if ((int) $room['host_user_id'] !== (int) $user['id']) {
            throw new ApiException('Only the live host can do this action.', 403);
        }
    }

    private function requireHostOrPkGuestForRoom(array $room, array $user): void
    {
        $isHost = isset($room['host_user_id'])
            && $room['host_user_id'] !== null
            && (int) $room['host_user_id'] === (int) $user['id'];
        $isPkGuest = isset($room['pk_guest_user_id'])
            && $room['pk_guest_user_id'] !== null
            && (int) $room['pk_guest_user_id'] === (int) $user['id'];

        if (!$isHost && !$isPkGuest) {
            throw new ApiException('Only the live host or PK guest can do this action.', 403);
        }
    }

    private function sanitizeChannelName(string $value): string
    {
        $value = trim($value);
        $value = preg_replace('/[^a-zA-Z0-9!#$%&()+\\-:;<=>.?@\\[\\]^_{}|~,]/', '-', $value) ?? '';
        return substr($value, 0, 63);
    }

    private function findUserById(int $userId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM users WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $userId]);
        $user = $statement->fetch();

        return $user === false ? null : $user;
    }

    private function findGiftById(int $giftId): ?array
    {
        $statement = $this->pdo->prepare('SELECT * FROM gifts WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $giftId]);
        $gift = $statement->fetch();

        return $gift === false ? null : $gift;
    }

    private function resolveOptionalUser(?string $authorizationHeader): ?array
    {
        if ($authorizationHeader === null || trim($authorizationHeader) === '') {
            return null;
        }

        $matches = [];
        if (preg_match('/Bearer\s+(.+)/i', $authorizationHeader, $matches) !== 1) {
            return null;
        }

        $tokenHash = hash('sha256', trim($matches[1]));
        $statement = $this->pdo->prepare(
            'SELECT users.*
             FROM auth_tokens
             INNER JOIN users ON users.id = auth_tokens.user_id
             WHERE auth_tokens.token_hash = :token_hash
             LIMIT 1'
        );
        $statement->execute(['token_hash' => $tokenHash]);
        $user = $statement->fetch();

        return $user === false ? null : $user;
    }

    private function socialFollowingIds(int $userId): array
    {
        try {
            $statement = $this->pdo->prepare(
                'SELECT followed_user_id
                 FROM user_follows
                 WHERE follower_user_id = :user_id
                   AND status = "active"'
            );
            $statement->execute(['user_id' => $userId]);

            return array_map('intval', $statement->fetchAll(PDO::FETCH_COLUMN) ?: []);
        } catch (Throwable) {
            return [];
        }
    }

    private function socialFriendIds(int $userId): array
    {
        try {
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
        } catch (Throwable) {
            return [];
        }
    }

    private function requireUser(?string $authorizationHeader): array
    {
        if ($authorizationHeader === null || trim($authorizationHeader) === '') {
            throw new ApiException('Unauthorized.', 401);
        }

        $matches = [];
        if (preg_match('/Bearer\s+(.+)/i', $authorizationHeader, $matches) !== 1) {
            throw new ApiException('Invalid authorization header.', 401);
        }

        $tokenHash = hash('sha256', trim($matches[1]));
        $statement = $this->pdo->prepare(
            'SELECT users.*
             FROM auth_tokens
             INNER JOIN users ON users.id = auth_tokens.user_id
             WHERE auth_tokens.token_hash = :token_hash
             LIMIT 1'
        );
        $statement->execute(['token_hash' => $tokenHash]);
        $user = $statement->fetch();

        if ($user === false) {
            throw new ApiException('Unauthorized.', 401);
        }

        return $user;
    }

    private function displayNameForUser(array $user): string
    {
        return (string) ($user['nickname'] ?: $user['email'] ?: 'Mohammed Ahmed');
    }

    private function walletRowForUser(int $userId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM user_wallets WHERE user_id = :user_id LIMIT 1');
        $statement->execute(['user_id' => $userId]);
        $wallet = $statement->fetch();

        if ($wallet !== false) {
            return $wallet;
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

        $statement->execute(['user_id' => $userId]);
        $wallet = $statement->fetch();
        if ($wallet === false) {
            throw new ApiException('Wallet not found.', 500);
        }

        return $wallet;
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

    private function nextCommentDisplayOrder(int $roomId): int
    {
        $statement = $this->pdo->prepare(
            'SELECT COALESCE(MAX(display_order), 0) + 1 AS next_order
             FROM live_room_comments
             WHERE room_id = :room_id'
        );
        $statement->execute(['room_id' => $roomId]);

        return (int) ($statement->fetchColumn() ?: 1);
    }

    private function nextRoomDisplayOrder(): int
    {
        $statement = $this->pdo->query(
            'SELECT COALESCE(MAX(display_order), 0) + 1 AS next_order
             FROM live_rooms'
        );

        return (int) ($statement->fetchColumn() ?: 1);
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
