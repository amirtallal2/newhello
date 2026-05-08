<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/LiveService.php';

admin_require_auth();
$pdo = admin_pdo();
$liveService = new LiveService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$status = (string) ($_GET['status'] ?? 'all');
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? 'create');
        if ($action === 'update') {
            $liveService->updateNotificationAdmin(
                (int) ($_POST['notification_id'] ?? 0),
                (int) ($_POST['room_id'] ?? 0),
                trim((string) ($_POST['title_text'] ?? '')),
                trim((string) ($_POST['body_text'] ?? '')),
                (string) ($_POST['row_status'] ?? 'active'),
                (int) ($_POST['display_order'] ?? 0)
            );
            $flash = 'تم تحديث الإشعار.';
        } else {
            $liveService->createNotificationAdmin(
                (int) ($_POST['room_id'] ?? 0),
                trim((string) ($_POST['title_text'] ?? '')),
                trim((string) ($_POST['body_text'] ?? '')),
                (string) ($_POST['status'] ?? 'active'),
                (int) ($_POST['display_order'] ?? 0)
            );
            $flash = 'تم إنشاء الإشعار.';
        }
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$notifications = $liveService->adminListNotifications($search, $status);
$rooms = $liveService->adminListRooms();

admin_render_header('إشعارات اللايف', 'live-notifications');
?>
<?php if ($flash !== null): ?>
    <section class="panel"><div class="pill pill-success"><?= htmlspecialchars($flash) ?></div></section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel"><div class="pill pill-danger"><?= htmlspecialchars($error) ?></div></section>
<?php endif; ?>

<section class="panel">
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="create">
        <label>
            <span>الغرفة</span>
            <select name="room_id">
                <?php foreach ($rooms as $room): ?>
                    <option value="<?= (int) $room['id'] ?>"><?= htmlspecialchars((string) $room['title']) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>العنوان</span>
            <input type="text" name="title_text" required>
        </label>
        <label>
            <span>الحالة</span>
            <select name="status">
                <option value="active">نشط</option>
                <option value="hidden">مخفي</option>
            </select>
        </label>
        <label>
            <span>الترتيب</span>
            <input type="number" name="display_order" value="0" min="0">
        </label>
        <label class="label-full">
            <span>المحتوى</span>
            <textarea name="body_text" rows="3" required></textarea>
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">إضافة إشعار</button>
        </div>
    </form>
</section>

<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بعنوان الإشعار أو الغرفة">
        <select name="status">
            <?php foreach (['all' => 'الكل', 'active' => 'نشط', 'hidden' => 'مخفي'] as $value => $label): ?>
                <option value="<?= $value ?>" <?= $status === $value ? 'selected' : '' ?>><?= $label ?></option>
            <?php endforeach; ?>
        </select>
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>الغرفة</th>
                <th>العنوان</th>
                <th>المحتوى</th>
                <th>الترتيب</th>
                <th>الحالة</th>
                <th>حفظ</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($notifications as $notification): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="notification_id" value="<?= (int) $notification['id'] ?>">
                    <td>#<?= (int) $notification['id'] ?></td>
                    <td>
                        <select name="room_id">
                            <?php foreach ($rooms as $room): ?>
                                <option value="<?= (int) $room['id'] ?>" <?= (int) $notification['room_id'] === (int) $room['id'] ? 'selected' : '' ?>>
                                    <?= htmlspecialchars((string) $room['title']) ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                    </td>
                    <td><input type="text" name="title_text" value="<?= htmlspecialchars((string) $notification['title_text']) ?>"></td>
                    <td><textarea name="body_text" rows="2"><?= htmlspecialchars((string) $notification['body_text']) ?></textarea></td>
                    <td><input type="number" name="display_order" value="<?= (int) $notification['display_order'] ?>" min="0"></td>
                    <td>
                        <select name="row_status">
                            <option value="active" <?= $notification['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                            <option value="hidden" <?= $notification['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
                        </select>
                    </td>
                    <td><button class="btn btn-secondary" type="submit">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
