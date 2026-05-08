<?php

declare(strict_types=1);

final class AgoraTokenUtil
{
    public static function packUint16(int $value): string
    {
        return pack('v', $value);
    }

    public static function packUint32(int $value): string
    {
        return pack('V', $value);
    }

    public static function packString(string $value): string
    {
        return self::packUint16(strlen($value)) . $value;
    }

    /**
     * @param array<int, int> $values
     */
    public static function packMapUint32(array $values): string
    {
        ksort($values);

        $payload = '';
        foreach ($values as $key => $value) {
            $payload .= self::packUint16($key);
            $payload .= self::packUint32($value);
        }

        return self::packUint16(count($values)) . $payload;
    }
}

abstract class AgoraTokenService
{
    /**
     * @var array<int, int>
     */
    protected array $privileges = [];

    public function __construct(private readonly int $type)
    {
    }

    public function addPrivilege(int $privilege, int $expire): void
    {
        $this->privileges[$privilege] = $expire;
    }

    public function getServiceType(): int
    {
        return $this->type;
    }

    public function pack(): string
    {
        return AgoraTokenUtil::packUint16($this->type)
            . AgoraTokenUtil::packMapUint32($this->privileges);
    }
}

final class AgoraServiceRtc extends AgoraTokenService
{
    public const SERVICE_TYPE = 1;
    public const PRIVILEGE_JOIN_CHANNEL = 1;
    public const PRIVILEGE_PUBLISH_AUDIO_STREAM = 2;
    public const PRIVILEGE_PUBLISH_VIDEO_STREAM = 3;
    public const PRIVILEGE_PUBLISH_DATA_STREAM = 4;

    public function __construct(
        private readonly string $channelName = '',
        private readonly string $userAccount = ''
    ) {
        parent::__construct(self::SERVICE_TYPE);
    }

    public function pack(): string
    {
        return parent::pack()
            . AgoraTokenUtil::packString($this->channelName)
            . AgoraTokenUtil::packString($this->userAccount);
    }
}

final class AgoraAccessToken2
{
    private const VERSION = '007';

    /**
     * @var array<int, AgoraTokenService>
     */
    private array $services = [];
    private readonly int $issueTimestamp;
    private readonly int $salt;

    public function __construct(
        private readonly string $appId,
        private readonly string $appCertificate,
        private readonly int $expireInSeconds = 3600
    ) {
        $this->issueTimestamp = time();
        $this->salt = random_int(1, 99999999);
    }

    public function addService(AgoraTokenService $service): void
    {
        $this->services[$service->getServiceType()] = $service;
    }

    public function build(): string
    {
        if (!$this->isValidUuid($this->appId) || !$this->isValidUuid($this->appCertificate)) {
            return '';
        }

        $signingKey = $this->signingKey();
        $data = AgoraTokenUtil::packString($this->appId)
            . AgoraTokenUtil::packUint32($this->issueTimestamp)
            . AgoraTokenUtil::packUint32($this->expireInSeconds)
            . AgoraTokenUtil::packUint32($this->salt)
            . AgoraTokenUtil::packUint16(count($this->services));

        ksort($this->services);
        foreach ($this->services as $service) {
            $data .= $service->pack();
        }

        $signature = hash_hmac('sha256', $data, $signingKey, true);
        $payload = AgoraTokenUtil::packString($signature) . $data;

        return self::VERSION . base64_encode(zlib_encode($payload, ZLIB_ENCODING_DEFLATE));
    }

    private function signingKey(): string
    {
        $stageOne = hash_hmac(
            'sha256',
            $this->appCertificate,
            AgoraTokenUtil::packUint32($this->issueTimestamp),
            true
        );

        return hash_hmac('sha256', $stageOne, AgoraTokenUtil::packUint32($this->salt), true);
    }

    private function isValidUuid(string $value): bool
    {
        return strlen($value) === 32 && ctype_xdigit($value);
    }
}

final class AgoraRtcTokenBuilder
{
    public const ROLE_PUBLISHER = 1;
    public const ROLE_SUBSCRIBER = 2;

    public static function buildTokenWithUserAccount(
        string $appId,
        string $appCertificate,
        string $channelName,
        string $userAccount,
        int $role,
        int $tokenExpireInSeconds,
        int $privilegeExpireInSeconds = 0
    ): string {
        $privilegeExpireInSeconds = $privilegeExpireInSeconds > 0
            ? $privilegeExpireInSeconds
            : $tokenExpireInSeconds;

        $token = new AgoraAccessToken2($appId, $appCertificate, $tokenExpireInSeconds);
        $serviceRtc = new AgoraServiceRtc($channelName, $userAccount);
        $serviceRtc->addPrivilege(
            AgoraServiceRtc::PRIVILEGE_JOIN_CHANNEL,
            $privilegeExpireInSeconds
        );

        if ($role === self::ROLE_PUBLISHER) {
            $serviceRtc->addPrivilege(
                AgoraServiceRtc::PRIVILEGE_PUBLISH_AUDIO_STREAM,
                $privilegeExpireInSeconds
            );
            $serviceRtc->addPrivilege(
                AgoraServiceRtc::PRIVILEGE_PUBLISH_VIDEO_STREAM,
                $privilegeExpireInSeconds
            );
            $serviceRtc->addPrivilege(
                AgoraServiceRtc::PRIVILEGE_PUBLISH_DATA_STREAM,
                $privilegeExpireInSeconds
            );
        }

        $token->addService($serviceRtc);
        return $token->build();
    }
}
