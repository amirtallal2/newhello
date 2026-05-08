<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/AgencyService.php';
require_once __DIR__ . '/../src/ChatService.php';
require_once __DIR__ . '/../src/GiftService.php';
require_once __DIR__ . '/../src/LiveService.php';
require_once __DIR__ . '/../src/PostService.php';
require_once __DIR__ . '/../src/RoomGameService.php';
require_once __DIR__ . '/../src/RoomMusicService.php';
require_once __DIR__ . '/../src/RoomService.php';
require_once __DIR__ . '/../src/SupportService.php';

$admin = admin_require_auth();
$pdo = admin_pdo();
$agencyService = new AgencyService($pdo);
$chatService = new ChatService($pdo);
$giftService = new GiftService($pdo);
$liveService = new LiveService($pdo);
$postService = new PostService($pdo);
$roomGameService = new RoomGameService($pdo);
$roomMusicService = new RoomMusicService($pdo);
$roomService = new RoomService($pdo);
$supportService = new SupportService($pdo);
$roomStats = $roomService->adminRoomStats();
$giftStats = $giftService->adminGiftStats();
$liveStats = $liveService->adminStats();
$chatStats = $chatService->adminThreadStats();
$postStats = $postService->adminPostStats();
$roomGameStats = $roomGameService->adminStats();
$musicStats = $roomMusicService->adminMusicStats();
$agencyStats = $agencyService->adminStats();
$supportStats = $supportService->adminSupportStats();

$totals = [
    'users' => (int) $pdo->query('SELECT COUNT(*) FROM users')->fetchColumn(),
    'verified_emails' => (int) $pdo->query('SELECT COUNT(*) FROM users WHERE email_verified_at IS NOT NULL')->fetchColumn(),
    'verified_phones' => (int) $pdo->query('SELECT COUNT(*) FROM users WHERE phone_verified_at IS NOT NULL')->fetchColumn(),
    'pending_registrations' => (int) $pdo->query('SELECT COUNT(*) FROM pending_registrations')->fetchColumn(),
    'rooms' => $roomStats['rooms'],
    'active_rooms' => $roomStats['active_rooms'],
    'pending_seat_requests' => $roomStats['pending_seat_requests'],
    'room_games' => $roomGameStats['catalog_games'],
    'active_room_games' => $roomGameStats['active_games'],
    'room_game_sessions' => $roomGameStats['active_sessions'],
    'room_game_players' => $roomGameStats['active_players'],
    'live_rooms' => $liveStats['rooms'],
    'active_live_rooms' => $liveStats['active_rooms'],
    'live_viewers' => $liveStats['viewers'],
    'live_comments' => $liveStats['comments'],
    'live_reports' => $liveStats['reports'],
    'live_gift_transactions' => $liveStats['gift_transactions'],
    'live_pk_invites' => $liveStats['pk_invites'],
    'live_notifications' => $liveStats['notifications'],
    'gifts' => $giftStats['gifts'],
    'gift_transactions' => $giftStats['sent_transactions'],
    'gift_spent_coins' => $giftStats['spent_coins'],
    'chat_threads' => $chatStats['threads'],
    'chat_unread_threads' => $chatStats['unread_threads'],
    'chat_messages' => $chatStats['messages'],
    'posts' => $postStats['posts'],
    'active_posts' => $postStats['active_posts'],
    'post_comments' => $postStats['comments'],
    'post_reports' => $postStats['reports'],
    'open_post_reports' => $postStats['open_reports'],
    'music_tracks' => $musicStats['tracks'],
    'room_playlist_entries' => $musicStats['playlist_entries'],
    'agencies' => $agencyStats['agencies'],
    'active_agencies' => $agencyStats['active_agencies'],
    'agency_open_requests' => $agencyStats['open_requests'],
    'pending_agency_open_requests' => $agencyStats['pending_open_requests'],
    'agency_join_requests' => $agencyStats['join_requests'],
    'pending_agency_join_requests' => $agencyStats['pending_join_requests'],
    'shipping_agencies' => $supportStats['shipping_agencies'],
    'active_shipping_agencies' => $supportStats['active_shipping_agencies'],
    'support_tickets' => $supportStats['support_tickets'],
    'open_support_tickets' => $supportStats['open_support_tickets'],
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
        <div class="stat-label">ألعاب الغرف</div>
        <div class="stat-value"><?= $totals['room_games'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">ألعاب الغرف النشطة</div>
        <div class="stat-value"><?= $totals['active_room_games'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">جلسات الألعاب</div>
        <div class="stat-value"><?= $totals['room_game_sessions'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">لاعبو الجلسات</div>
        <div class="stat-value"><?= $totals['room_game_players'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">جلسات اللايف</div>
        <div class="stat-value"><?= $totals['live_rooms'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">جلسات اللايف النشطة</div>
        <div class="stat-value"><?= $totals['active_live_rooms'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">مشاهدو اللايف</div>
        <div class="stat-value"><?= $totals['live_viewers'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">تعليقات اللايف</div>
        <div class="stat-value"><?= $totals['live_comments'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">بلاغات اللايف</div>
        <div class="stat-value"><?= $totals['live_reports'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">هدايا اللايف</div>
        <div class="stat-value"><?= $totals['live_gift_transactions'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">دعوات PK</div>
        <div class="stat-value"><?= $totals['live_pk_invites'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">إشعارات اللايف</div>
        <div class="stat-value"><?= $totals['live_notifications'] ?></div>
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
        <div class="stat-label">المحادثات</div>
        <div class="stat-value"><?= $totals['chat_threads'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">المحادثات غير المقروءة</div>
        <div class="stat-value"><?= $totals['chat_unread_threads'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">رسائل الشات</div>
        <div class="stat-value"><?= $totals['chat_messages'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">البوستات</div>
        <div class="stat-value"><?= $totals['posts'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">البوستات النشطة</div>
        <div class="stat-value"><?= $totals['active_posts'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">تعليقات البوست</div>
        <div class="stat-value"><?= $totals['post_comments'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">بلاغات البوست</div>
        <div class="stat-value"><?= $totals['post_reports'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">البلاغات المفتوحة</div>
        <div class="stat-value"><?= $totals['open_post_reports'] ?></div>
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
    <article class="stat-card">
        <div class="stat-label">وكالات التطبيق</div>
        <div class="stat-value"><?= $totals['agencies'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">الوكالات النشطة</div>
        <div class="stat-value"><?= $totals['active_agencies'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">طلبات فتح وكالة</div>
        <div class="stat-value"><?= $totals['agency_open_requests'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">طلبات فتح معلقة</div>
        <div class="stat-value"><?= $totals['pending_agency_open_requests'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">طلبات الانضمام</div>
        <div class="stat-value"><?= $totals['agency_join_requests'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">طلبات الانضمام المعلقة</div>
        <div class="stat-value"><?= $totals['pending_agency_join_requests'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">وكالات الشحن</div>
        <div class="stat-value"><?= $totals['shipping_agencies'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">الوكالات النشطة</div>
        <div class="stat-value"><?= $totals['active_shipping_agencies'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">تذاكر الدعم</div>
        <div class="stat-value"><?= $totals['support_tickets'] ?></div>
    </article>
    <article class="stat-card">
        <div class="stat-label">التذاكر المفتوحة</div>
        <div class="stat-value"><?= $totals['open_support_tickets'] ?></div>
    </article>
</section>

<section class="panel">
    <div class="panel-title">نطاق هذه المرحلة</div>
    <p class="panel-copy">
        هذه اللوحة تغطي المسارات المنفذة حاليًا: المستخدمون، الغرف الصوتية، الهدايا، الشات،
        البوستات، الموسيقى داخل الغرفة، ألعاب الغرف، مركز الدعم الفني، الوكالات، ووكالات الشحن. من هنا يمكن مراجعة
        المستخدمين، إدارة الغرف، تعديل كتالوج الهدايا والموسيقى والألعاب، متابعة الشات والرسائل،
        الإشراف على البوستات والبلاغات، متابعة التذاكر، وإدارة بيانات الوكالات والوكلاء.
    </p>
    <div class="action-row">
        <a class="btn btn-primary" href="/admin/users.php">إدارة المستخدمين</a>
        <a class="btn btn-secondary" href="/admin/rooms.php">إدارة الغرف</a>
        <a class="btn btn-secondary" href="/admin/room-games.php">ألعاب الغرف</a>
        <a class="btn btn-secondary" href="/admin/room-game-sessions.php">جلسات الألعاب</a>
        <a class="btn btn-secondary" href="/admin/live-rooms.php">إدارة اللايف</a>
        <a class="btn btn-secondary" href="/admin/music-tracks.php">إدارة الموسيقى</a>
        <a class="btn btn-secondary" href="/admin/gifts.php">إدارة الهدايا</a>
        <a class="btn btn-secondary" href="/admin/chat-threads.php">إدارة المحادثات</a>
        <a class="btn btn-secondary" href="/admin/posts.php">إدارة البوستات</a>
        <a class="btn btn-secondary" href="/admin/post-reports.php">بلاغات البوست</a>
        <a class="btn btn-secondary" href="/admin/agencies.php">إدارة الوكالات</a>
        <a class="btn btn-secondary" href="/admin/agency-open-requests.php">طلبات فتح وكالة</a>
        <a class="btn btn-secondary" href="/admin/agency-join-requests.php">طلبات الانضمام</a>
        <a class="btn btn-secondary" href="/admin/shipping-agencies.php">وكالات الشحن</a>
        <a class="btn btn-secondary" href="/admin/support-tickets.php">تذاكر الدعم</a>
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
