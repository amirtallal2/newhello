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
        $agencyService->adminUpdateAgencyStatus(
            (int) ($_POST['agency_id'] ?? 0),
            (string) ($_POST['status'] ?? 'active')
        );
        $flash = 'تم تحديث حالة الوكالة.';
    } catch (Throwable $throwable) {
        $error = $throwable->getMessage();
    }
}

$search = trim((string) ($_GET['search'] ?? ''));
$status = trim((string) ($_GET['status'] ?? 'all'));
$agencies = $agencyService->adminListAgencies($search, $status);

admin_render_header('إدارة الوكالات', 'agencies');
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
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم الوكالة أو كود الدعوة أو المالك">
        <select name="status">
            <option value="all" <?= $status === 'all' ? 'selected' : '' ?>>الكل</option>
            <option value="active" <?= $status === 'active' ? 'selected' : '' ?>>نشطة</option>
            <option value="hidden" <?= $status === 'hidden' ? 'selected' : '' ?>>مخفية</option>
            <option value="suspended" <?= $status === 'suspended' ? 'selected' : '' ?>>موقوفة</option>
        </select>
        <button type="submit" class="btn btn-primary">تصفية</button>
    </form>
</section>

<section class="panel">
    <div class="panel-title">قائمة الوكالات</div>
    <table class="data-table">
        <thead>
        <tr>
            <th>#</th>
            <th>اسم الوكالة</th>
            <th>المالك</th>
            <th>كود الدعوة</th>
            <th>الدولة</th>
            <th>الهاتف</th>
            <th>الأعضاء</th>
            <th>الحالة</th>
            <th>إجراء</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($agencies as $agency): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="agency_id" value="<?= (int) $agency['id'] ?>">
                    <td>#<?= (int) $agency['id'] ?></td>
                    <td><?= htmlspecialchars((string) $agency['name']) ?></td>
                    <td><?= htmlspecialchars((string) ($agency['owner_name'] ?? 'غير محدد')) ?></td>
                    <td><code><?= htmlspecialchars((string) $agency['invitation_code']) ?></code></td>
                    <td><?= htmlspecialchars((string) $agency['country']) ?></td>
                    <td><?= htmlspecialchars((string) $agency['phone']) ?></td>
                    <td><?= (int) $agency['member_count'] ?></td>
                    <td>
                        <select name="status">
                            <option value="active" <?= $agency['status'] === 'active' ? 'selected' : '' ?>>نشطة</option>
                            <option value="hidden" <?= $agency['status'] === 'hidden' ? 'selected' : '' ?>>مخفية</option>
                            <option value="suspended" <?= $agency['status'] === 'suspended' ? 'selected' : '' ?>>موقوفة</option>
                        </select>
                    </td>
                    <td><button type="submit" class="btn btn-secondary">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
