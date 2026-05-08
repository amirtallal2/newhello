<?php

declare(strict_types=1);

final class AgencyService
{
    private const AGENCY_STATUS_OPTIONS = ['active', 'hidden', 'suspended'];
    private const REQUEST_STATUS_OPTIONS = ['new', 'reviewed', 'approved', 'rejected'];
    private const AGENCY_TYPE_OPTIONS = ['لايف', 'صوتي', 'شات', 'لايف وشات'];

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function summary(?string $authorizationHeader): array
    {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];

        $agency = null;
        if (!empty($user['agency_id'])) {
            $statement = $this->pdo->prepare(
                'SELECT agencies.*,
                        users.nickname AS owner_name
                 FROM agencies
                 LEFT JOIN users ON users.id = agencies.owner_user_id
                 WHERE agencies.id = :id
                 LIMIT 1'
            );
            $statement->execute(['id' => (int) $user['agency_id']]);
            $row = $statement->fetch();
            if ($row !== false) {
                $agency = $this->mapAgency($row);
            }
        }

        $pendingOpenRequest = $this->latestPendingOpenRequest($userId);
        $pendingJoinRequest = $this->latestPendingJoinRequest($userId);

        return [
            'agency' => $agency,
            'agency_role' => $user['agency_role'] !== null ? (string) $user['agency_role'] : null,
            'pending_open_request' => $pendingOpenRequest,
            'pending_join_request' => $pendingJoinRequest,
        ];
    }

    public function submitOpenRequest(
        string $agencyName,
        string $country,
        string $phone,
        string $address,
        ?array $avatarDraft,
        ?array $frontIdDraft,
        ?array $backIdDraft,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];

        if (!empty($user['agency_id'])) {
            throw new ApiException('User already belongs to an agency.', 422);
        }

        if ($this->latestPendingOpenRequest($userId) !== null) {
            throw new ApiException('There is already a pending agency open request.', 422);
        }

        $agencyName = trim($agencyName);
        $country = trim($country);
        $phone = trim($phone);
        $address = trim($address);

        if ($agencyName === '' || mb_strlen($agencyName) > 20) {
            throw new ApiException('Invalid agency name.', 422);
        }

        if ($country === '' || mb_strlen($country) > 120) {
            throw new ApiException('Invalid country.', 422);
        }

        if ($phone === '' || mb_strlen($phone) > 80) {
            throw new ApiException('Invalid phone number.', 422);
        }

        if ($address === '' || mb_strlen($address) > 255) {
            throw new ApiException('Invalid address.', 422);
        }

        $now = $this->now();
        $this->pdo->beginTransaction();

        try {
            $insert = $this->pdo->prepare(
                'INSERT INTO agency_open_requests
                    (request_code, user_id, agency_name, country, phone, address, avatar_path, front_id_path, back_id_path, status, admin_note, agency_id, created_at, updated_at)
                 VALUES
                    (:request_code, :user_id, :agency_name, :country, :phone, :address, :avatar_path, :front_id_path, :back_id_path, :status, :admin_note, :agency_id, :created_at, :updated_at)'
            );

            $placeholderCode = 'AOR-PENDING-' . bin2hex(random_bytes(6));
            $insert->execute([
                'request_code' => $placeholderCode,
                'user_id' => $userId,
                'agency_name' => $agencyName,
                'country' => $country,
                'phone' => $phone,
                'address' => $address,
                'avatar_path' => $avatarDraft !== null ? $this->storeImageDraft($avatarDraft, 'avatars') : null,
                'front_id_path' => $frontIdDraft !== null ? $this->storeImageDraft($frontIdDraft, 'ids') : null,
                'back_id_path' => $backIdDraft !== null ? $this->storeImageDraft($backIdDraft, 'ids') : null,
                'status' => 'new',
                'admin_note' => null,
                'agency_id' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $requestId = (int) $this->pdo->lastInsertId();
            $requestCode = sprintf('AOR-%06d', $requestId);

            $update = $this->pdo->prepare(
                'UPDATE agency_open_requests
                 SET request_code = :request_code
                 WHERE id = :id'
            );
            $update->execute([
                'request_code' => $requestCode,
                'id' => $requestId,
            ]);

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->getOpenRequestReceipt($requestId);
    }

    public function submitJoinRequest(
        string $invitationCode,
        string $agencyType,
        ?string $authorizationHeader
    ): array {
        $user = $this->requireUser($authorizationHeader);
        $userId = (int) $user['id'];

        if (!empty($user['agency_id'])) {
            throw new ApiException('User already belongs to an agency.', 422);
        }

        if ($this->latestPendingJoinRequest($userId) !== null) {
            throw new ApiException('There is already a pending agency join request.', 422);
        }

        $invitationCode = strtoupper(trim($invitationCode));
        if ($invitationCode === '') {
            throw new ApiException('Invitation code is required.', 422);
        }

        if (!in_array($agencyType, self::AGENCY_TYPE_OPTIONS, true)) {
            throw new ApiException('Invalid agency type.', 422);
        }

        $agencyStatement = $this->pdo->prepare(
            'SELECT *
             FROM agencies
             WHERE invitation_code = :invitation_code
               AND status = :status
             LIMIT 1'
        );
        $agencyStatement->execute([
            'invitation_code' => $invitationCode,
            'status' => 'active',
        ]);
        $agency = $agencyStatement->fetch();

        if ($agency === false) {
            throw new ApiException('Invitation code is invalid.', 422);
        }

        $now = $this->now();
        $insert = $this->pdo->prepare(
            'INSERT INTO agency_join_requests
                (request_code, user_id, agency_id, invitation_code, agency_name_snapshot, agency_type, status, admin_note, created_at, updated_at)
             VALUES
                (:request_code, :user_id, :agency_id, :invitation_code, :agency_name_snapshot, :agency_type, :status, :admin_note, :created_at, :updated_at)'
        );
        $placeholderCode = 'AJR-PENDING-' . bin2hex(random_bytes(6));
        $insert->execute([
            'request_code' => $placeholderCode,
            'user_id' => $userId,
            'agency_id' => (int) $agency['id'],
            'invitation_code' => $invitationCode,
            'agency_name_snapshot' => (string) $agency['name'],
            'agency_type' => $agencyType,
            'status' => 'new',
            'admin_note' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $requestId = (int) $this->pdo->lastInsertId();
        $requestCode = sprintf('AJR-%06d', $requestId);
        $update = $this->pdo->prepare(
            'UPDATE agency_join_requests
             SET request_code = :request_code
             WHERE id = :id'
        );
        $update->execute([
            'request_code' => $requestCode,
            'id' => $requestId,
        ]);

        return $this->getJoinRequestReceipt($requestId);
    }

    public function adminStats(): array
    {
        return [
            'agencies' => (int) $this->pdo->query('SELECT COUNT(*) FROM agencies')->fetchColumn(),
            'active_agencies' => (int) $this->pdo->query('SELECT COUNT(*) FROM agencies WHERE status = "active"')->fetchColumn(),
            'open_requests' => (int) $this->pdo->query('SELECT COUNT(*) FROM agency_open_requests')->fetchColumn(),
            'pending_open_requests' => (int) $this->pdo->query('SELECT COUNT(*) FROM agency_open_requests WHERE status IN ("new", "reviewed")')->fetchColumn(),
            'join_requests' => (int) $this->pdo->query('SELECT COUNT(*) FROM agency_join_requests')->fetchColumn(),
            'pending_join_requests' => (int) $this->pdo->query('SELECT COUNT(*) FROM agency_join_requests WHERE status IN ("new", "reviewed")')->fetchColumn(),
        ];
    }

    public function adminListAgencies(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT agencies.*, users.nickname AS owner_name
                FROM agencies
                LEFT JOIN users ON users.id = agencies.owner_user_id
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (agencies.name LIKE :search OR agencies.invitation_code LIKE :search OR users.nickname LIKE :search)';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $status = $this->normalizeAgencyStatus($status);
            $sql .= ' AND agencies.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY agencies.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminUpdateAgencyStatus(int $agencyId, string $status): void
    {
        if ($agencyId < 1) {
            throw new ApiException('Invalid agency id.', 422);
        }

        $status = $this->normalizeAgencyStatus($status);
        $statement = $this->pdo->prepare(
            'UPDATE agencies
             SET status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => $status,
            'updated_at' => $this->now(),
            'id' => $agencyId,
        ]);
    }

    public function adminListOpenRequests(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT agency_open_requests.*,
                       users.nickname AS requester_name,
                       agencies.invitation_code AS agency_invitation_code
                FROM agency_open_requests
                LEFT JOIN users ON users.id = agency_open_requests.user_id
                LEFT JOIN agencies ON agencies.id = agency_open_requests.agency_id
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                agency_open_requests.request_code LIKE :search
                OR agency_open_requests.agency_name LIKE :search
                OR users.nickname LIKE :search
                OR agency_open_requests.phone LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $status = $this->normalizeRequestStatus($status);
            $sql .= ' AND agency_open_requests.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY agency_open_requests.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);
        return $statement->fetchAll();
    }

    public function adminUpdateOpenRequestStatus(int $requestId, string $status, string $adminNote = ''): void
    {
        if ($requestId < 1) {
            throw new ApiException('Invalid open request id.', 422);
        }

        $status = $this->normalizeRequestStatus($status);
        $request = $this->requireOpenRequest($requestId);
        $agencyId = isset($request['agency_id']) && $request['agency_id'] !== null ? (int) $request['agency_id'] : null;

        $this->pdo->beginTransaction();

        try {
            if ($status === 'approved' && $agencyId === null) {
                $insertAgency = $this->pdo->prepare(
                    'INSERT INTO agencies
                        (owner_user_id, name, invitation_code, country, phone, address, avatar_path, front_id_path, back_id_path, status, member_count, created_at, updated_at)
                     VALUES
                        (:owner_user_id, :name, :invitation_code, :country, :phone, :address, :avatar_path, :front_id_path, :back_id_path, :status, :member_count, :created_at, :updated_at)'
                );
                $insertAgency->execute([
                    'owner_user_id' => $request['user_id'] !== null ? (int) $request['user_id'] : null,
                    'name' => (string) $request['agency_name'],
                    'invitation_code' => $this->generateInvitationCode((string) $request['agency_name']),
                    'country' => (string) $request['country'],
                    'phone' => (string) $request['phone'],
                    'address' => (string) $request['address'],
                    'avatar_path' => $request['avatar_path'] !== null ? (string) $request['avatar_path'] : null,
                    'front_id_path' => $request['front_id_path'] !== null ? (string) $request['front_id_path'] : null,
                    'back_id_path' => $request['back_id_path'] !== null ? (string) $request['back_id_path'] : null,
                    'status' => 'active',
                    'member_count' => 1,
                    'created_at' => $this->now(),
                    'updated_at' => $this->now(),
                ]);
                $agencyId = (int) $this->pdo->lastInsertId();
            }

            $updateRequest = $this->pdo->prepare(
                'UPDATE agency_open_requests
                 SET status = :status,
                     admin_note = :admin_note,
                     agency_id = :agency_id,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $updateRequest->execute([
                'status' => $status,
                'admin_note' => trim($adminNote) !== '' ? trim($adminNote) : null,
                'agency_id' => $agencyId,
                'updated_at' => $this->now(),
                'id' => $requestId,
            ]);

            if ($status === 'approved' && $request['user_id'] !== null && $agencyId !== null) {
                $updateUser = $this->pdo->prepare(
                    'UPDATE users
                     SET agency_id = :agency_id,
                         agency_role = :agency_role,
                         agency_joined_at = :agency_joined_at,
                         updated_at = :updated_at
                     WHERE id = :id'
                );
                $updateUser->execute([
                    'agency_id' => $agencyId,
                    'agency_role' => 'owner',
                    'agency_joined_at' => $this->now(),
                    'updated_at' => $this->now(),
                    'id' => (int) $request['user_id'],
                ]);
                $this->recalculateAgencyMemberCount($agencyId);
            }

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }
    }

    public function adminListJoinRequests(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT agency_join_requests.*,
                       users.nickname AS requester_name,
                       agencies.name AS agency_name_current
                FROM agency_join_requests
                LEFT JOIN users ON users.id = agency_join_requests.user_id
                LEFT JOIN agencies ON agencies.id = agency_join_requests.agency_id
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                agency_join_requests.request_code LIKE :search
                OR agency_join_requests.invitation_code LIKE :search
                OR agency_join_requests.agency_name_snapshot LIKE :search
                OR users.nickname LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $status = $this->normalizeRequestStatus($status);
            $sql .= ' AND agency_join_requests.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY agency_join_requests.id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);
        return $statement->fetchAll();
    }

    public function adminUpdateJoinRequestStatus(int $requestId, string $status, string $adminNote = ''): void
    {
        if ($requestId < 1) {
            throw new ApiException('Invalid join request id.', 422);
        }

        $status = $this->normalizeRequestStatus($status);
        $request = $this->requireJoinRequest($requestId);
        $agencyId = isset($request['agency_id']) && $request['agency_id'] !== null ? (int) $request['agency_id'] : null;

        if ($status === 'approved' && $agencyId === null) {
            throw new ApiException('Join request is not matched to an agency.', 422);
        }

        $this->pdo->beginTransaction();

        try {
            $updateRequest = $this->pdo->prepare(
                'UPDATE agency_join_requests
                 SET status = :status,
                     admin_note = :admin_note,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $updateRequest->execute([
                'status' => $status,
                'admin_note' => trim($adminNote) !== '' ? trim($adminNote) : null,
                'updated_at' => $this->now(),
                'id' => $requestId,
            ]);

            if ($status === 'approved' && $request['user_id'] !== null && $agencyId !== null) {
                $userStatement = $this->pdo->prepare('SELECT agency_id FROM users WHERE id = :id LIMIT 1');
                $userStatement->execute(['id' => (int) $request['user_id']]);
                $userRow = $userStatement->fetch();
                if ($userRow !== false && $userRow['agency_id'] !== null && (int) $userRow['agency_id'] !== $agencyId) {
                    throw new ApiException('User already belongs to a different agency.', 422);
                }

                $updateUser = $this->pdo->prepare(
                    'UPDATE users
                     SET agency_id = :agency_id,
                         agency_role = :agency_role,
                         agency_joined_at = :agency_joined_at,
                         updated_at = :updated_at
                     WHERE id = :id'
                );
                $updateUser->execute([
                    'agency_id' => $agencyId,
                    'agency_role' => 'member',
                    'agency_joined_at' => $this->now(),
                    'updated_at' => $this->now(),
                    'id' => (int) $request['user_id'],
                ]);
                $this->recalculateAgencyMemberCount($agencyId);
            }

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }
    }

    private function getOpenRequestReceipt(int $requestId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT request_code, status, agency_name
             FROM agency_open_requests
             WHERE id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $requestId]);
        $row = $statement->fetch();
        if ($row === false) {
            throw new ApiException('Open request not found.', 404);
        }

        return [
            'request_code' => (string) $row['request_code'],
            'status' => (string) $row['status'],
            'agency_name' => (string) $row['agency_name'],
        ];
    }

    private function getJoinRequestReceipt(int $requestId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT request_code, status, agency_name_snapshot
             FROM agency_join_requests
             WHERE id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $requestId]);
        $row = $statement->fetch();
        if ($row === false) {
            throw new ApiException('Join request not found.', 404);
        }

        return [
            'request_code' => (string) $row['request_code'],
            'status' => (string) $row['status'],
            'agency_name' => $row['agency_name_snapshot'] !== null ? (string) $row['agency_name_snapshot'] : '',
        ];
    }

    private function latestPendingOpenRequest(int $userId): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT request_code, status, agency_name
             FROM agency_open_requests
             WHERE user_id = :user_id
               AND status IN ("new", "reviewed")
             ORDER BY id DESC
             LIMIT 1'
        );
        $statement->execute(['user_id' => $userId]);
        $row = $statement->fetch();

        if ($row === false) {
            return null;
        }

        return [
            'request_code' => (string) $row['request_code'],
            'status' => (string) $row['status'],
            'agency_name' => (string) $row['agency_name'],
        ];
    }

    private function latestPendingJoinRequest(int $userId): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT request_code, status, agency_name_snapshot
             FROM agency_join_requests
             WHERE user_id = :user_id
               AND status IN ("new", "reviewed")
             ORDER BY id DESC
             LIMIT 1'
        );
        $statement->execute(['user_id' => $userId]);
        $row = $statement->fetch();

        if ($row === false) {
            return null;
        }

        return [
            'request_code' => (string) $row['request_code'],
            'status' => (string) $row['status'],
            'agency_name' => $row['agency_name_snapshot'] !== null ? (string) $row['agency_name_snapshot'] : '',
        ];
    }

    private function requireOpenRequest(int $requestId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM agency_open_requests WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $requestId]);
        $request = $statement->fetch();
        if ($request === false) {
            throw new ApiException('Agency open request not found.', 404);
        }

        return $request;
    }

    private function requireJoinRequest(int $requestId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM agency_join_requests WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $requestId]);
        $request = $statement->fetch();
        if ($request === false) {
            throw new ApiException('Agency join request not found.', 404);
        }

        return $request;
    }

    private function recalculateAgencyMemberCount(int $agencyId): void
    {
        $countStatement = $this->pdo->prepare('SELECT COUNT(*) FROM users WHERE agency_id = :agency_id');
        $countStatement->execute(['agency_id' => $agencyId]);
        $memberCount = (int) $countStatement->fetchColumn();

        $update = $this->pdo->prepare(
            'UPDATE agencies
             SET member_count = :member_count,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $update->execute([
            'member_count' => max(1, $memberCount),
            'updated_at' => $this->now(),
            'id' => $agencyId,
        ]);
    }

    private function generateInvitationCode(string $agencyName): string
    {
        $base = preg_replace('/[^A-Z0-9]/', '', strtoupper(mb_substr($agencyName, 0, 4))) ?: 'AGY';

        do {
            $code = $base . '-' . strtoupper(bin2hex(random_bytes(3)));
            $statement = $this->pdo->prepare('SELECT id FROM agencies WHERE invitation_code = :code LIMIT 1');
            $statement->execute(['code' => $code]);
        } while ($statement->fetch() !== false);

        return $code;
    }

    private function normalizeAgencyStatus(string $status): string
    {
        $status = trim($status);
        if (!in_array($status, self::AGENCY_STATUS_OPTIONS, true)) {
            throw new ApiException('Invalid agency status.', 422);
        }

        return $status;
    }

    private function normalizeRequestStatus(string $status): string
    {
        $status = trim($status);
        if (!in_array($status, self::REQUEST_STATUS_OPTIONS, true)) {
            throw new ApiException('Invalid agency request status.', 422);
        }

        return $status;
    }

    private function mapAgency(array $agency): array
    {
        return [
            'id' => (int) $agency['id'],
            'name' => (string) $agency['name'],
            'invitation_code' => (string) $agency['invitation_code'],
            'country' => (string) $agency['country'],
            'phone' => (string) $agency['phone'],
            'address' => (string) $agency['address'],
            'avatar_path' => $agency['avatar_path'] !== null ? (string) $agency['avatar_path'] : null,
            'status' => (string) $agency['status'],
            'member_count' => (int) $agency['member_count'],
            'owner_name' => isset($agency['owner_name']) && $agency['owner_name'] !== null
                ? (string) $agency['owner_name']
                : null,
        ];
    }

    private function storeImageDraft(array $draft, string $folder): string
    {
        $fileName = trim((string) ($draft['filename'] ?? 'agency-file'));
        $contentBase64 = (string) ($draft['content_base64'] ?? '');
        $mimeType = trim((string) ($draft['mime_type'] ?? 'image/png'));

        if ($contentBase64 === '') {
            throw new ApiException('Invalid agency image payload.', 422);
        }

        $bytes = base64_decode($contentBase64, true);
        if ($bytes === false) {
            throw new ApiException('Invalid agency image encoding.', 422);
        }

        $extension = match ($mimeType) {
            'image/jpeg', 'image/jpg' => 'jpg',
            'image/webp' => 'webp',
            default => 'png',
        };

        $directory = dirname(__DIR__) . '/storage/agencies/' . $folder;
        if (!is_dir($directory) && !mkdir($directory, 0777, true) && !is_dir($directory)) {
            throw new ApiException('Failed to create agency storage directory.', 500);
        }

        $safeName = preg_replace('/[^a-zA-Z0-9_\-]/', '-', pathinfo($fileName, PATHINFO_FILENAME)) ?: 'agency';
        $relativePath = '/storage/agencies/' . $folder . '/' . $safeName . '-' . bin2hex(random_bytes(6)) . '.' . $extension;
        $absolutePath = dirname(__DIR__) . $relativePath;

        if (file_put_contents($absolutePath, $bytes) === false) {
            throw new ApiException('Failed to store agency image.', 500);
        }

        return $relativePath;
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
        if ($authorizationHeader === null || !preg_match('/Bearer\s+(.*)$/i', $authorizationHeader, $matches)) {
            return null;
        }

        $token = trim($matches[1]);
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
            'token_hash' => TokenManager::hash($token),
        ]);

        $user = $statement->fetch();
        return $user === false ? null : $user;
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
