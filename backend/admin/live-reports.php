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
        $liveService->adminUpdateReportStatus(
            (int) ($_POST['report_id'] ?? 0),
            (string) ($_POST['next_status'] ?? 'reviewed')
        );
        admin_redirect('/admin/live-reports.php?search=' . urlencode($search) . '&status=' . urlencode($status));
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$reports = $liveService->adminListReports($search, $status);

admin_render_header('بلاغات اللايف', 'live-reports');
?>
<?php if ($error !== null): ?>
    <section class="panel"><div class="pill pill-danger"><?= htmlspecialchars($error) ?></div></section>
<?php endif; ?>
<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم المبلغ أو الغرفة أو السبب">
        <select name="status">
            <?php foreach (['all' => 'الكل', 'new' => 'جديد', 'reviewed' => 'قيد المراجعة', 'resolved' => 'تم الحل', 'rejected' => 'مرفوض'] as $value => $label): ?>
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
                <th>المبلغ</th>
                <th>السبب</th>
                <th>الحالة</th>
                <th>التاريخ</th>
                <th>إجراء</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($reports as $report): ?>
            <tr>
                <td>#<?= (int) $report['id'] ?></td>
                <td><?= htmlspecialchars((string) $report['room_title']) ?></td>
                <td><?= htmlspecialchars((string) $report['reporter_name']) ?></td>
                <td><?= htmlspecialchars((string) $report['reason_text']) ?></td>
                <td><?= htmlspecialchars((string) $report['status']) ?></td>
                <td><?= htmlspecialchars((string) $report['created_at']) ?></td>
                <td>
                    <form method="post">
                        <input type="hidden" name="report_id" value="<?= (int) $report['id'] ?>">
                        <select name="next_status">
                            <?php foreach (['reviewed', 'resolved', 'rejected'] as $nextStatus): ?>
                                <option value="<?= $nextStatus ?>"><?= $nextStatus ?></option>
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
