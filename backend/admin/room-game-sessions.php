<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/RoomGameService.php';

admin_require_auth();
$pdo = admin_pdo();
$roomGameService = new RoomGameService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$status = (string) ($_GET['status'] ?? 'all');
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $roomGameService->adminCloseSession((int) ($_POST['session_id'] ?? 0));
        $flash = 'تم إنهاء جلسة اللعبة.';
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$sessions = $roomGameService->adminListSessions($search, $status);

admin_render_header('جلسات ألعاب الغرف', 'room-game-sessions');
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
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بالغرفة أو المضيف أو اللعبة">
        <select name="status">
            <option value="all" <?= $status === 'all' ? 'selected' : '' ?>>كل الحالات</option>
            <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>نشطة</option>
            <option value="closed" <?= $status === 'closed' ? 'selected' : '' ?>>منتهية</option>
        </select>
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>الغرفة</th>
            <th>اللعبة</th>
            <th>المضيف</th>
            <th>اللاعبون</th>
            <th>الحالة</th>
            <th>التاريخ</th>
            <th>إجراء</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($sessions as $session): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="session_id" value="<?= (int) $session['id'] ?>">
                    <td>#<?= (int) $session['id'] ?></td>
                    <td><?= htmlspecialchars((string) $session['room_title']) ?></td>
                    <td>
                        <div><?= htmlspecialchars((string) $session['game_name']) ?></div>
                        <div class="muted-copy"><?= htmlspecialchars((string) $session['icon_asset']) ?></div>
                    </td>
                    <td><?= htmlspecialchars((string) $session['host_name']) ?></td>
                    <td><?= (int) $session['player_count'] ?> / <?= (int) $session['max_players'] ?></td>
                    <td><?= htmlspecialchars((string) $session['status']) ?></td>
                    <td><?= htmlspecialchars((string) $session['created_at']) ?></td>
                    <td>
                        <?php if ((string) $session['status'] === 'active'): ?>
                            <button class="btn btn-primary" type="submit">إنهاء</button>
                        <?php else: ?>
                            <span class="muted-copy">لا يوجد</span>
                        <?php endif; ?>
                    </td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
