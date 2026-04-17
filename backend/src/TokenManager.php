<?php

declare(strict_types=1);

final class TokenManager
{
    public static function generate(int $length = 64): string
    {
        return bin2hex(random_bytes((int) ceil($length / 2)));
    }

    public static function hash(string $token): string
    {
        return hash('sha256', $token);
    }
}
