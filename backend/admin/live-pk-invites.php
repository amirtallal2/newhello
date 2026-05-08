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
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $liveService->adminUpdatePkInviteStatus(
            (int) ($_POST['invite_id'] ?? 0),
            (string) ($_POST['next_status'] ?? 'sent')
        );
        admin_redirect('/admin/live-pk-invites.php?search=' . urlencode($search) . '&status=' . urlencode($status));
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$invites = $liveService->adminListPkInvites($search, $status);

admin_render_header('دعوات PK', 'live-pk-invites');
?>
<?php if ($error !== null): ?>
    <section class="panel"><div class="pill pill-danger"><?= htmlspecialchars($error) ?></div></section>
<?php endif; ?>
<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث بالغرفة أو المرسل أو المستلم">
        <select name="status">
            <?php foreach (['all' => 'الكل', 'sent' => 'مرسلة', 'accepted' => 'مقبولة', 'rejected' => 'مرفوضة', 'ended' => 'منتهية'] as $value => $label): ?>
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
                <th>المرسل</th>
                <th>المستلم</th>
                <th>الحالة</th>
                <th>التاريخ</th>
                <th>إجراء</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($invites as $invite): ?>
            <tr>
                <td>#<?= (int) $invite['id'] ?></td>
                <td><?= htmlspecialchars((string) $invite['room_title']) ?></td>
                <td><?= htmlspecialchars((string) $invite['sender_name']) ?></td>
                <td><?= htmlspecialchars((string) $invite['recipient_name_snapshot']) ?></td>
                <td><?= htmlspecialchars((string) $invite['status']) ?></td>
                <td><?= htmlspecialchars((string) $invite['created_at']) ?></td>
                <td>
                    <form method="post">
                        <input type="hidden" name="invite_id" value="<?= (int) $invite['id'] ?>">
                        <select name="next_status">
                            <?php foreach (['sent', 'accepted', 'rejected', 'ended'] as $nextStatus): ?>
                                <option value="<?= $nextStatus ?>" <?= $invite['status'] === $nextStatus ? 'selected' : '' ?>><?= $nextStatus ?></option>
                            <?php endforeach; ?>
                        </select>
                        <button class="btn btn-secondary" type="submit">تحديث</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
