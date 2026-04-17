<?php

declare(strict_types=1);

final class Database
{
    private static ?PDO $connection = null;

    public static function connection(array $config): PDO
    {
        if (self::$connection instanceof PDO) {
            return self::$connection;
        }

        $driver = $config['driver'] ?? 'mysql';

        if ($driver === 'sqlite') {
            $dsn = 'sqlite:' . $config['sqlite_path'];
            self::$connection = new PDO($dsn);
        } else {
            $host = $config['host'] ?? '127.0.0.1';
            $port = (int) ($config['port'] ?? 3306);
            $database = $config['database'] ?? '';
            $charset = $config['charset'] ?? 'utf8mb4';
            $dsn = sprintf(
                'mysql:host=%s;port=%d;dbname=%s;charset=%s',
                $host,
                $port,
                $database,
                $charset
            );

            self::$connection = new PDO(
                $dsn,
                $config['username'] ?? '',
                $config['password'] ?? ''
            );
        }

        self::$connection->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        self::$connection->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

        return self::$connection;
    }
}
