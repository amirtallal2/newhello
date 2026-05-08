<?php

declare(strict_types=1);

session_start();

$config = require __DIR__ . '/../config/app.php';

require_once __DIR__ . '/../src/Database.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/EconomyService.php';
require_once __DIR__ . '/../src/LevelService.php';
require_once __DIR__ . '/../src/ReferralService.php';

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

function admin_nav_items(): array
{
    return [
        ['key' => 'dashboard', 'href' => '/admin/index.php', 'label' => 'لوحة التحكم', 'icon' => 'dashboard'],
        ['key' => 'users', 'href' => '/admin/users.php', 'label' => 'المستخدمون', 'icon' => 'users'],
        ['key' => 'rooms', 'href' => '/admin/rooms.php', 'label' => 'الغرف الصوتية', 'icon' => 'mic'],
        ['key' => 'clubs', 'href' => '/admin/clubs.php', 'label' => 'النوادي', 'icon' => 'building'],
        ['key' => 'room-games', 'href' => '/admin/room-games.php', 'label' => 'ألعاب الغرف', 'icon' => 'game'],
        ['key' => 'room-game-sessions', 'href' => '/admin/room-game-sessions.php', 'label' => 'جلسات الألعاب', 'icon' => 'layers'],
        ['key' => 'live-rooms', 'href' => '/admin/live-rooms.php', 'label' => 'اللايف', 'icon' => 'live'],
        ['key' => 'live-actions', 'href' => '/admin/live-actions.php', 'label' => 'أزرار اللايف', 'icon' => 'activity'],
        ['key' => 'live-gift-transactions', 'href' => '/admin/live-gift-transactions.php', 'label' => 'هدايا اللايف', 'icon' => 'gift'],
        ['key' => 'live-reports', 'href' => '/admin/live-reports.php', 'label' => 'بلاغات اللايف', 'icon' => 'shield'],
        ['key' => 'live-notifications', 'href' => '/admin/live-notifications.php', 'label' => 'إشعارات اللايف', 'icon' => 'bell'],
        ['key' => 'live-pk-invites', 'href' => '/admin/live-pk-invites.php', 'label' => 'دعوات PK', 'icon' => 'sparkles'],
        ['key' => 'music-tracks', 'href' => '/admin/music-tracks.php', 'label' => 'الموسيقى', 'icon' => 'music'],
        ['key' => 'gifts', 'href' => '/admin/gifts.php', 'label' => 'الهدايا', 'icon' => 'gift'],
        ['key' => 'gift-transactions', 'href' => '/admin/gift-transactions.php', 'label' => 'سجل الهدايا', 'icon' => 'coins'],
        ['key' => 'vip-levels', 'href' => '/admin/vip-levels.php', 'label' => 'مستويات VIP', 'icon' => 'sparkles'],
        ['key' => 'referrals', 'href' => '/admin/referrals.php', 'label' => 'الدعوات والأرباح', 'icon' => 'link'],
        ['key' => 'wallet-packages', 'href' => '/admin/wallet-packages.php', 'label' => 'باقات الشحن', 'icon' => 'wallet'],
        ['key' => 'store-items', 'href' => '/admin/store-items.php', 'label' => 'عناصر المتجر', 'icon' => 'store'],
        ['key' => 'economy-transactions', 'href' => '/admin/economy-transactions.php', 'label' => 'عمليات المتجر والمحفظة', 'icon' => 'activity'],
        ['key' => 'agencies', 'href' => '/admin/agencies.php', 'label' => 'الوكالات', 'icon' => 'building'],
        ['key' => 'agency-open-requests', 'href' => '/admin/agency-open-requests.php', 'label' => 'طلبات فتح وكالة', 'icon' => 'document'],
        ['key' => 'agency-join-requests', 'href' => '/admin/agency-join-requests.php', 'label' => 'طلبات الانضمام للوكالة', 'icon' => 'link'],
        ['key' => 'chat-threads', 'href' => '/admin/chat-threads.php', 'label' => 'المحادثات', 'icon' => 'chat'],
        ['key' => 'posts', 'href' => '/admin/posts.php', 'label' => 'البوستات', 'icon' => 'posts'],
        ['key' => 'post-reports', 'href' => '/admin/post-reports.php', 'label' => 'بلاغات البوست', 'icon' => 'flag'],
        ['key' => 'post-report-reasons', 'href' => '/admin/post-report-reasons.php', 'label' => 'أسباب بلاغات البوست', 'icon' => 'shield'],
        ['key' => 'shipping-agencies', 'href' => '/admin/shipping-agencies.php', 'label' => 'وكالات الشحن', 'icon' => 'truck'],
        ['key' => 'support-tickets', 'href' => '/admin/support-tickets.php', 'label' => 'تذاكر الدعم', 'icon' => 'support'],
    ];
}

function admin_brand_name(): string
{
    return 'Hallo Party';
}

function admin_brand_subtitle(): string
{
    return 'Admin Control';
}

function admin_brand_logo_url(): string
{
    return '/app-assets/images/splash_logo.png';
}

function admin_svg_icon(string $name, string $class = 'nav-icon'): string
{
    $paths = match ($name) {
        'dashboard' => '<path d="M4 12.5A2.5 2.5 0 0 1 6.5 10H10v8H6.5A2.5 2.5 0 0 1 4 15.5zM12 10h5.5A2.5 2.5 0 0 1 20 12.5v3A2.5 2.5 0 0 1 17.5 18H12zM4 6.5A2.5 2.5 0 0 1 6.5 4H10v4H4zM12 4h5.5A2.5 2.5 0 0 1 20 6.5V8h-8z" fill="currentColor"/>',
        'users' => '<path d="M12 12a4 4 0 1 0-4-4 4 4 0 0 0 4 4zm-6.8 7a6.8 6.8 0 0 1 13.6 0" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M18.5 10.5a3 3 0 1 0-2.1-5.1" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        'mic' => '<path d="M12 15a3 3 0 0 0 3-3V7a3 3 0 1 0-6 0v5a3 3 0 0 0 3 3z" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M6.5 11.5a5.5 5.5 0 0 0 11 0M12 17v3M9 20h6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        'game' => '<path d="M8 9h8a3.5 3.5 0 0 1 3.4 4.2l-.8 3.3A2.5 2.5 0 0 1 16.2 18h-.6a2 2 0 0 1-1.8-1.1L13 15h-2l-.8 1.9A2 2 0 0 1 8.4 18h-.6a2.5 2.5 0 0 1-2.4-1.5l-.8-3.3A3.5 3.5 0 0 1 8 9z" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M8.5 13h3M10 11.5v3M16 12.5h.01M18 14.5h.01" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        'layers' => '<path d="m12 4 8 4-8 4-8-4 8-4zm-8 8 8 4 8-4M4 16l8 4 8-4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>',
        'live' => '<path d="M8 7.5A5.5 5.5 0 0 0 8 16.5M16 7.5A5.5 5.5 0 0 1 16 16.5M6 5A8.5 8.5 0 0 0 6 19M18 5a8.5 8.5 0 0 1 0 14" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="12" cy="12" r="2.5" fill="currentColor"/>',
        'gift' => '<path d="M12 7v13M5 10h14M6.5 7H17a1.5 1.5 0 0 1 1.5 1.5V19a1 1 0 0 1-1 1h-11a1 1 0 0 1-1-1V8.5A1.5 1.5 0 0 1 7 7z" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M9 7c-1.7 0-2.5-.8-2.5-2S7.3 2.5 9 4l3 3m3 0c1.7 0 2.5-.8 2.5-2S16.7 2.5 15 4l-3 3" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        'shield' => '<path d="M12 3 5 6v5c0 4.3 2.8 7.7 7 9 4.2-1.3 7-4.7 7-9V6z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>',
        'bell' => '<path d="M9 18h6M7 15h10l-1.2-1.6A3 3 0 0 1 15 11.6V10a3 3 0 1 0-6 0v1.6a3 3 0 0 1-.8 1.8z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
        'sparkles' => '<path d="M12 3l1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5L12 3zm6 10 1 3 3 1-3 1-1 3-1-3-3-1 3-1 1-3zM5 14l.8 2.2L8 17l-2.2.8L5 20l-.8-2.2L2 17l2.2-.8L5 14z" fill="currentColor"/>',
        'music' => '<path d="M14 4v9.5a2.5 2.5 0 1 1-1.8-2.4V6.2L18 5v7.5a2.5 2.5 0 1 1-1.8-2.4V4.3z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>',
        'coins' => '<ellipse cx="12" cy="7" rx="5.5" ry="2.5" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M6.5 7v4c0 1.4 2.5 2.5 5.5 2.5s5.5-1.1 5.5-2.5V7M6.5 11v4c0 1.4 2.5 2.5 5.5 2.5s5.5-1.1 5.5-2.5v-4" fill="none" stroke="currentColor" stroke-width="1.8"/>',
        'wallet' => '<path d="M5 7.5A2.5 2.5 0 0 1 7.5 5H18v14H7.5A2.5 2.5 0 0 1 5 16.5z" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M18 9h2v6h-2M15 12h.01" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        'store' => '<path d="M5 8h14l-1 11H6L5 8zm1.5 0 1.1-3h8.8l1.1 3M9 11v5M12 11v5M15 11v5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
        'activity' => '<path d="M4 12h4l2-4 4 8 2-4h4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
        'building' => '<path d="M6 20V6l6-2 6 2v14M9 9h.01M15 9h.01M9 13h.01M15 13h.01M10 20v-4h4v4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
        'document' => '<path d="M8 4h6l4 4v12H8z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/><path d="M14 4v4h4M10 13h6M10 17h6M10 9h2" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        'link' => '<path d="M10.5 13.5 13.5 10.5M8.8 15.2l-1.6 1.6a3 3 0 1 1-4.2-4.2l3-3a3 3 0 0 1 4.2 0M15.2 8.8l1.6-1.6a3 3 0 1 1 4.2 4.2l-3 3a3 3 0 0 1-4.2 0" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        'chat' => '<path d="M6 6.5A2.5 2.5 0 0 1 8.5 4h7A2.5 2.5 0 0 1 18 6.5v5A2.5 2.5 0 0 1 15.5 14H11l-3 3v-3H8.5A2.5 2.5 0 0 1 6 11.5z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>',
        'posts' => '<path d="M6 5h12v14H6z" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M9 9h6M9 12h6M9 15h4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>',
        'flag' => '<path d="M6 20V5m0 0h9l-1 3 1 3H6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
        'truck' => '<path d="M4 8h10v7H4zM14 10h3l2 2v3h-5M7 18.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3zm9 0a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
        'support' => '<path d="M12 18v-2.2M8.6 9.5a3.4 3.4 0 1 1 6.8 0c0 2.2-2.1 2.8-2.9 4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.8"/>',
        'logout' => '<path d="M15 16l4-4-4-4M19 12H9M11 5H6a2 2 0 0 0-2 2v10a2 2 0 0 0 2 2h5" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>',
        default => '<circle cx="12" cy="12" r="7" fill="none" stroke="currentColor" stroke-width="1.8"/>',
    };

    return sprintf(
        '<svg class="%s" viewBox="0 0 24 24" aria-hidden="true" focusable="false">%s</svg>',
        htmlspecialchars($class, ENT_QUOTES),
        $paths
    );
}

function admin_media_url(?string $path): ?string
{
    $path = trim((string) $path);
    if ($path === '') {
        return null;
    }

    if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
        return $path;
    }

    if (str_starts_with($path, '/storage/') || str_starts_with($path, '/app-assets/')) {
        return $path;
    }

    if (str_starts_with($path, 'storage/')) {
        return '/' . $path;
    }

    if (str_starts_with($path, 'assets/')) {
        return '/app-assets/' . substr($path, strlen('assets/'));
    }

    return $path[0] === '/' ? $path : '/' . ltrim($path, '/');
}

function admin_render_media_preview(?string $path, string $alt = 'media', string $class = 'table-media-thumb'): string
{
    $url = admin_media_url($path);

    if ($url === null) {
        return '<span class="media-thumb-empty">بدون صورة</span>';
    }

    $safeUrl = htmlspecialchars($url, ENT_QUOTES);
    $safeAlt = htmlspecialchars($alt, ENT_QUOTES);

    return sprintf(
        '<a class="media-thumb-link" href="%s" target="_blank" rel="noopener"><img class="%s" src="%s" alt="%s"></a>',
        $safeUrl,
        htmlspecialchars($class, ENT_QUOTES),
        $safeUrl,
        $safeAlt
    );
}

function admin_render_audio_preview(?string $path): string
{
    $url = admin_media_url($path);

    if ($url === null) {
        return '<span class="media-thumb-empty">بدون صوت</span>';
    }

    $safeUrl = htmlspecialchars($url, ENT_QUOTES);

    return sprintf(
        '<audio class="admin-audio-preview" controls preload="none" src="%s"></audio>',
        $safeUrl
    );
}

function admin_render_header(string $title, string $active = '', ?string $eyebrow = null): void
{
    $admin = admin_current_user();
    $eyebrowText = $eyebrow ?? 'لوحة التحكم';
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
    <aside class="sidebar" id="admin-sidebar">
        <div class="brand">
            <div class="brand-badge">
                <img class="brand-logo-image" src="<?= htmlspecialchars(admin_brand_logo_url(), ENT_QUOTES) ?>" alt="<?= htmlspecialchars(admin_brand_name(), ENT_QUOTES) ?>">
            </div>
            <div>
                <div class="brand-title"><?= htmlspecialchars(admin_brand_name()) ?></div>
                <div class="brand-subtitle"><?= htmlspecialchars(admin_brand_subtitle()) ?></div>
            </div>
        </div>
        <nav class="nav-links">
            <?php foreach (admin_nav_items() as $item): ?>
                <a class="<?= $active === $item['key'] ? 'active' : '' ?>" href="<?= htmlspecialchars($item['href']) ?>">
                    <?= admin_svg_icon((string) $item['icon']) ?>
                    <span><?= htmlspecialchars((string) $item['label']) ?></span>
                </a>
            <?php endforeach; ?>
            <a href="/admin/logout.php" class="nav-logout">
                <?= admin_svg_icon('logout') ?>
                <span>تسجيل الخروج</span>
            </a>
        </nav>
        <?php if ($admin !== null): ?>
            <div class="sidebar-footer">
                <div class="sidebar-footer-label">المسؤول الحالي</div>
                <div class="sidebar-footer-value"><?= htmlspecialchars((string) $admin['email']) ?></div>
            </div>
        <?php endif; ?>
    </aside>
    <button
        type="button"
        class="sidebar-backdrop"
        id="sidebar-backdrop"
        aria-label="إغلاق القائمة"
    ></button>
    <main class="content">
        <header class="content-header">
            <div class="content-header-primary">
                <button
                    type="button"
                    class="mobile-nav-toggle"
                    id="mobile-nav-toggle"
                    aria-expanded="false"
                    aria-controls="admin-sidebar"
                >
                    <?= admin_svg_icon('dashboard', 'header-pill-icon') ?>
                    <span>القائمة</span>
                </button>
                <div>
                    <div class="page-eyebrow"><?= htmlspecialchars($eyebrowText) ?></div>
                    <h1><?= htmlspecialchars($title) ?></h1>
                </div>
            </div>
            <?php if ($admin !== null): ?>
                <div class="header-admin-pill">
                    <?= admin_svg_icon('users', 'header-pill-icon') ?>
                    <div>
                        <strong><?= htmlspecialchars((string) ($admin['name'] ?? 'Administrator')) ?></strong>
                        <span><?= htmlspecialchars((string) $admin['email']) ?></span>
                    </div>
                </div>
            <?php endif; ?>
        </header>
<?php
}

function admin_render_footer(): void
{
    ?>
    </main>
</div>
<script>
(() => {
    const body = document.body;
    const toggle = document.getElementById('mobile-nav-toggle');
    const backdrop = document.getElementById('sidebar-backdrop');

    if (!toggle || !backdrop) {
        return;
    }

    const setOpen = (open) => {
        body.classList.toggle('admin-mobile-nav-open', open);
        toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    };

    toggle.addEventListener('click', () => {
        setOpen(!body.classList.contains('admin-mobile-nav-open'));
    });

    backdrop.addEventListener('click', () => {
        setOpen(false);
    });

    window.addEventListener('resize', () => {
        if (window.innerWidth > 860) {
            setOpen(false);
        }
    });
})();
</script>
</body>
</html>
<?php
}
