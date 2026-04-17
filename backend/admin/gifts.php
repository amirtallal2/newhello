<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';
require_once __DIR__ . '/../src/GiftService.php';

admin_require_auth();
$pdo = admin_pdo();
$giftService = new GiftService($pdo);
$search = trim((string) ($_GET['search'] ?? ''));
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $giftService->updateGiftAdmin(
            (int) ($_POST['gift_id'] ?? 0),
            trim((string) ($_POST['name'] ?? '')),
            trim((string) ($_POST['category'] ?? '')),
            (int) ($_POST['price_coins'] ?? 0),
            (string) ($_POST['status'] ?? 'active')
        );
        $flash = 'تم تحديث الهدية.';
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$gifts = $giftService->adminListGifts($search);

admin_render_header('إدارة الهدايا', 'gifts');
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
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم الهدية أو الفئة">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
            <tr>
                <th>ID</th>
                <th>الصورة</th>
                <th>الاسم</th>
                <th>الفئة</th>
                <th>السعر</th>
                <th>الحالة</th>
                <th>حفظ</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($gifts as $gift): ?>
            <tr>
                <form method="post">
                    <td>#<?= (int) $gift['id'] ?><input type="hidden" name="gift_id" value="<?= (int) $gift['id'] ?>"></td>
                    <td><?= htmlspecialchars((string) $gift['asset_path']) ?></td>
                    <td><input type="text" name="name" value="<?= htmlspecialchars((string) $gift['name']) ?>"></td>
                    <td><input type="text" name="category" value="<?= htmlspecialchars((string) $gift['category']) ?>"></td>
                    <td><input type="number" min="1" name="price_coins" value="<?= (int) $gift['price_coins'] ?>"></td>
                    <td>
                        <select name="status">
                            <option value="active" <?= $gift['status'] === 'active' ? 'selected' : '' ?>>نشطة</option>
                            <option value="hidden" <?= $gift['status'] === 'hidden' ? 'selected' : '' ?>>مخفية</option>
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
