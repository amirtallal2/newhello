<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/PostService.php';

admin_require_auth();
$pdo = admin_pdo();
$postService = new PostService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$status = (string) ($_GET['status'] ?? 'all');
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $postService->adminUpdateReportStatus(
            (int) ($_POST['report_id'] ?? 0),
            (string) ($_POST['status'] ?? 'reviewed'),
            isset($_POST['hide_post']),
            (string) ($_POST['report_target'] ?? 'post')
        );
        $flash = 'تم تحديث البلاغ.';
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$reports = $postService->adminListReports($search, $status);

admin_render_header('بلاغات البوست', 'post-reports');
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
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم المبلغ أو السبب أو محتوى البوست">
        <select name="status">
            <option value="all" <?= $status === 'all' ? 'selected' : '' ?>>كل الحالات</option>
            <option value="new" <?= $status === 'new' ? 'selected' : '' ?>>جديد</option>
            <option value="reviewed" <?= $status === 'reviewed' ? 'selected' : '' ?>>قيد المراجعة</option>
            <option value="resolved" <?= $status === 'resolved' ? 'selected' : '' ?>>تم الحل</option>
            <option value="rejected" <?= $status === 'rejected' ? 'selected' : '' ?>>مرفوض</option>
        </select>
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>النوع</th>
            <th>المبلغ</th>
            <th>البوست</th>
            <th>التعليق</th>
            <th>السبب</th>
            <th>حالة البوست</th>
            <th>حالة البلاغ</th>
            <th>إجراء</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($reports as $report): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="report_id" value="<?= (int) $report['id'] ?>">
                    <input type="hidden" name="report_target" value="<?= htmlspecialchars((string) $report['report_target']) ?>">
                    <td>#<?= (int) $report['id'] ?></td>
                    <td><?= $report['report_target'] === 'comment' ? 'تعليق' : 'بوست' ?></td>
                    <td><?= htmlspecialchars((string) $report['reporter_name']) ?></td>
                    <td>
                        <div><strong><?= htmlspecialchars((string) $report['author_name']) ?></strong></div>
                        <div><?= htmlspecialchars(mb_strimwidth((string) $report['body_text'], 0, 110, '...')) ?></div>
                    </td>
                    <td>
                        <?php if ($report['report_target'] === 'comment'): ?>
                            <div><?= htmlspecialchars(mb_strimwidth((string) $report['comment_body'], 0, 110, '...')) ?></div>
                            <div class="muted">الحالة: <?= htmlspecialchars((string) $report['comment_status']) ?></div>
                        <?php else: ?>
                            <span class="muted">-</span>
                        <?php endif; ?>
                    </td>
                    <td><?= htmlspecialchars((string) $report['reason']) ?></td>
                    <td><?= htmlspecialchars((string) $report['post_status']) ?></td>
                    <td>
                        <select name="status">
                            <option value="new" <?= $report['status'] === 'new' ? 'selected' : '' ?>>جديد</option>
                            <option value="reviewed" <?= $report['status'] === 'reviewed' ? 'selected' : '' ?>>قيد المراجعة</option>
                            <option value="resolved" <?= $report['status'] === 'resolved' ? 'selected' : '' ?>>تم الحل</option>
                            <option value="rejected" <?= $report['status'] === 'rejected' ? 'selected' : '' ?>>مرفوض</option>
                        </select>
                    </td>
                    <td>
                        <div class="stack">
                            <label>
                                <input type="checkbox" name="hide_post" value="1">
                                <?= $report['report_target'] === 'comment' ? 'إخفاء التعليق' : 'إخفاء البوست' ?>
                            </label>
                            <button class="btn btn-primary" type="submit">حفظ</button>
                        </div>
                    </td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
