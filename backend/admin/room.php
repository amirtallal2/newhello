<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/RoomMusicService.php';
require_once __DIR__ . '/../src/RoomService.php';

admin_require_auth();
$pdo = admin_pdo();
$roomMusicService = new RoomMusicService($pdo);
$roomService = new RoomService($pdo);
$roomId = (int) ($_GET['id'] ?? 0);
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? '');

        if ($action === 'save_room') {
            $roomService->updateRoomAdmin(
                $roomId,
                trim((string) ($_POST['card_title'] ?? '')),
                trim((string) ($_POST['room_title'] ?? '')),
                trim((string) ($_POST['subtitle'] ?? '')),
                trim((string) ($_POST['host_name'] ?? '')),
                trim((string) ($_POST['room_code'] ?? '')),
                (int) ($_POST['listener_count'] ?? 0),
                (int) ($_POST['mic_count'] ?? 9),
                (string) ($_POST['status'] ?? 'active')
            );
            $flash = 'تم حفظ بيانات الغرفة.';
        }

        if (in_array($action, ['approve_request', 'reject_request'], true)) {
            $requestId = (int) ($_POST['request_id'] ?? 0);
            if ($action === 'approve_request') {
                $roomService->approveSeatRequest($roomId, $requestId);
                $flash = 'تمت الموافقة على طلب المايك.';
            } else {
                $roomService->rejectSeatRequest($roomId, $requestId);
                $flash = 'تم رفض طلب المايك.';
            }
        }

        if ($action === 'remove_music_entry') {
            $roomMusicService->adminRemoveRoomPlaylistEntry(
                $roomId,
                (int) ($_POST['entry_id'] ?? 0)
            );
            $flash = 'تمت إزالة المقطع من قائمة التشغيل.';
        }
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$room = $roomService->getRoom($roomId);
$requests = $roomService->listSeatRequests($roomId);
$playlistEntries = $roomMusicService->adminRoomPlaylist($roomId);

admin_render_header('تفاصيل الغرفة', 'rooms');
?>
<?php if ($flash !== null): ?>
    <section class="panel">
        <div class="pill pill-success"><?= htmlspecialchars($flash) ?></div>
    </section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel">
        <div class="pill pill-danger"><?= htmlspecialchars($error) ?></div>
    </section>
<?php endif; ?>

<section class="panel">
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="save_room">
        <label>
            <span>عنوان الكارت</span>
            <input type="text" name="card_title" value="<?= htmlspecialchars((string) $room['card_title']) ?>" required>
        </label>
        <label>
            <span>عنوان الغرفة</span>
            <input type="text" name="room_title" value="<?= htmlspecialchars((string) $room['room_title']) ?>" required>
        </label>
        <label>
            <span>الوصف</span>
            <input type="text" name="subtitle" value="<?= htmlspecialchars((string) $room['subtitle']) ?>">
        </label>
        <label>
            <span>المضيف</span>
            <input type="text" name="host_name" value="<?= htmlspecialchars((string) $room['host_name']) ?>" required>
        </label>
        <label>
            <span>كود الغرفة</span>
            <input type="text" name="room_code" value="<?= htmlspecialchars((string) $room['room_code']) ?>" required>
        </label>
        <label>
            <span>المستمعون</span>
            <input type="number" name="listener_count" value="<?= (int) $room['listener_count'] ?>" min="0">
        </label>
        <label>
            <span>عدد المايكات</span>
            <select name="mic_count">
                <?php foreach ([5, 9, 12, 15] as $micCount): ?>
                    <option value="<?= $micCount ?>" <?= (int) $room['mic_count'] === $micCount ? 'selected' : '' ?>><?= $micCount ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>الحالة</span>
            <select name="status">
                <option value="active" <?= $room['status'] === 'active' ? 'selected' : '' ?>>نشطة</option>
                <option value="hidden" <?= $room['status'] === 'hidden' ? 'selected' : '' ?>>مخفية</option>
            </select>
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">حفظ الغرفة</button>
            <a class="btn btn-secondary" href="/admin/rooms.php">رجوع</a>
        </div>
    </form>
</section>

<section class="panel table-panel">
    <div class="panel-title">قائمة الموسيقى الحالية</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>العنوان</th>
                <th>الفنان</th>
                <th>المصدر</th>
                <th>المدة</th>
                <th>أضافه</th>
                <th>إزالة</th>
            </tr>
        </thead>
        <tbody>
        <?php if ($playlistEntries === []): ?>
            <tr>
                <td colspan="7">لا توجد موسيقى مضافة لهذه الغرفة.</td>
            </tr>
        <?php else: ?>
            <?php foreach ($playlistEntries as $entry): ?>
                <tr>
                    <td>#<?= (int) $entry['id'] ?></td>
                    <td><?= htmlspecialchars((string) $entry['title']) ?></td>
                    <td><?= htmlspecialchars((string) $entry['artist_name']) ?></td>
                    <td><?= $entry['source_type'] === 'friends' ? 'الاصدقاء' : 'واتساب' ?></td>
                    <td><?= (int) $entry['duration_seconds'] ?> ثانية</td>
                    <td><?= htmlspecialchars((string) $entry['added_by_name']) ?></td>
                    <td>
                        <form method="post">
                            <input type="hidden" name="action" value="remove_music_entry">
                            <input type="hidden" name="entry_id" value="<?= (int) $entry['id'] ?>">
                            <button class="btn btn-secondary" type="submit">إزالة</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <div class="panel-title">طلبات المايك المعلقة</div>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>الاسم</th>
                <th>المقعد</th>
                <th>الوقت</th>
                <th>إجراءات</th>
            </tr>
        </thead>
        <tbody>
        <?php if ($requests === []): ?>
            <tr>
                <td colspan="5">لا توجد طلبات مايك معلقة.</td>
            </tr>
        <?php else: ?>
            <?php foreach ($requests as $request): ?>
                <tr>
                    <td>#<?= (int) $request['id'] ?></td>
                    <td><?= htmlspecialchars((string) $request['requester_name']) ?></td>
                    <td><?= (int) $request['seat_number'] ?></td>
                    <td><?= htmlspecialchars((string) $request['created_at']) ?></td>
                    <td>
                        <div class="inline-actions">
                            <form method="post">
                                <input type="hidden" name="action" value="approve_request">
                                <input type="hidden" name="request_id" value="<?= (int) $request['id'] ?>">
                                <button class="btn btn-primary" type="submit">موافقة</button>
                            </form>
                            <form method="post">
                                <input type="hidden" name="action" value="reject_request">
                                <input type="hidden" name="request_id" value="<?= (int) $request['id'] ?>">
                                <button class="btn btn-secondary" type="submit">رفض</button>
                            </form>
                        </div>
                    </td>
                </tr>
            <?php endforeach; ?>
        <?php endif; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
