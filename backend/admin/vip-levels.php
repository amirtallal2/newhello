<?php

declare(strict_types=1);

require_once __DIR__ . '/common.php';

admin_require_auth();
$pdo = admin_pdo();
$levelService = new LevelService($pdo);
$flash = null;
$error = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $action = (string) ($_POST['action'] ?? '');

        if ($action === 'save_level') {
            $levelService->adminSaveVipLevel(
                (int) ($_POST['level_id'] ?? 0),
                (int) ($_POST['tier_number'] ?? 1),
                (string) ($_POST['name'] ?? ''),
                (string) ($_POST['subtitle'] ?? ''),
                (string) ($_POST['description'] ?? ''),
                (int) ($_POST['price_coins'] ?? 0),
                (int) ($_POST['duration_days'] ?? 30),
                (string) ($_POST['hero_asset_path'] ?? ''),
                (string) ($_POST['badge_asset_path'] ?? ''),
                (string) ($_POST['status'] ?? 'active'),
                (int) ($_POST['display_order'] ?? 0)
            );
            $flash = 'تم حفظ مستوى VIP.';
        }

        if ($action === 'save_privilege') {
            $levelService->adminSavePrivilege(
                (int) ($_POST['privilege_id'] ?? 0),
                (int) ($_POST['unlock_tier'] ?? 1),
                (string) ($_POST['title'] ?? ''),
                (string) ($_POST['description'] ?? ''),
                (string) ($_POST['icon_asset_path'] ?? ''),
                (string) ($_POST['status'] ?? 'active'),
                (int) ($_POST['display_order'] ?? 0)
            );
            $flash = 'تم حفظ ميزة VIP.';
        }
    } catch (Throwable $throwable) {
        $error = $throwable->getMessage();
    }
}

$levels = $levelService->adminListVipLevels();
$privileges = $levelService->adminListPrivileges();
$statusOptions = ['active' => 'نشط', 'hidden' => 'مخفي'];

admin_render_header('مستويات VIP', 'vip-levels');
?>
<?php if ($flash !== null): ?>
    <section class="panel"><div class="pill pill-success"><?= htmlspecialchars($flash) ?></div></section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel"><div class="pill pill-danger"><?= htmlspecialchars($error) ?></div></section>
<?php endif; ?>

<section class="panel">
    <div class="panel-title">إضافة مستوى جديد</div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="save_level">
        <input type="hidden" name="level_id" value="0">
        <label>
            رقم المستوى
            <input type="number" min="1" name="tier_number" value="1">
        </label>
        <label>
            الاسم
            <input type="text" name="name" value="VIP 1" required>
        </label>
        <label>
            العنوان الفرعي
            <input type="text" name="subtitle" placeholder="مثال: القمة الذهبية">
        </label>
        <label>
            السعر بالكوينز
            <input type="number" min="0" name="price_coins" value="499999">
        </label>
        <label>
            المدة بالأيام
            <input type="number" min="1" name="duration_days" value="30">
        </label>
        <label>
            ترتيب العرض
            <input type="number" min="0" name="display_order" value="1">
        </label>
        <label class="span-2">
            وصف المستوى
            <textarea name="description" rows="3"></textarea>
        </label>
        <label>
            صورة البطل
            <input type="text" name="hero_asset_path" placeholder="assets/... أو https://...">
        </label>
        <label>
            شارة المستوى
            <input type="text" name="badge_asset_path" placeholder="assets/... أو https://...">
        </label>
        <label>
            الحالة
            <select name="status">
                <?php foreach ($statusOptions as $value => $label): ?>
                    <option value="<?= htmlspecialchars($value) ?>"><?= htmlspecialchars($label) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <div class="action-row">
            <button type="submit" class="btn btn-primary">إضافة مستوى</button>
        </div>
    </form>
</section>

<section class="panel table-panel">
    <div class="panel-title">التحكم في مستويات VIP</div>
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>المستوى</th>
            <th>المحتوى</th>
            <th>الصورة</th>
            <th>السعر/المدة</th>
            <th>الحالة</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($levels as $level): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="action" value="save_level">
                    <input type="hidden" name="level_id" value="<?= (int) $level['id'] ?>">
                    <td>#<?= (int) $level['id'] ?></td>
                    <td>
                        <input type="number" min="1" name="tier_number" value="<?= (int) $level['tier_number'] ?>">
                        <input type="number" min="0" name="display_order" value="<?= (int) $level['display_order'] ?>" placeholder="الترتيب">
                    </td>
                    <td>
                        <div class="media-stack">
                            <input type="text" name="name" value="<?= htmlspecialchars((string) $level['name']) ?>">
                            <input type="text" name="subtitle" value="<?= htmlspecialchars((string) ($level['subtitle'] ?? '')) ?>" placeholder="العنوان الفرعي">
                            <textarea name="description" rows="3" placeholder="الوصف"><?= htmlspecialchars((string) ($level['description'] ?? '')) ?></textarea>
                        </div>
                    </td>
                    <td>
                        <div class="media-stack">
                            <div class="media-inline">
                                <?= admin_render_media_preview((string) ($level['hero_asset_path'] ?? ''), (string) $level['name']) ?>
                                <?= admin_render_media_preview((string) ($level['badge_asset_path'] ?? ''), 'badge') ?>
                            </div>
                            <input type="text" name="hero_asset_path" value="<?= htmlspecialchars((string) ($level['hero_asset_path'] ?? '')) ?>" placeholder="Hero asset">
                            <input type="text" name="badge_asset_path" value="<?= htmlspecialchars((string) ($level['badge_asset_path'] ?? '')) ?>" placeholder="Badge asset">
                        </div>
                    </td>
                    <td>
                        <input type="number" min="0" name="price_coins" value="<?= (int) $level['price_coins'] ?>">
                        <input type="number" min="1" name="duration_days" value="<?= (int) $level['duration_days'] ?>">
                    </td>
                    <td>
                        <select name="status">
                            <?php foreach ($statusOptions as $value => $label): ?>
                                <option value="<?= htmlspecialchars($value) ?>" <?= (string) $level['status'] === $value ? 'selected' : '' ?>><?= htmlspecialchars($label) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </td>
                    <td><button type="submit" class="btn btn-primary">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="panel">
    <div class="panel-title">إضافة ميزة جديدة</div>
    <form method="post" class="form-grid">
        <input type="hidden" name="action" value="save_privilege">
        <input type="hidden" name="privilege_id" value="0">
        <label>
            تفتح من VIP
            <input type="number" min="1" name="unlock_tier" value="1">
        </label>
        <label>
            اسم الميزة
            <input type="text" name="title" required>
        </label>
        <label>
            الأيقونة
            <input type="text" name="icon_asset_path" placeholder="assets/... أو https://...">
        </label>
        <label>
            ترتيب العرض
            <input type="number" min="0" name="display_order" value="1">
        </label>
        <label>
            الحالة
            <select name="status">
                <?php foreach ($statusOptions as $value => $label): ?>
                    <option value="<?= htmlspecialchars($value) ?>"><?= htmlspecialchars($label) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label class="span-2">
            الوصف
            <textarea name="description" rows="3"></textarea>
        </label>
        <div class="action-row">
            <button type="submit" class="btn btn-primary">إضافة ميزة</button>
        </div>
    </form>
</section>

<section class="panel table-panel">
    <div class="panel-title">كل مميزات VIP</div>
    <table class="table">
        <thead>
        <tr>
            <th>ID</th>
            <th>تفتح من</th>
            <th>الميزة</th>
            <th>الصورة</th>
            <th>الحالة</th>
            <th>حفظ</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($privileges as $privilege): ?>
            <tr>
                <form method="post">
                    <input type="hidden" name="action" value="save_privilege">
                    <input type="hidden" name="privilege_id" value="<?= (int) $privilege['id'] ?>">
                    <td>#<?= (int) $privilege['id'] ?></td>
                    <td>
                        <input type="number" min="1" name="unlock_tier" value="<?= (int) $privilege['unlock_tier'] ?>">
                        <input type="number" min="0" name="display_order" value="<?= (int) $privilege['display_order'] ?>" placeholder="الترتيب">
                    </td>
                    <td>
                        <div class="media-stack">
                            <input type="text" name="title" value="<?= htmlspecialchars((string) $privilege['title']) ?>">
                            <textarea name="description" rows="2"><?= htmlspecialchars((string) ($privilege['description'] ?? '')) ?></textarea>
                        </div>
                    </td>
                    <td>
                        <div class="media-stack">
                            <?= admin_render_media_preview((string) ($privilege['icon_asset_path'] ?? ''), (string) $privilege['title']) ?>
                            <input type="text" name="icon_asset_path" value="<?= htmlspecialchars((string) ($privilege['icon_asset_path'] ?? '')) ?>">
                        </div>
                    </td>
                    <td>
                        <select name="status">
                            <?php foreach ($statusOptions as $value => $label): ?>
                                <option value="<?= htmlspecialchars($value) ?>" <?= (string) $privilege['status'] === $value ? 'selected' : '' ?>><?= htmlspecialchars($label) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </td>
                    <td><button type="submit" class="btn btn-primary">حفظ</button></td>
                </form>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<?php admin_render_footer(); ?>
