<?php

declare(strict_types=1);

final class Response
{
    public static function cors(): void
    {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        header('Access-Control-Allow-Methods: GET, POST, PATCH, OPTIONS');
    }

    public static function json(array $payload, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function readJson(): array
    {
        $raw = file_get_contents('php://input') ?: '';

        if ($raw === '') {
            return [];
        }

        $data = json_decode($raw, true);

        if (!is_array($data)) {
            throw new ApiException('Invalid JSON payload.', 400);
        }

        return $data;
    }
}
