<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/PostService.php';

admin_require_auth();
$pdo = admin_pdo();
$postService = new PostService($pdo);
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $postService->adminSaveReportReason(
            (int) ($_POST['reason_id'] ?? 0),
            trim((string) ($_POST['label'] ?? '')),
            trim((string) ($_POST['description'] ?? '')),
            (int) ($_POST['display_order'] ?? 0),
            (string) ($_POST['status'] ?? 'active')
        );
        $flash = 'تم حفظ سبب البلاغ.';
    }
} catch (Throwable $exception) {
    $error = $exception->getMessage();
}

$reasons = $postService->adminListReportReasons();

admin_render_header('أسباب بلاغات البوست', 'post-report-reasons');
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
    <h2>إضافة سبب جديد</h2>
    <form method="post" class="form-grid">
        <input type="hidden" name="reason_id" value="0">
        <label>
            عنوان السبب
            <input type="text" name="label" placeholder="مثال: محتوى غير لائق" required>
        </label>
        <label>
            الوصف
            <input type="text" name="description" placeholder="وصف قصير يظهر للإدارة">
        </label>
        <label>
            الترتيب
            <input type="number" name="display_order" value="<?= count($reasons) + 1 ?>" min="0">
        </label>
        <label>
            الحالة
            <select name="status">
                <option value="active">نشط</option>
                <option value="hidden">مخفي</option>
            </select>
        </label>
        <div class="form-actions">
            <button class="btn btn-primary" type="submit">إضافة السبب</button>
        </div>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>المفتاح</th>
            <th>العنوان</th>
            <th>الوصف</th>
            <th>الترتيب</th>
            <th>الحالة</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($reasons as $reason): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="reason_id" value="<?= (int) $reason['id'] ?>">
                    <td>#<?= (int) $reason['id'] ?></td>
                    <td><code><?= htmlspecialchars((string) $reason['reason_key']) ?></code></td>
                    <td>
                        <input type="text" name="label" value="<?= htmlspecialchars((string) $reason['label']) ?>" required>
                    </td>
                    <td>
                        <input type="text" name="description" value="<?= htmlspecialchars((string) ($reason['description'] ?? '')) ?>">
                    </td>
                    <td>
                        <input type="number" name="display_order" value="<?= (int) $reason['display_order'] ?>" min="0">
                    </td>
                    <td>
                        <select name="status">
                            <option value="active" <?= $reason['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                            <option value="hidden" <?= $reason['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
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
