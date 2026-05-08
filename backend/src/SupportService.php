<?php

declare(strict_types=1);

final class SupportService
{
    private const CATEGORY_OPTIONS = ['مشكلة تطبيق', 'الاقتراحات', 'اخري', 'اعادة الشحن'];
    private const STATUS_OPTIONS = ['new', 'in_progress', 'resolved', 'closed'];

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function listShippingAgencies(string $query = ''): array
    {
        $sql = 'SELECT *
                FROM shipping_agencies
                WHERE status = :status';
        $params = ['status' => 'active'];

        if ($query !== '') {
            $sql .= ' AND (name LIKE :search OR handle LIKE :search)';
            $params['search'] = '%' . $query . '%';
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        $agencies = [];
        foreach ($statement->fetchAll() as $agency) {
            $agencies[] = $this->mapShippingAgency($agency);
        }

        return $agencies;
    }

    public function submitTicket(
        string $category,
        string $description,
        array $attachments,
        ?string $authorizationHeader
    ): array {
        if (!in_array($category, self::CATEGORY_OPTIONS, true)) {
            throw new ApiException('Invalid support category.', 422);
        }

        $description = trim($description);
        if ($description === '' || mb_strlen($description) > 300) {
            throw new ApiException('Invalid support description.', 422);
        }

        if (count($attachments) > 3) {
            throw new ApiException('A maximum of 3 attachments is allowed.', 422);
        }

        $user = $this->resolveUserFromAuthorization($authorizationHeader);
        if ($user === null) {
            throw new ApiException('Authentication required.', 401);
        }

        $senderName = trim((string) ($user['nickname'] ?: $user['email'] ?: $user['phone'] ?: 'Hallo Party User'));
        $senderEmail = $user['email'] !== null ? (string) $user['email'] : null;
        $senderPhone = $user['phone'] !== null ? (string) $user['phone'] : null;

        $this->pdo->beginTransaction();

        try {
            $insertTicket = $this->pdo->prepare(
                'INSERT INTO support_tickets
                    (ticket_code, user_id, sender_name, sender_email, sender_phone, category, description, status, attachment_count, admin_note, created_at, updated_at)
                 VALUES
                    (:ticket_code, :user_id, :sender_name, :sender_email, :sender_phone, :category, :description, :status, :attachment_count, :admin_note, :created_at, :updated_at)'
            );

            $placeholderCode = 'PENDING-' . TokenManager::generate(16);
            $now = $this->now();
            $insertTicket->execute([
                'ticket_code' => $placeholderCode,
                'user_id' => (int) $user['id'],
                'sender_name' => $senderName,
                'sender_email' => $senderEmail,
                'sender_phone' => $senderPhone,
                'category' => $category,
                'description' => $description,
                'status' => 'new',
                'attachment_count' => count($attachments),
                'admin_note' => null,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $ticketId = (int) $this->pdo->lastInsertId();
            $ticketCode = sprintf('SUP-%06d', $ticketId);

            $updateCode = $this->pdo->prepare(
                'UPDATE support_tickets SET ticket_code = :ticket_code WHERE id = :id'
            );
            $updateCode->execute([
                'ticket_code' => $ticketCode,
                'id' => $ticketId,
            ]);

            if ($attachments !== []) {
                $insertAttachment = $this->pdo->prepare(
                    'INSERT INTO support_ticket_attachments
                        (ticket_id, file_path, original_name, mime_type, created_at)
                     VALUES
                        (:ticket_id, :file_path, :original_name, :mime_type, :created_at)'
                );

                foreach ($attachments as $attachment) {
                    $saved = $this->storeAttachment($attachment);
                    $insertAttachment->execute([
                        'ticket_id' => $ticketId,
                        'file_path' => $saved['file_path'],
                        'original_name' => $saved['original_name'],
                        'mime_type' => $saved['mime_type'],
                        'created_at' => $now,
                    ]);
                }
            }

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return $this->adminGetSupportTicket($ticketId);
    }

    public function adminSupportStats(): array
    {
        return [
            'shipping_agencies' => (int) $this->pdo->query('SELECT COUNT(*) FROM shipping_agencies')->fetchColumn(),
            'active_shipping_agencies' => (int) $this->pdo->query('SELECT COUNT(*) FROM shipping_agencies WHERE status = "active"')->fetchColumn(),
            'support_tickets' => (int) $this->pdo->query('SELECT COUNT(*) FROM support_tickets')->fetchColumn(),
            'open_support_tickets' => (int) $this->pdo->query('SELECT COUNT(*) FROM support_tickets WHERE status IN ("new", "in_progress")')->fetchColumn(),
        ];
    }

    public function adminListShippingAgencies(string $search = ''): array
    {
        $sql = 'SELECT * FROM shipping_agencies';
        $params = [];

        if ($search !== '') {
            $sql .= ' WHERE name LIKE :search OR handle LIKE :search';
            $params['search'] = '%' . $search . '%';
        }

        $sql .= ' ORDER BY display_order ASC, id ASC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function createShippingAgencyAdmin(
        string $name,
        string $handle,
        int $diamondBalance,
        string $supportedCountryCodes,
        string $status
    ): void {
        $normalizedCodes = $this->normalizeCountryCodes($supportedCountryCodes);
        $normalizedStatus = $this->normalizeAgencyStatus($status);

        if ($name === '' || $handle === '') {
            throw new ApiException('Missing shipping agency data.', 422);
        }

        $statement = $this->pdo->prepare(
            'INSERT INTO shipping_agencies
                (name, handle, diamond_balance, supported_country_codes, status, display_order, created_at, updated_at)
             VALUES
                (:name, :handle, :diamond_balance, :supported_country_codes, :status, :display_order, :created_at, :updated_at)'
        );
        $statement->execute([
            'name' => trim($name),
            'handle' => trim($handle),
            'diamond_balance' => max(0, $diamondBalance),
            'supported_country_codes' => json_encode($normalizedCodes, JSON_UNESCAPED_UNICODE),
            'status' => $normalizedStatus,
            'display_order' => $this->nextAgencyDisplayOrder(),
            'created_at' => $this->now(),
            'updated_at' => $this->now(),
        ]);
    }

    public function updateShippingAgencyAdmin(
        int $agencyId,
        string $name,
        string $handle,
        int $diamondBalance,
        string $supportedCountryCodes,
        string $status
    ): void {
        if ($agencyId < 1) {
            throw new ApiException('Invalid shipping agency id.', 422);
        }

        $normalizedCodes = $this->normalizeCountryCodes($supportedCountryCodes);
        $normalizedStatus = $this->normalizeAgencyStatus($status);

        if ($name === '' || $handle === '') {
            throw new ApiException('Missing shipping agency data.', 422);
        }

        $statement = $this->pdo->prepare(
            'UPDATE shipping_agencies
             SET name = :name,
                 handle = :handle,
                 diamond_balance = :diamond_balance,
                 supported_country_codes = :supported_country_codes,
                 status = :status,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'name' => trim($name),
            'handle' => trim($handle),
            'diamond_balance' => max(0, $diamondBalance),
            'supported_country_codes' => json_encode($normalizedCodes, JSON_UNESCAPED_UNICODE),
            'status' => $normalizedStatus,
            'updated_at' => $this->now(),
            'id' => $agencyId,
        ]);
    }

    public function adminListSupportTickets(string $search = '', string $status = 'all'): array
    {
        $sql = 'SELECT *
                FROM support_tickets
                WHERE 1 = 1';
        $params = [];

        if ($search !== '') {
            $sql .= ' AND (
                ticket_code LIKE :search
                OR sender_name LIKE :search
                OR sender_email LIKE :search
                OR sender_phone LIKE :search
                OR description LIKE :search
            )';
            $params['search'] = '%' . $search . '%';
        }

        if ($status !== 'all') {
            $status = $this->normalizeTicketStatus($status);
            $sql .= ' AND status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY id DESC';
        $statement = $this->pdo->prepare($sql);
        $statement->execute($params);

        return $statement->fetchAll();
    }

    public function adminGetSupportTicket(int $ticketId): array
    {
        $statement = $this->pdo->prepare(
            'SELECT *
             FROM support_tickets
             WHERE id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $ticketId]);
        $ticket = $statement->fetch();

        if ($ticket === false) {
            throw new ApiException('Support ticket not found.', 404);
        }

        $attachments = $this->pdo->prepare(
            'SELECT *
             FROM support_ticket_attachments
             WHERE ticket_id = :ticket_id
             ORDER BY id ASC'
        );
        $attachments->execute(['ticket_id' => $ticketId]);

        return [
            ...$ticket,
            'attachments' => $attachments->fetchAll(),
        ];
    }

    public function adminUpdateSupportTicket(
        int $ticketId,
        string $status,
        string $adminNote
    ): void {
        $normalizedStatus = $this->normalizeTicketStatus($status);
        $statement = $this->pdo->prepare(
            'UPDATE support_tickets
             SET status = :status,
                 admin_note = :admin_note,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'status' => $normalizedStatus,
            'admin_note' => trim($adminNote) !== '' ? trim($adminNote) : null,
            'updated_at' => $this->now(),
            'id' => $ticketId,
        ]);
    }

    private function mapShippingAgency(array $agency): array
    {
        $countryCodes = json_decode((string) $agency['supported_country_codes'], true);
        if (!is_array($countryCodes)) {
            $countryCodes = [];
        }

        return [
            'id' => (int) $agency['id'],
            'name' => (string) $agency['name'],
            'handle' => (string) $agency['handle'],
            'diamond_balance' => (int) $agency['diamond_balance'],
            'diamond_balance_label' => $this->formatCompactNumber((int) $agency['diamond_balance']),
            'supported_country_codes' => array_values(array_map(
                static fn ($code) => strtolower((string) $code),
                array_filter($countryCodes, static fn ($code) => trim((string) $code) !== '')
            )),
            'supported_countries_count' => count($countryCodes),
            'status' => (string) $agency['status'],
        ];
    }

    private function normalizeCountryCodes(string $supportedCountryCodes): array
    {
        $codes = array_filter(array_map(
            static fn ($part) => strtolower(trim((string) $part)),
            preg_split('/[,\s]+/u', $supportedCountryCodes) ?: []
        ), static fn ($part) => $part !== '');

        if ($codes === []) {
            throw new ApiException('At least one supported country code is required.', 422);
        }

        return array_values(array_unique($codes));
    }

    private function normalizeAgencyStatus(string $status): string
    {
        if (!in_array($status, ['active', 'hidden'], true)) {
            throw new ApiException('Invalid shipping agency status.', 422);
        }

        return $status;
    }

    private function normalizeTicketStatus(string $status): string
    {
        if (!in_array($status, self::STATUS_OPTIONS, true)) {
            throw new ApiException('Invalid support ticket status.', 422);
        }

        return $status;
    }

    private function nextAgencyDisplayOrder(): int
    {
        return ((int) $this->pdo->query('SELECT COALESCE(MAX(display_order), 0) FROM shipping_agencies')->fetchColumn()) + 1;
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
             LIMIT 1'
        );
        $statement->execute([
            'token_hash' => TokenManager::hash($token),
        ]);
        $user = $statement->fetch();

        return $user === false ? null : $user;
    }

    private function storeAttachment(array $attachment): array
    {
        $base64 = (string) ($attachment['content_base64'] ?? '');
        $mimeType = strtolower(trim((string) ($attachment['mime_type'] ?? '')));
        $originalName = trim((string) ($attachment['filename'] ?? 'attachment'));

        if ($base64 === '' || $mimeType === '') {
            throw new ApiException('Invalid attachment payload.', 422);
        }

        if (!in_array($mimeType, ['image/png', 'image/jpeg', 'image/jpg', 'image/webp'], true)) {
            throw new ApiException('Unsupported attachment type.', 422);
        }

        $decoded = base64_decode($base64, true);
        if ($decoded === false || $decoded === '') {
            throw new ApiException('Failed to decode attachment.', 422);
        }

        if (strlen($decoded) > (4 * 1024 * 1024)) {
            throw new ApiException('Attachment exceeds maximum size.', 422);
        }

        $extension = match ($mimeType) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $storageDir = __DIR__ . '/../storage/support';
        if (!is_dir($storageDir) && !mkdir($storageDir, 0777, true) && !is_dir($storageDir)) {
            throw new ApiException('Failed to prepare support attachment storage.', 500);
        }

        $filename = 'support-' . TokenManager::generate(20) . '.' . $extension;
        $fullPath = $storageDir . '/' . $filename;

        if (file_put_contents($fullPath, $decoded) === false) {
            throw new ApiException('Failed to save attachment.', 500);
        }

        return [
            'file_path' => '/storage/support/' . $filename,
            'original_name' => $originalName,
            'mime_type' => $mimeType,
        ];
    }

    private function formatCompactNumber(int $value): string
    {
        if ($value >= 1000000) {
            return number_format($value / 1000000, 1) . 'M';
        }

        if ($value >= 1000) {
            return number_format($value / 1000, 1) . 'K';
        }

        return (string) $value;
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }
}
