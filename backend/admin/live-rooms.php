<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/LiveService.php';

admin_require_auth();
$pdo = admin_pdo();
$liveService = new LiveService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $roomId = (int) ($_POST['room_id'] ?? 0);
    $action = (string) ($_POST['action'] ?? '');

    if ($roomId > 0 && in_array($action, ['hide', 'activate'], true)) {
        $liveService->adminSetRoomStatus($roomId, $action === 'activate' ? 'active' : 'hidden');
    }

    admin_redirect('/admin/live-rooms.php' . ($search !== '' ? '?search=' . urlencode($search) : ''));
}

$rooms = $liveService->adminListRooms($search);

admin_render_header('إدارة اللايف', 'live-rooms');
?>
<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بعنوان اللايف أو المضيف أو الـ ID">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>العنوان</th>
                <th>المضيف</th>
                <th>المشاهدون</th>
                <th>الداعمون</th>
                <th>قائمة الظهور</th>
                <th>المشاهدون المسجلون</th>
                <th>التعليقات</th>
                <th>الحالة</th>
                <th>إجراءات</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($rooms as $room): ?>
            <tr>
                <td>#<?= (int) $room['id'] ?></td>
                <td><a href="/admin/live-room.php?id=<?= (int) $room['id'] ?>"><?= htmlspecialchars((string) $room['title']) ?></a></td>
                <td><?= htmlspecialchars((string) $room['host_name']) ?></td>
                <td><?= (int) $room['viewer_count'] ?></td>
                <td><?= (int) $room['coin_count'] ?></td>
                <td><?= htmlspecialchars((string) $room['listing_scope']) ?></td>
                <td><?= (int) $room['viewers_count'] ?></td>
                <td><?= (int) $room['comments_count'] ?></td>
                <td>
                    <span class="pill <?= $room['status'] === 'active' ? 'pill-success' : 'pill-danger' ?>">
                        <?= $room['status'] === 'active' ? 'نشط' : 'مخفي' ?>
                    </span>
                </td>
                <td>
                    <div class="inline-actions">
                        <a class="btn btn-primary" href="/admin/live-room.php?id=<?= (int) $room['id'] ?>">إدارة</a>
                        <form method="post">
                            <input type="hidden" name="room_id" value="<?= (int) $room['id'] ?>">
                            <input type="hidden" name="action" value="<?= $room['status'] === 'active' ? 'hide' : 'activate' ?>">
                            <button class="btn btn-secondary" type="submit">
                                <?= $room['status'] === 'active' ? 'إخفاء' : 'تفعيل' ?>
                            </button>
                        </form>
                    </div>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
