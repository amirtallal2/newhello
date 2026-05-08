<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/RoomRtcService.php';
require_once __DIR__ . '/../src/RoomService.php';

admin_require_auth();
$pdo = admin_pdo();
$roomRtcService = new RoomRtcService($pdo, $config);
$roomService = new RoomService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $roomId = (int) ($_POST['room_id'] ?? 0);
    $action = (string) ($_POST['action'] ?? '');

    if ($roomId > 0 && in_array($action, ['hide', 'activate'], true)) {
        $statement = $pdo->prepare(
            'UPDATE rooms SET status = :status, updated_at = :updated_at WHERE id = :id'
        );
        $statement->execute([
            'status' => $action === 'activate' ? 'active' : 'hidden',
            'updated_at' => gmdate('Y-m-d H:i:s'),
            'id' => $roomId,
        ]);

        if ($action === 'hide') {
            $roomRtcService->adminCloseRoomAudio($roomId);
        }
    }

    admin_redirect('/admin/rooms.php' . ($search !== '' ? '?search=' . urlencode($search) : ''));
}

$roomRtcService->refreshAudioPresence();
$rooms = $roomService->adminListRooms($search);

admin_render_header('إدارة الغرف الصوتية', 'rooms');
?>
<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم الكارت أو الغرفة أو المضيف">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>الصورة</th>
                <th>الكارت</th>
                <th>عنوان الغرفة</th>
                <th>النوع</th>
                <th>البلد</th>
                <th>المضيف</th>
                <th>المايكات</th>
                <th>المستمعون</th>
                <th>الصوت المباشر</th>
                <th>المتصلون الآن</th>
                <th>طلبات المايك</th>
                <th>الحالة</th>
                <th>إجراءات</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($rooms as $room): ?>
            <tr>
                <td>#<?= (int) $room['id'] ?></td>
                <td><?= admin_render_media_preview((string) ($room['card_image_asset'] ?? ''), (string) ($room['room_title'] ?? 'room')) ?></td>
                <td><a href="/admin/room.php?id=<?= (int) $room['id'] ?>"><?= htmlspecialchars((string) $room['card_title']) ?></a></td>
                <td><?= htmlspecialchars((string) $room['room_title']) ?></td>
                <td><?= htmlspecialchars((string) ($room['room_type'] ?? 'غناء')) ?></td>
                <td><?= htmlspecialchars((string) ($room['country_label'] ?? 'مصر')) ?></td>
                <td><?= htmlspecialchars((string) $room['host_name']) ?></td>
                <td><?= (int) $room['mic_count'] ?></td>
                <td><?= (int) $room['listener_count'] ?></td>
                <td>
                    <span class="pill <?= !empty($room['audio_enabled']) ? 'pill-success' : 'pill-danger' ?>">
                        <?= !empty($room['audio_enabled']) ? 'مفعل' : 'مغلق' ?>
                    </span>
                </td>
                <td><?= (int) ($room['active_audio_participants_count'] ?? 0) ?></td>
                <td><?= (int) $room['pending_requests_count'] ?></td>
                <td>
                    <span class="pill <?= $room['status'] === 'active' ? 'pill-success' : 'pill-danger' ?>">
                        <?= $room['status'] === 'active' ? 'نشطة' : 'مخفية' ?>
                    </span>
                </td>
                <td>
                    <div class="inline-actions">
                        <a class="btn btn-primary" href="/admin/room.php?id=<?= (int) $room['id'] ?>">إدارة</a>
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
