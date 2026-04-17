<?php

declare(strict_types=1);

final class AuthService
{
    public function __construct(
        private readonly PDO $pdo,
        private readonly array $config
    ) {
    }

    public function register(string $email, string $password): array
    {
        $email = strtolower(trim($email));
        $password = trim($password);

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            throw new ApiException('Invalid email address.');
        }

        if (mb_strlen($password) < 6) {
            throw new ApiException('Password must be at least 6 characters.');
        }

        $this->deleteExpiredPendingRegistrations();

        if ($this->userExistsByEmail($email)) {
            throw new ApiException('This email is already registered.');
        }

        $pending = $this->findPendingRegistrationByEmail($email);
        $registrationToken = TokenManager::generate(64);
        $verificationCode = $this->config['auth']['default_email_verification_code'];
        $now = $this->now();
        $expiresAt = $this->futureMinutes(
            (int) $this->config['auth']['pending_registration_expiry_minutes']
        );

        if ($pending !== null) {
            $statement = $this->pdo->prepare(
                'UPDATE pending_registrations
                 SET password_hash = :password_hash,
                     registration_token = :registration_token,
                     email_verification_code = :email_verification_code,
                     email_verified_at = NULL,
                     phone_otp_code = NULL,
                     phone_verified_at = NULL,
                     nickname = NULL,
                     phone = NULL,
                     birthdate = NULL,
                     gender = NULL,
                     country = NULL,
                     expires_at = :expires_at,
                     updated_at = :updated_at
                 WHERE id = :id'
            );
            $statement->execute([
                'password_hash' => password_hash($password, PASSWORD_DEFAULT),
                'registration_token' => $registrationToken,
                'email_verification_code' => $verificationCode,
                'expires_at' => $expiresAt,
                'updated_at' => $now,
                'id' => $pending['id'],
            ]);
        } else {
            $statement = $this->pdo->prepare(
                'INSERT INTO pending_registrations
                    (email, password_hash, registration_token, email_verification_code, expires_at, created_at, updated_at)
                 VALUES
                    (:email, :password_hash, :registration_token, :email_verification_code, :expires_at, :created_at, :updated_at)'
            );
            $statement->execute([
                'email' => $email,
                'password_hash' => password_hash($password, PASSWORD_DEFAULT),
                'registration_token' => $registrationToken,
                'email_verification_code' => $verificationCode,
                'expires_at' => $expiresAt,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }

        return [
            'registration_token' => $registrationToken,
            'email' => $email,
            'email_masked' => $this->maskEmail($email),
            'debug_email_code' => $verificationCode,
        ];
    }

    public function resendEmailVerification(string $registrationToken): array
    {
        $pending = $this->requirePendingRegistration($registrationToken);
        $verificationCode = $this->config['auth']['default_email_verification_code'];

        $statement = $this->pdo->prepare(
            'UPDATE pending_registrations
             SET email_verification_code = :email_verification_code, updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'email_verification_code' => $verificationCode,
            'updated_at' => $this->now(),
            'id' => $pending['id'],
        ]);

        return [
            'email_masked' => $this->maskEmail((string) $pending['email']),
            'debug_email_code' => $verificationCode,
        ];
    }

    public function verifyEmail(string $registrationToken): array
    {
        $pending = $this->requirePendingRegistration($registrationToken);

        $statement = $this->pdo->prepare(
            'UPDATE pending_registrations
             SET email_verified_at = :email_verified_at, updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'email_verified_at' => $this->now(),
            'updated_at' => $this->now(),
            'id' => $pending['id'],
        ]);

        return [
            'email' => $pending['email'],
            'email_masked' => $this->maskEmail((string) $pending['email']),
        ];
    }

    public function completeIdentity(
        string $registrationToken,
        string $nickname,
        string $phone,
        string $birthdate,
        string $gender,
        string $country
    ): array {
        $pending = $this->requirePendingRegistration($registrationToken);

        if (empty($pending['email_verified_at'])) {
            throw new ApiException('Email must be verified before identity setup.');
        }

        $nickname = trim($nickname);
        $phone = trim($phone);
        $country = trim($country);
        $gender = trim($gender);

        if ($nickname === '' || $phone === '' || $country === '' || $gender === '') {
            throw new ApiException('All identity fields are required.');
        }

        if (!$this->isValidBirthdate($birthdate)) {
            throw new ApiException('Invalid birthdate.');
        }

        if ($this->userExistsByPhone($phone)) {
            throw new ApiException('This phone number is already in use.');
        }

        $otherPending = $this->findPendingRegistrationByPhone($phone);
        if ($otherPending !== null && (int) $otherPending['id'] !== (int) $pending['id']) {
            throw new ApiException('This phone number is already reserved.');
        }

        $phoneOtp = $this->config['auth']['default_phone_otp_code'];
        $statement = $this->pdo->prepare(
            'UPDATE pending_registrations
             SET nickname = :nickname,
                 phone = :phone,
                 birthdate = :birthdate,
                 gender = :gender,
                 country = :country,
                 phone_otp_code = :phone_otp_code,
                 phone_verified_at = NULL,
                 updated_at = :updated_at
             WHERE id = :id'
        );
        $statement->execute([
            'nickname' => $nickname,
            'phone' => $phone,
            'birthdate' => $birthdate,
            'gender' => $gender,
            'country' => $country,
            'phone_otp_code' => $phoneOtp,
            'updated_at' => $this->now(),
            'id' => $pending['id'],
        ]);

        return [
            'registration_token' => $registrationToken,
            'phone' => $phone,
            'debug_phone_otp' => $phoneOtp,
        ];
    }

    public function verifyPhoneOtp(string $registrationToken, string $otp): array
    {
        $pending = $this->requirePendingRegistration($registrationToken);

        if (empty($pending['email_verified_at'])) {
            throw new ApiException('Email is not verified yet.');
        }

        if (empty($pending['phone']) || empty($pending['nickname'])) {
            throw new ApiException('Identity setup is incomplete.');
        }

        if ((string) $pending['phone_otp_code'] !== trim($otp)) {
            throw new ApiException('Invalid OTP code.');
        }

        $now = $this->now();
        $this->pdo->beginTransaction();

        try {
            $insertUser = $this->pdo->prepare(
                'INSERT INTO users
                    (email, phone, password_hash, nickname, birthdate, gender, country, status, email_verified_at, phone_verified_at, created_at, updated_at)
                 VALUES
                    (:email, :phone, :password_hash, :nickname, :birthdate, :gender, :country, :status, :email_verified_at, :phone_verified_at, :created_at, :updated_at)'
            );
            $insertUser->execute([
                'email' => $pending['email'],
                'phone' => $pending['phone'],
                'password_hash' => $pending['password_hash'],
                'nickname' => $pending['nickname'],
                'birthdate' => $pending['birthdate'],
                'gender' => $pending['gender'],
                'country' => $pending['country'],
                'status' => 'active',
                'email_verified_at' => $pending['email_verified_at'],
                'phone_verified_at' => $now,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $userId = (int) $this->pdo->lastInsertId();

            $createWallet = $this->pdo->prepare(
                'INSERT INTO user_wallets
                    (user_id, coins_balance, diamonds_balance, created_at, updated_at)
                 VALUES
                    (:user_id, :coins_balance, :diamonds_balance, :created_at, :updated_at)'
            );
            $createWallet->execute([
                'user_id' => $userId,
                'coins_balance' => 1235,
                'diamonds_balance' => 5,
                'created_at' => $now,
                'updated_at' => $now,
            ]);

            $deletePending = $this->pdo->prepare(
                'DELETE FROM pending_registrations WHERE id = :id'
            );
            $deletePending->execute(['id' => $pending['id']]);

            $token = $this->createAuthToken($userId);
            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }

        return [
            'token' => $token,
            'user' => $this->findUserById($userId),
        ];
    }

    public function loginByEmail(string $email, string $password): array
    {
        $email = strtolower(trim($email));
        $statement = $this->pdo->prepare(
            'SELECT * FROM users WHERE email = :email LIMIT 1'
        );
        $statement->execute(['email' => $email]);
        $user = $statement->fetch();

        return $this->authenticateUser($user, $password);
    }

    public function loginByPhone(string $phone, string $password): array
    {
        $statement = $this->pdo->prepare(
            'SELECT * FROM users WHERE phone = :phone LIMIT 1'
        );
        $statement->execute(['phone' => trim($phone)]);
        $user = $statement->fetch();

        return $this->authenticateUser($user, $password);
    }

    public function forgotPassword(string $email): array
    {
        $email = strtolower(trim($email));
        $statement = $this->pdo->prepare(
            'SELECT * FROM users WHERE email = :email LIMIT 1'
        );
        $statement->execute(['email' => $email]);
        $user = $statement->fetch();

        if ($user === false) {
            return [
                'email_masked' => $this->maskEmail($email),
                'debug_reset_token' => null,
            ];
        }

        $now = $this->now();
        $resetToken = TokenManager::generate(64);
        $resetCode = '99999';
        $expiresAt = $this->futureMinutes(
            (int) $this->config['auth']['password_reset_expiry_minutes']
        );

        $this->pdo->prepare(
            'UPDATE password_reset_tokens SET used_at = :used_at WHERE user_id = :user_id AND used_at IS NULL'
        )->execute([
            'used_at' => $now,
            'user_id' => $user['id'],
        ]);

        $insert = $this->pdo->prepare(
            'INSERT INTO password_reset_tokens
                (user_id, email_snapshot, reset_token, reset_code, expires_at, created_at)
             VALUES
                (:user_id, :email_snapshot, :reset_token, :reset_code, :expires_at, :created_at)'
        );
        $insert->execute([
            'user_id' => $user['id'],
            'email_snapshot' => $user['email'],
            'reset_token' => $resetToken,
            'reset_code' => $resetCode,
            'expires_at' => $expiresAt,
            'created_at' => $now,
        ]);

        return [
            'email_masked' => $this->maskEmail((string) $user['email']),
            'debug_reset_token' => $resetToken,
            'debug_reset_code' => $resetCode,
        ];
    }

    public function resetPassword(string $resetToken, string $password): void
    {
        $password = trim($password);

        if (mb_strlen($password) < 6) {
            throw new ApiException('Password must be at least 6 characters.');
        }

        $statement = $this->pdo->prepare(
            'SELECT * FROM password_reset_tokens
             WHERE reset_token = :reset_token AND used_at IS NULL AND expires_at > :now
             LIMIT 1'
        );
        $statement->execute([
            'reset_token' => trim($resetToken),
            'now' => $this->now(),
        ]);
        $reset = $statement->fetch();

        if ($reset === false) {
            throw new ApiException('Reset token is invalid or expired.');
        }

        $this->pdo->beginTransaction();

        try {
            $this->pdo->prepare(
                'UPDATE users SET password_hash = :password_hash, updated_at = :updated_at WHERE id = :id'
            )->execute([
                'password_hash' => password_hash($password, PASSWORD_DEFAULT),
                'updated_at' => $this->now(),
                'id' => $reset['user_id'],
            ]);

            $this->pdo->prepare(
                'UPDATE password_reset_tokens SET used_at = :used_at WHERE id = :id'
            )->execute([
                'used_at' => $this->now(),
                'id' => $reset['id'],
            ]);

            $this->pdo->commit();
        } catch (Throwable $throwable) {
            $this->pdo->rollBack();
            throw $throwable;
        }
    }

    public function me(?string $authorizationHeader): array
    {
        if ($authorizationHeader === null || !str_starts_with($authorizationHeader, 'Bearer ')) {
            throw new ApiException('Unauthenticated.', 401);
        }

        $plainToken = trim(substr($authorizationHeader, 7));
        if ($plainToken === '') {
            throw new ApiException('Unauthenticated.', 401);
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
            'token_hash' => TokenManager::hash($plainToken),
            'now' => $this->now(),
        ]);
        $user = $statement->fetch();

        if ($user === false) {
            throw new ApiException('Unauthenticated.', 401);
        }

        $this->pdo->prepare(
            'UPDATE auth_tokens SET last_used_at = :last_used_at WHERE token_hash = :token_hash'
        )->execute([
            'last_used_at' => $this->now(),
            'token_hash' => TokenManager::hash($plainToken),
        ]);

        return $this->normalizeUser($user);
    }

    private function authenticateUser(array|false $user, string $password): array
    {
        if ($user === false || !password_verify($password, (string) $user['password_hash'])) {
            throw new ApiException('Invalid credentials.', 401);
        }

        if (($user['status'] ?? 'active') !== 'active') {
            throw new ApiException('This account is suspended.', 403);
        }

        $token = $this->createAuthToken((int) $user['id']);

        return [
            'token' => $token,
            'user' => $this->normalizeUser($user),
        ];
    }

    private function createAuthToken(int $userId): string
    {
        $plainToken = TokenManager::generate(80);
        $statement = $this->pdo->prepare(
            'INSERT INTO auth_tokens
                (user_id, token_name, token_hash, expires_at, created_at)
             VALUES
                (:user_id, :token_name, :token_hash, :expires_at, :created_at)'
        );
        $statement->execute([
            'user_id' => $userId,
            'token_name' => 'mobile',
            'token_hash' => TokenManager::hash($plainToken),
            'expires_at' => $this->futureDays((int) $this->config['auth']['token_ttl_days']),
            'created_at' => $this->now(),
        ]);

        return $plainToken;
    }

    private function requirePendingRegistration(string $registrationToken): array
    {
        $statement = $this->pdo->prepare(
            'SELECT * FROM pending_registrations
             WHERE registration_token = :registration_token AND expires_at > :now
             LIMIT 1'
        );
        $statement->execute([
            'registration_token' => trim($registrationToken),
            'now' => $this->now(),
        ]);
        $pending = $statement->fetch();

        if ($pending === false) {
            throw new ApiException('Registration session is invalid or expired.', 404);
        }

        return $pending;
    }

    private function deleteExpiredPendingRegistrations(): void
    {
        $statement = $this->pdo->prepare(
            'DELETE FROM pending_registrations WHERE expires_at <= :now'
        );
        $statement->execute(['now' => $this->now()]);
    }

    private function findPendingRegistrationByEmail(string $email): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT * FROM pending_registrations WHERE email = :email LIMIT 1'
        );
        $statement->execute(['email' => $email]);
        $row = $statement->fetch();

        return $row === false ? null : $row;
    }

    private function findPendingRegistrationByPhone(string $phone): ?array
    {
        $statement = $this->pdo->prepare(
            'SELECT * FROM pending_registrations WHERE phone = :phone LIMIT 1'
        );
        $statement->execute(['phone' => $phone]);
        $row = $statement->fetch();

        return $row === false ? null : $row;
    }

    private function userExistsByEmail(string $email): bool
    {
        $statement = $this->pdo->prepare(
            'SELECT id FROM users WHERE email = :email LIMIT 1'
        );
        $statement->execute(['email' => $email]);

        return $statement->fetch() !== false;
    }

    private function userExistsByPhone(string $phone): bool
    {
        $statement = $this->pdo->prepare(
            'SELECT id FROM users WHERE phone = :phone LIMIT 1'
        );
        $statement->execute(['phone' => $phone]);

        return $statement->fetch() !== false;
    }

    private function findUserById(int $userId): array
    {
        $statement = $this->pdo->prepare('SELECT * FROM users WHERE id = :id LIMIT 1');
        $statement->execute(['id' => $userId]);
        $user = $statement->fetch();

        if ($user === false) {
            throw new ApiException('User not found.', 404);
        }

        return $this->normalizeUser($user);
    }

    private function normalizeUser(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'email' => $user['email'],
            'phone' => $user['phone'],
            'nickname' => $user['nickname'],
            'birthdate' => $user['birthdate'],
            'gender' => $user['gender'],
            'country' => $user['country'],
            'status' => $user['status'],
            'email_verified' => !empty($user['email_verified_at']),
            'phone_verified' => !empty($user['phone_verified_at']),
        ];
    }

    private function maskEmail(string $email): string
    {
        $parts = explode('@', $email);
        if (count($parts) !== 2) {
            return $email;
        }

        $name = $parts[0];
        $domain = $parts[1];

        if (mb_strlen($name) <= 2) {
            return mb_substr($name, 0, 1) . str_repeat('*', max(mb_strlen($name) - 1, 1)) . '@' . $domain;
        }

        return mb_substr($name, 0, 2) . str_repeat('*', max(mb_strlen($name) - 2, 5)) . '@' . $domain;
    }

    private function now(): string
    {
        return gmdate('Y-m-d H:i:s');
    }

    private function futureMinutes(int $minutes): string
    {
        return gmdate('Y-m-d H:i:s', time() + ($minutes * 60));
    }

    private function futureDays(int $days): string
    {
        return gmdate('Y-m-d H:i:s', time() + ($days * 86400));
    }

    private function isValidBirthdate(string $birthdate): bool
    {
        $parsed = date_create($birthdate);
        return $parsed !== false && $parsed->format('Y-m-d') === $birthdate;
    }
}
