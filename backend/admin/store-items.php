<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';
require_once __DIR__ . '/../src/ApiException.php';

admin_require_auth();
$pdo = admin_pdo();
$economyService = new EconomyService($pdo);
$categoryKey = trim((string) ($_GET['category'] ?? ''));
$search = trim((string) ($_GET['search'] ?? ''));
$flash = null;
$error = null;

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $action = (string) ($_POST['action'] ?? 'update');

        if ($action === 'create') {
            $economyService->createStoreItemAdmin(
                (string) ($_POST['category_key'] ?? 'frames'),
                trim((string) ($_POST['name'] ?? '')),
                trim((string) ($_POST['preview_asset_path'] ?? '')),
                trim((string) ($_POST['dialog_icon_asset_path'] ?? '')),
                trim((string) ($_POST['dialog_preview_asset_path'] ?? '')),
                (int) ($_POST['price_3_days'] ?? 0),
                (int) ($_POST['price_7_days'] ?? 0),
                (int) ($_POST['price_15_days'] ?? 0),
                (int) ($_POST['price_30_days'] ?? 0),
                trim((string) ($_POST['discount_3_days'] ?? '')),
                trim((string) ($_POST['discount_7_days'] ?? '')),
                trim((string) ($_POST['discount_15_days'] ?? '')),
                trim((string) ($_POST['discount_30_days'] ?? '')),
                (string) ($_POST['status'] ?? 'active')
            );
            $flash = 'تم إنشاء عنصر المتجر.';
        } else {
            $economyService->updateStoreItemAdmin(
                (int) ($_POST['item_id'] ?? 0),
                (string) ($_POST['category_key'] ?? 'frames'),
                trim((string) ($_POST['name'] ?? '')),
                trim((string) ($_POST['preview_asset_path'] ?? '')),
                trim((string) ($_POST['dialog_icon_asset_path'] ?? '')),
                trim((string) ($_POST['dialog_preview_asset_path'] ?? '')),
                (int) ($_POST['price_3_days'] ?? 0),
                (int) ($_POST['price_7_days'] ?? 0),
                (int) ($_POST['price_15_days'] ?? 0),
                (int) ($_POST['price_30_days'] ?? 0),
                trim((string) ($_POST['discount_3_days'] ?? '')),
                trim((string) ($_POST['discount_7_days'] ?? '')),
                trim((string) ($_POST['discount_15_days'] ?? '')),
                trim((string) ($_POST['discount_30_days'] ?? '')),
                (string) ($_POST['status'] ?? 'active')
            );
            $flash = 'تم تحديث عنصر المتجر.';
        }
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$items = $economyService->adminListStoreItems($categoryKey, $search);
$categories = [
    'frames' => 'الاطارات',
    'animated_frames' => 'الاطارات المتحركة',
    'backgrounds' => 'الخلفيات',
    'chat_frames' => 'اطارات المحادثات',
    'entry_effects' => 'الدخلات',
    'aristocracy' => 'استقراطيه',
];

admin_render_header('عناصر المتجر', 'store-items');
?>
<?php if ($flash !== null): ?>
    <section class="panel"><div class="pill pill-success"><?= htmlspecialchars($flash) ?></div></section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel"><div class="pill pill-danger"><?= htmlspecialchars($error) ?></div></section>
<?php endif; ?>

<section class="panel">
    <div class="panel-title">إضافة عنصر جديد</div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="create">
        <label>
            الفئة
            <select name="category_key">
                <?php foreach ($categories as $value => $label): ?>
                    <option value="<?= htmlspecialchars($value) ?>"><?= htmlspecialchars($label) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            الاسم
            <input type="text" name="name" required>
        </label>
        <label>
            ملف المعاينة
            <input type="text" name="preview_asset_path" required>
        </label>
        <label>
            أيقونة الحوار
            <input type="text" name="dialog_icon_asset_path">
        </label>
        <label>
            معاينة الحوار
            <input type="text" name="dialog_preview_asset_path">
        </label>
        <label><span>سعر 3 أيام</span><input type="number" min="0" name="price_3_days" value="90"></label>
        <label><span>سعر 7 أيام</span><input type="number" min="0" name="price_7_days" value="180"></label>
        <label><span>سعر 15 يوم</span><input type="number" min="0" name="price_15_days" value="330"></label>
        <label><span>سعر 30 يوم</span><input type="number" min="0" name="price_30_days" value="540"></label>
        <label><span>خصم 3 أيام</span><input type="text" name="discount_3_days" value="10% Off"></label>
        <label><span>خصم 7 أيام</span><input type="text" name="discount_7_days" value="22% Off"></label>
        <label><span>خصم 15 يوم</span><input type="text" name="discount_15_days" value="27% Off"></label>
        <label><span>خصم 30 يوم</span><input type="text" name="discount_30_days" value="27% Off"></label>
        <label>
            الحالة
            <select name="status">
                <option value="active">نشط</option>
                <option value="hidden">مخفي</option>
            </select>
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">إضافة</button>
        </div>
    </form>
</section>

<section class="panel">
    <form method="get" class="toolbar">
        <select name="category">
            <option value="">كل الفئات</option>
            <?php foreach ($categories as $value => $label): ?>
                <option value="<?= htmlspecialchars($value) ?>" <?= $categoryKey === $value ? 'selected' : '' ?>><?= htmlspecialchars($label) ?></option>
            <?php endforeach; ?>
        </select>
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم العنصر">
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>الفئة</th>
            <th>الاسم</th>
            <th>المعاينة</th>
            <th>3/7/15/30</th>
            <th>الخصومات</th>
            <th>الحالة</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($items as $item): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="action" value="update">
                    <input type="hidden" name="item_id" value="<?= (int) $item['id'] ?>">
                    <td>#<?= (int) $item['id'] ?></td>
                    <td>
                        <select name="category_key">
                            <?php foreach ($categories as $value => $label): ?>
                                <option value="<?= htmlspecialchars($value) ?>" <?= $item['category_key'] === $value ? 'selected' : '' ?>><?= htmlspecialchars($label) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </td>
                    <td>
                        <div class="media-stack">
                            <input type="text" name="name" value="<?= htmlspecialchars((string) $item['name']) ?>">
                            <div class="media-inline">
                                <?= admin_render_media_preview((string) $item['preview_asset_path'], (string) $item['name']) ?>
                                <?= admin_render_media_preview((string) ($item['dialog_icon_asset_path'] ?? ''), 'dialog-icon') ?>
                                <?= admin_render_media_preview((string) ($item['dialog_preview_asset_path'] ?? ''), 'dialog-preview') ?>
                            </div>
                            <input type="text" name="preview_asset_path" value="<?= htmlspecialchars((string) $item['preview_asset_path']) ?>" placeholder="Preview asset">
                            <input type="text" name="dialog_icon_asset_path" value="<?= htmlspecialchars((string) ($item['dialog_icon_asset_path'] ?? '')) ?>" placeholder="Dialog icon asset">
                            <input type="text" name="dialog_preview_asset_path" value="<?= htmlspecialchars((string) ($item['dialog_preview_asset_path'] ?? '')) ?>" placeholder="Dialog preview asset">
                        </div>
                    </td>
                    <td>
                        <input type="number" min="0" name="price_3_days" value="<?= (int) $item['price_3_days'] ?>">
                        <input type="number" min="0" name="price_7_days" value="<?= (int) $item['price_7_days'] ?>">
                        <input type="number" min="0" name="price_15_days" value="<?= (int) $item['price_15_days'] ?>">
                        <input type="number" min="0" name="price_30_days" value="<?= (int) $item['price_30_days'] ?>">
                    </td>
                    <td>
                        <input type="text" name="discount_3_days" value="<?= htmlspecialchars((string) $item['discount_3_days']) ?>">
                        <input type="text" name="discount_7_days" value="<?= htmlspecialchars((string) $item['discount_7_days']) ?>">
                        <input type="text" name="discount_15_days" value="<?= htmlspecialchars((string) $item['discount_15_days']) ?>">
                        <input type="text" name="discount_30_days" value="<?= htmlspecialchars((string) $item['discount_30_days']) ?>">
                    </td>
                    <td>
                        <select name="status">
                            <option value="active" <?= $item['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                            <option value="hidden" <?= $item['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
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
