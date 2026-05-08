<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/AgencyService.php';

$admin = admin_require_auth();
$pdo = admin_pdo();
$agencyService = new AgencyService($pdo);
$flash = null;
$error = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $agencyService->adminUpdateJoinRequestStatus(
            (int) ($_POST['request_id'] ?? 0),
            (string) ($_POST['status'] ?? 'reviewed'),
            (string) ($_POST['admin_note'] ?? '')
        );
        $flash = 'تم تحديث طلب الانضمام.';
    } catch (Throwable $throwable) {
        $error = $throwable->getMessage();
    }
}

$search = trim((string) ($_GET['search'] ?? ''));
$status = trim((string) ($_GET['status'] ?? 'all'));
$requests = $agencyService->adminListJoinRequests($search, $status);

admin_render_header('طلبات الانضمام للوكالة', 'agency-join-requests');
?>
<?php if ($flash !== null): ?>
    <div class="flash success"><?= htmlspecialchars($flash) ?></div>
<?php endif; ?>
<?php if ($error !== null): ?>
    <div class="flash error"><?= htmlspecialchars($error) ?></div>
<?php endif; ?>

<section class="panel">
    <div class="panel-title">البحث والتصفية</div>
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث برقم الطلب أو كود الدعوة أو اسم الوكالة">
        <select name="status">
            <option value="all" <?= $status === 'all' ? 'selected' : '' ?>>الكل</option>
            <option value="new" <?= $status === 'new' ? 'selected' : '' ?>>جديد</option>
            <option value="reviewed" <?= $status === 'reviewed' ? 'selected' : '' ?>>قيد المراجعة</option>
            <option value="approved" <?= $status === 'approved' ? 'selected' : '' ?>>مقبول</option>
            <option value="rejected" <?= $status === 'rejected' ? 'selected' : '' ?>>مرفوض</option>
        </select>
        <button type="submit" class="btn btn-primary">تصفية</button>
    </form>
</section>

<section class="panel">
    <div class="panel-title">طلبات الانضمام</div>
    <table class="data-table">
        <thead>
        <tr>
            <th>الطلب</th>
            <th>المستخدم</th>
            <th>الوكالة</th>
            <th>كود الدعوة</th>
            <th>النوع</th>
            <th>الحالة</th>
            <th>ملاحظة الأدمن</th>
            <th>إجراء</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($requests as $request): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="request_id" value="<?= (int) $request['id'] ?>">
                    <td><?= htmlspecialchars((string) $request['request_code']) ?></td>
                    <td><?= htmlspecialchars((string) ($request['requester_name'] ?? 'غير محدد')) ?></td>
                    <td><?= htmlspecialchars((string) ($request['agency_name_current'] ?? $request['agency_name_snapshot'] ?? 'غير محدد')) ?></td>
                    <td><code><?= htmlspecialchars((string) $request['invitation_code']) ?></code></td>
                    <td><?= htmlspecialchars((string) $request['agency_type']) ?></td>
                    <td>
                        <select name="status">
                            <option value="new" <?= $request['status'] === 'new' ? 'selected' : '' ?>>جديد</option>
                            <option value="reviewed" <?= $request['status'] === 'reviewed' ? 'selected' : '' ?>>قيد المراجعة</option>
                            <option value="approved" <?= $request['status'] === 'approved' ? 'selected' : '' ?>>مقبول</option>
                            <option value="rejected" <?= $request['status'] === 'rejected' ? 'selected' : '' ?>>مرفوض</option>
                        </select>
                    </td>
                    <td><input type="text" name="admin_note" value="<?= htmlspecialchars((string) ($request['admin_note'] ?? '')) ?>" placeholder="ملاحظة"></td>
                    <td><button type="submit" class="btn btn-secondary">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
