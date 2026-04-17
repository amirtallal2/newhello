<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/RoomMusicService.php';

admin_require_auth();
$pdo = admin_pdo();
$roomMusicService = new RoomMusicService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $roomMusicService->updateTrackAdmin(
            (int) ($_POST['track_id'] ?? 0),
            trim((string) ($_POST['title'] ?? '')),
            trim((string) ($_POST['artist_name'] ?? '')),
            (string) ($_POST['source_type'] ?? ''),
            (int) ($_POST['duration_seconds'] ?? 0),
            (string) ($_POST['status'] ?? 'active')
        );
        $flash = 'تم تحديث المسار الموسيقي.';
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$tracks = $roomMusicService->adminListTracks($search);

admin_render_header('إدارة الموسيقى', 'music-tracks');
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
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بعنوان المقطع أو الفنان أو المصدر">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>العنوان</th>
                <th>الفنان</th>
                <th>المصدر</th>
                <th>المدة</th>
                <th>الحالة</th>
                <th>حفظ</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($tracks as $track): ?>
            <tr>
                <form method="post">
                    <td>#<?= (int) $track['id'] ?><input type="hidden" name="track_id" value="<?= (int) $track['id'] ?>"></td>
                    <td><input type="text" name="title" value="<?= htmlspecialchars((string) $track['title']) ?>"></td>
                    <td><input type="text" name="artist_name" value="<?= htmlspecialchars((string) $track['artist_name']) ?>"></td>
                    <td>
                        <select name="source_type">
                            <option value="friends" <?= $track['source_type'] === 'friends' ? 'selected' : '' ?>>الاصدقاء</option>
                            <option value="whatsapp" <?= $track['source_type'] === 'whatsapp' ? 'selected' : '' ?>>واتساب</option>
                        </select>
                    </td>
                    <td><input type="number" min="10" name="duration_seconds" value="<?= (int) $track['duration_seconds'] ?>"></td>
                    <td>
                        <select name="status">
                            <option value="active" <?= $track['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                            <option value="hidden" <?= $track['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
                        </select>
                    </td>
                    <td><button class="btn btn-primary" type="submit">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
