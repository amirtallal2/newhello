<?php

declare(strict_types=1);

final class GoogleIdTokenVerifier
{
    /**
     * @param array{client_ids?: array<int, string>, jwks_uri?: string, jwks_cache_path?: string} $config
     */
    public function __construct(private readonly array $config)
    {
    }

    /**
     * @return array<string, mixed>
     */
    public function verify(string $idToken): array
    {
        $clientIds = array_values(array_filter(
            array_map(
                static fn (mixed $value): string => trim((string) $value),
                $this->config['client_ids'] ?? []
            )
        ));

        if ($clientIds === []) {
            throw new ApiException('Google sign-in is not configured on the server.', 500);
        }

        $parts = explode('.', trim($idToken));
        if (count($parts) !== 3) {
            throw new ApiException('Invalid Google token format.', 401);
        }

        [$encodedHeader, $encodedPayload, $encodedSignature] = $parts;
        $header = $this->decodeJsonPart($encodedHeader, 'token header');
        $payload = $this->decodeJsonPart($encodedPayload, 'token payload');
        $signature = $this->base64UrlDecode($encodedSignature);

        $algorithm = (string) ($header['alg'] ?? '');
        $keyId = (string) ($header['kid'] ?? '');

        if ($algorithm !== 'RS256' || $keyId === '') {
            throw new ApiException('Unsupported Google token algorithm.', 401);
        }

        $key = $this->findKeyById($keyId);
        if ($key === null) {
            $this->clearKeyCache();
            $key = $this->findKeyById($keyId);
        }

        if ($key === null) {
            throw new ApiException('Unable to find a matching Google signing key.', 401);
        }

        $publicKey = $this->jwkToPem($key);
        $verification = openssl_verify(
            $encodedHeader . '.' . $encodedPayload,
            $signature,
            $publicKey,
            OPENSSL_ALGO_SHA256
        );

        if ($verification !== 1) {
            throw new ApiException('Google token signature is invalid.', 401);
        }

        $issuer = (string) ($payload['iss'] ?? '');
        if (!in_array($issuer, ['accounts.google.com', 'https://accounts.google.com'], true)) {
            throw new ApiException('Google token issuer is invalid.', 401);
        }

        $expiresAt = (int) ($payload['exp'] ?? 0);
        if ($expiresAt <= time()) {
            throw new ApiException('Google token has expired.', 401);
        }

        $audience = $payload['aud'] ?? null;
        $isAudienceValid = is_array($audience)
            ? count(array_intersect($clientIds, array_map('strval', $audience))) > 0
            : in_array((string) $audience, $clientIds, true);

        if (!$isAudienceValid) {
            throw new ApiException('Google token audience is invalid.', 401);
        }

        return $payload;
    }

    /**
     * @return array<string, mixed>
     */
    private function decodeJsonPart(string $value, string $label): array
    {
        $decoded = $this->base64UrlDecode($value);
        $json = json_decode($decoded, true);

        if (!is_array($json)) {
            throw new ApiException('Invalid Google ' . $label . '.', 401);
        }

        return $json;
    }

    private function base64UrlDecode(string $value): string
    {
        $remainder = strlen($value) % 4;
        if ($remainder > 0) {
            $value .= str_repeat('=', 4 - $remainder);
        }

        $decoded = base64_decode(strtr($value, '-_', '+/'), true);
        if ($decoded === false) {
            throw new ApiException('Unable to decode Google token.', 401);
        }

        return $decoded;
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function keys(): array
    {
        $cachePath = (string) ($this->config['jwks_cache_path'] ?? '');
        if ($cachePath !== '' && is_file($cachePath)) {
            $cached = json_decode((string) file_get_contents($cachePath), true);
            if (
                is_array($cached) &&
                is_array($cached['keys'] ?? null) &&
                (int) ($cached['expires_at'] ?? 0) > time()
            ) {
                return $cached['keys'];
            }
        }

        $jwksUri = (string) ($this->config['jwks_uri'] ?? '');
        if ($jwksUri === '') {
            throw new ApiException('Google JWKS URI is not configured.', 500);
        }

        $context = stream_context_create([
            'http' => [
                'method' => 'GET',
                'timeout' => 10,
                'ignore_errors' => true,
            ],
        ]);

        $body = @file_get_contents($jwksUri, false, $context);
        if ($body === false) {
            throw new ApiException('Failed to load Google signing keys.', 502);
        }

        $responseHeaders = $http_response_header ?? [];
        $payload = json_decode($body, true);
        $keys = is_array($payload['keys'] ?? null) ? $payload['keys'] : null;
        if ($keys === null) {
            throw new ApiException('Invalid Google signing keys response.', 502);
        }

        $maxAge = $this->extractMaxAgeSeconds($responseHeaders);
        if ($cachePath !== '') {
            $directory = dirname($cachePath);
            if (!is_dir($directory)) {
                mkdir($directory, 0777, true);
            }

            file_put_contents($cachePath, json_encode([
                'expires_at' => time() + $maxAge,
                'keys' => $keys,
            ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
        }

        return $keys;
    }

    /**
     * @return array<string, mixed>|null
     */
    private function findKeyById(string $keyId): ?array
    {
        foreach ($this->keys() as $key) {
            if ((string) ($key['kid'] ?? '') === $keyId) {
                return $key;
            }
        }

        return null;
    }

    private function clearKeyCache(): void
    {
        $cachePath = (string) ($this->config['jwks_cache_path'] ?? '');
        if ($cachePath !== '' && is_file($cachePath)) {
            @unlink($cachePath);
        }
    }

    /**
     * @param array<string, mixed> $jwk
     */
    private function jwkToPem(array $jwk): string
    {
        $modulus = $this->base64UrlDecode((string) ($jwk['n'] ?? ''));
        $exponent = $this->base64UrlDecode((string) ($jwk['e'] ?? ''));

        $rsaPublicKey = $this->asn1Sequence(
            $this->asn1Integer($modulus) .
            $this->asn1Integer($exponent)
        );

        $algorithmIdentifier = hex2bin('300d06092a864886f70d0101010500');
        if ($algorithmIdentifier === false) {
            throw new ApiException('Failed to build Google public key.', 500);
        }

        $subjectPublicKeyInfo = $this->asn1Sequence(
            $algorithmIdentifier .
            $this->asn1BitString($rsaPublicKey)
        );

        return "-----BEGIN PUBLIC KEY-----\n"
            . chunk_split(base64_encode($subjectPublicKeyInfo), 64, "\n")
            . "-----END PUBLIC KEY-----\n";
    }

    private function asn1Integer(string $value): string
    {
        $value = ltrim($value, "\x00");
        if ($value === '') {
            $value = "\x00";
        }

        if (ord($value[0]) > 0x7f) {
            $value = "\x00" . $value;
        }

        return "\x02" . $this->asn1Length(strlen($value)) . $value;
    }

    private function asn1BitString(string $value): string
    {
        return "\x03" . $this->asn1Length(strlen($value) + 1) . "\x00" . $value;
    }

    private function asn1Sequence(string $value): string
    {
        return "\x30" . $this->asn1Length(strlen($value)) . $value;
    }

    private function asn1Length(int $length): string
    {
        if ($length < 128) {
            return chr($length);
        }

        $binary = ltrim(pack('N', $length), "\x00");
        return chr(0x80 | strlen($binary)) . $binary;
    }

    /**
     * @param array<int, string> $responseHeaders
     */
    private function extractMaxAgeSeconds(array $responseHeaders): int
    {
        foreach ($responseHeaders as $headerLine) {
            if (!str_starts_with(strtolower($headerLine), 'cache-control:')) {
                continue;
            }

            if (preg_match('/max-age=(\d+)/i', $headerLine, $matches) === 1) {
                return max((int) ($matches[1] ?? 3600), 60);
            }
        }

        return 3600;
    }
}
