<?php

declare(strict_types=1);

session_start();

$config = require __DIR__ . '/../config/app.php';

require_once __DIR__ . '/../src/Database.php';

function admin_pdo(): PDO
{
    global $config;
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $pdo = Database::connection($config['db']);
    admin_seed_default_account($pdo, $config['admin']);

    return $pdo;
}

function admin_seed_default_account(PDO $pdo, array $adminConfig): void
{
    $statement = $pdo->prepare('SELECT id FROM admins WHERE email = :email LIMIT 1');
    $statement->execute(['email' => $adminConfig['seed_email']]);

    if ($statement->fetch() !== false) {
        return;
    }

    $now = gmdate('Y-m-d H:i:s');
    $insert = $pdo->prepare(
        'INSERT INTO admins
            (name, email, password_hash, role, is_active, created_at, updated_at)
         VALUES
            (:name, :email, :password_hash, :role, :is_active, :created_at, :updated_at)'
    );
    $insert->execute([
        'name' => $adminConfig['seed_name'],
        'email' => $adminConfig['seed_email'],
        'password_hash' => $adminConfig['seed_password_hash'],
        'role' => 'super_admin',
        'is_active' => 1,
        'created_at' => $now,
        'updated_at' => $now,
    ]);
}

function admin_attempt_login(string $email, string $password): bool
{
    $statement = admin_pdo()->prepare(
        'SELECT * FROM admins WHERE email = :email AND is_active = 1 LIMIT 1'
    );
    $statement->execute(['email' => strtolower(trim($email))]);
    $admin = $statement->fetch();

    if ($admin === false || !password_verify($password, (string) $admin['password_hash'])) {
        return false;
    }

    $_SESSION['admin_id'] = (int) $admin['id'];

    return true;
}

function admin_current_user(): ?array
{
    if (!isset($_SESSION['admin_id'])) {
        return null;
    }

    $statement = admin_pdo()->prepare('SELECT * FROM admins WHERE id = :id LIMIT 1');
    $statement->execute(['id' => $_SESSION['admin_id']]);
    $admin = $statement->fetch();

    return $admin === false ? null : $admin;
}

function admin_require_auth(): array
{
    $admin = admin_current_user();

    if ($admin === null) {
        header('Location: /admin/login.php');
        exit;
    }

    return $admin;
}

function admin_redirect(string $path): never
{
    header('Location: ' . $path);
    exit;
}

function admin_render_header(string $title, string $active = ''): void
{
    $admin = admin_current_user();
    ?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= htmlspecialchars($title) ?></title>
    <link rel="stylesheet" href="/admin/assets/style.css">
</head>
<body>
<div class="admin-shell">
    <aside class="sidebar">
        <div class="brand">
            <div class="brand-badge">VL</div>
            <div>
                <div class="brand-title">Voice Live</div>
                <div class="brand-subtitle">Admin Control</div>
            </div>
        </div>
        <nav class="nav-links">
            <a class="<?= $active === 'dashboard' ? 'active' : '' ?>" href="/admin/index.php">لوحة التحكم</a>
            <a class="<?= $active === 'users' ? 'active' : '' ?>" href="/admin/users.php">المستخدمون</a>
            <a class="<?= $active === 'rooms' ? 'active' : '' ?>" href="/admin/rooms.php">الغرف الصوتية</a>
            <a class="<?= $active === 'music-tracks' ? 'active' : '' ?>" href="/admin/music-tracks.php">الموسيقى</a>
            <a class="<?= $active === 'gifts' ? 'active' : '' ?>" href="/admin/gifts.php">الهدايا</a>
            <a class="<?= $active === 'gift-transactions' ? 'active' : '' ?>" href="/admin/gift-transactions.php">سجل الهدايا</a>
            <a href="/admin/logout.php">تسجيل الخروج</a>
        </nav>
        <?php if ($admin !== null): ?>
            <div class="sidebar-footer">
                <div class="sidebar-footer-label">المسؤول الحالي</div>
                <div class="sidebar-footer-value"><?= htmlspecialchars((string) $admin['email']) ?></div>
            </div>
        <?php endif; ?>
    </aside>
    <main class="content">
        <header class="content-header">
            <h1><?= htmlspecialchars($title) ?></h1>
        </header>
<?php
}

function admin_render_footer(): void
{
    ?>
    </main>
</div>
</body>
</html>
<?php
}
