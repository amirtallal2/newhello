<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/SupportService.php';

admin_require_auth();
$pdo = admin_pdo();
$supportService = new SupportService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? 'update');

        if ($action === 'create') {
            $supportService->createShippingAgencyAdmin(
                trim((string) ($_POST['name'] ?? '')),
                trim((string) ($_POST['handle'] ?? '')),
                (int) ($_POST['diamond_balance'] ?? 0),
                trim((string) ($_POST['supported_country_codes'] ?? '')),
                (string) ($_POST['status'] ?? 'active')
            );
            $flash = 'تم إنشاء وكالة الشحن.';
        } else {
            $supportService->updateShippingAgencyAdmin(
                (int) ($_POST['agency_id'] ?? 0),
                trim((string) ($_POST['name'] ?? '')),
                trim((string) ($_POST['handle'] ?? '')),
                (int) ($_POST['diamond_balance'] ?? 0),
                trim((string) ($_POST['supported_country_codes'] ?? '')),
                (string) ($_POST['status'] ?? 'active')
            );
            $flash = 'تم تحديث وكالة الشحن.';
        }
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$agencies = $supportService->adminListShippingAgencies($search);

admin_render_header('وكالات الشحن', 'shipping-agencies');
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
    <div class="panel-title">إضافة وكالة جديدة</div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="create">
        <label>
            الاسم
            <input type="text" name="name" required>
        </label>
        <label>
            المعرف
            <input type="text" name="handle" placeholder="@ agency" required>
        </label>
        <label>
            رصيد الماس
            <input type="number" min="0" name="diamond_balance" value="0" required>
        </label>
        <label>
            الدول المدعومة
            <input type="text" name="supported_country_codes" placeholder="ae, az, at" required>
        </label>
        <label>
            الحالة
            <select name="status">
                <option value="active">نشطة</option>
                <option value="hidden">مخفية</option>
            </select>
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">إضافة</button>
        </div>
    </form>
</section>

<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم الوكالة أو المعرف">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>الاسم</th>
            <th>المعرف</th>
            <th>الرصيد</th>
            <th>الدول</th>
            <th>الحالة</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($agencies as $agency): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="agency_id" value="<?= (int) $agency['id'] ?>">
                    <td>#<?= (int) $agency['id'] ?></td>
                    <td><input type="text" name="name" value="<?= htmlspecialchars((string) $agency['name']) ?>"></td>
                    <td><input type="text" name="handle" value="<?= htmlspecialchars((string) $agency['handle']) ?>"></td>
                    <td><input type="number" min="0" name="diamond_balance" value="<?= (int) $agency['diamond_balance'] ?>"></td>
                    <td><input type="text" name="supported_country_codes" value="<?= htmlspecialchars(implode(', ', json_decode((string) $agency['supported_country_codes'], true) ?: [])) ?>"></td>
                    <td>
                        <select name="status">
                            <option value="active" <?= $agency['status'] === 'active' ? 'selected' : '' ?>>نشطة</option>
                            <option value="hidden" <?= $agency['status'] === 'hidden' ? 'selected' : '' ?>>مخفية</option>
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
