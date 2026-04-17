<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/GiftService.php';
require_once __DIR__ . '/../src/RoomMusicService.php';
require_once __DIR__ . '/../src/RoomService.php';

$admin = admin_require_auth();
$pdo = admin_pdo();
$giftService = new GiftService($pdo);
$roomMusicService = new RoomMusicService($pdo);
$roomService = new RoomService($pdo);
$roomStats = $roomService->adminRoomStats();
$giftStats = $giftService->adminGiftStats();
$musicStats = $roomMusicService->adminMusicStats();

$totals = [
    'users' => (int) $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn(),
    'verified_emails' => (int) $pdo->query('SELECT COUNT(*) FROM users WHERE email_verified_at IS NOT NULL')->fetchColumn(),
    'verified_phones' => (int) $pdo->query('SELECT COUNT(*) FROM users WHERE phone_verified_at IS NOT NULL')->fetchColumn(),
    'pending_registrations' => (int) $pdo->query('SELECT COUNT(*) FROM pending_registrations')->fetchColumn(),
    'rooms' => $roomStats['rooms'],
    'active_rooms' => $roomStats['active_rooms'],
    'pending_seat_requests' => $roomStats['pending_seat_requests'],
    'gifts' => $giftStats['gifts'],
    'gift_transactions' => $giftStats['sent_transactions'],
    'gift_spent_coins' => $giftStats['spent_coins'],
    'music_tracks' => $musicStats['tracks'],
    'room_playlist_entries' => $musicStats['playlist_entries'],
];

admin_render_header('لوحة التحكم', 'dashboard');
?>
<section class="stats-grid">
    <article class="stat-card">
        <div class="stat-label">إجمالي المستخدمين</div>
        <div class="stat-value"><?= $totals['users'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">البريد الموثق</div>
        <div class="stat-value"><?= $totals['verified_emails'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">الهواتف الموثقة</div>
        <div class="stat-value"><?= $totals['verified_phones'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">تسجيلات معلقة</div>
        <div class="stat-value"><?= $totals['pending_registrations'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">الغرف الصوتية</div>
        <div class="stat-value"><?= $totals['rooms'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">الغرف النشطة</div>
        <div class="stat-value"><?= $totals['active_rooms'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">طلبات المايك</div>
        <div class="stat-value"><?= $totals['pending_seat_requests'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">الهدايا</div>
        <div class="stat-value"><?= $totals['gifts'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">عمليات الإرسال</div>
        <div class="stat-value"><?= $totals['gift_transactions'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">العملات المصروفة</div>
        <div class="stat-value"><?= $totals['gift_spent_coins'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">المقاطع الموسيقية</div>
        <div class="stat-value"><?= $totals['music_tracks'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">قوائم التشغيل</div>
        <div class="stat-value"><?= $totals['room_playlist_entries'] ?></div>
    </article>
</section>

<section class="panel">
    <div class="panel-title">نطاق هذه المرحلة</div>
    <p class="panel-copy">
        هذه اللوحة تغطي المسارات المنفذة حاليًا: المستخدمون، الغرف الصوتية، الهدايا، والموسيقى داخل الغرفة.
        من هنا يمكن مراجعة المستخدمين، إدارة الغرف، تعديل كتالوج الهدايا والموسيقى، ومتابعة العمليات.
    </p>
    <div class="action-row">
        <a class="btn btn-primary" href="/admin/users.php">إدارة المستخدمين</a>
        <a class="btn btn-secondary" href="/admin/rooms.php">إدارة الغرف</a>
        <a class="btn btn-secondary" href="/admin/music-tracks.php">إدارة الموسيقى</a>
        <a class="btn btn-secondary" href="/admin/gifts.php">إدارة الهدايا</a>
    </div>
</section>

<section class="panel">
    <div class="panel-title">المسؤول الحالي</div>
    <div class="detail-grid">
        <div><strong>الاسم:</strong> <?= htmlspecialchars((string) $admin['name']) ?></div>
        <div><strong>البريد:</strong> <?= htmlspecialchars((string) $admin['email']) ?></div>
        <div><strong>الدور:</strong> <?= htmlspecialchars((string) $admin['role']) ?></div>
    </div>
</section>
<?php admin_render_footer(); ?>
