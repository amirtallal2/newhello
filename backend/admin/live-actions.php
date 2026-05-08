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
$flash = null;
$error = null;

$behaviorLabels = [
    'beauty' => 'تجميل Agora',
    'sticker' => 'ملصقات',
    'interface' => 'واجهة',
    'mute' => 'كتم/تشغيل الصوت',
    'notifications' => 'إشعارات الغرفة',
    'welcome_message' => 'رسالة ترحيب',
    'viewers' => 'المشاهدون',
    'room_admin' => 'مسؤول الغرفة',
    'supporters' => 'الداعمون',
    'entry_ranking' => 'ترتيب الدخولية',
    'gift' => 'الهدايا',
    'pk' => 'PK',
    'share' => 'مشاركة',
    'report' => 'إبلاغ',
    'game' => 'لعبة',
    'custom' => 'مخصص',
];

try {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $liveService->saveActionButtonAdmin(
            (int) ($_POST['action_id'] ?? 0),
            (string) ($_POST['section_key'] ?? ''),
            (string) ($_POST['section_title'] ?? ''),
            (int) ($_POST['section_order'] ?? 0),
            (string) ($_POST['action_key'] ?? ''),
            (string) ($_POST['label'] ?? ''),
            (string) ($_POST['icon_kind'] ?? 'custom'),
            (string) ($_POST['icon_asset'] ?? ''),
            (string) ($_POST['behavior'] ?? 'custom'),
            (string) ($_POST['detail_title'] ?? ''),
            (string) ($_POST['detail_body'] ?? ''),
            isset($_POST['requires_host']),
            (string) ($_POST['row_status'] ?? $_POST['status'] ?? 'active'),
            (int) ($_POST['display_order'] ?? 0)
        );
        $flash = ((int) ($_POST['action_id'] ?? 0)) > 0 ? 'تم حفظ الزر.' : 'تم إضافة الزر.';
    }
} catch (ApiException $exception) {
    $error = $exception->getMessage();
}

$actions = $liveService->adminListActionButtons($search, $status);
$events = $liveService->adminListActionEvents($search);

admin_render_header('أزرار اللايف', 'live-actions');
?>
<?php if ($flash !== null): ?>
    <section class="panel"><div class="pill pill-success"><?= htmlspecialchars($flash) ?></div></section>
<?php endif; ?>
<?php if ($error !== null): ?>
    <section class="panel"><div class="pill pill-danger"><?= htmlspecialchars($error) ?></div></section>
<?php endif; ?>

<section class="panel">
    <h2>إضافة زر جديد للوحة اللايف</h2>
    <form method="post" class="form-grid">
        <input type="hidden" name="action_id" value="0">
        <label>
            <span>مفتاح القسم</span>
            <input type="text" name="section_key" value="broadcast" placeholder="broadcast">
        </label>
        <label>
            <span>اسم القسم</span>
            <input type="text" name="section_title" value="ادارة البث" required>
        </label>
        <label>
            <span>ترتيب القسم</span>
            <input type="number" name="section_order" value="10" min="0">
        </label>
        <label>
            <span>مفتاح الزر</span>
            <input type="text" name="action_key" placeholder="custom_action" required>
        </label>
        <label>
            <span>اسم الزر</span>
            <input type="text" name="label" placeholder="زر جديد" required>
        </label>
        <label>
            <span>نوع الأيقونة</span>
            <input type="text" name="icon_kind" value="custom" placeholder="beauty / game / admin">
        </label>
        <label>
            <span>مسار صورة الأيقونة</span>
            <input type="text" name="icon_asset" placeholder="assets/images/... أو /storage/...">
        </label>
        <label>
            <span>السلوك</span>
            <select name="behavior">
                <?php foreach ($behaviorLabels as $value => $label): ?>
                    <option value="<?= htmlspecialchars($value) ?>"><?= htmlspecialchars($label) ?></option>
                <?php endforeach; ?>
            </select>
        </label>
        <label>
            <span>الحالة</span>
            <select name="status">
                <option value="active">نشط</option>
                <option value="hidden">مخفي</option>
            </select>
        </label>
        <label>
            <span>ترتيب الزر</span>
            <input type="number" name="display_order" value="0" min="0">
        </label>
        <label>
            <span>العنوان عند الضغط</span>
            <input type="text" name="detail_title" placeholder="عنوان التفاصيل">
        </label>
        <label class="checkbox-row">
            <input type="checkbox" name="requires_host" value="1">
            <span>يظهر/يعمل للمضيف فقط</span>
        </label>
        <label class="label-full">
            <span>تفاصيل تظهر داخل التطبيق</span>
            <textarea name="detail_body" rows="3" placeholder="اكتب وصف الزر أو تعليمات استخدامه"></textarea>
        </label>
        <div class="action-row">
            <button class="btn btn-primary" type="submit">إضافة الزر</button>
        </div>
    </form>
</section>

<section class="panel">
    <form method="get" class="toolbar">
        <input type="text" name="search" value="<?= htmlspecialchars($search) ?>" placeholder="ابحث باسم الزر أو السلوك">
        <select name="status">
            <?php foreach (['all' => 'الكل', 'active' => 'نشط', 'hidden' => 'مخفي'] as $value => $label): ?>
                <option value="<?= $value ?>" <?= $status === $value ? 'selected' : '' ?>><?= $label ?></option>
            <?php endforeach; ?>
        </select>
        <button class="btn btn-primary" type="submit">بحث</button>
    </form>
</section>

<section class="panel table-panel">
    <h2>الأزرار الحالية</h2>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>القسم</th>
                <th>الزر</th>
                <th>الأيقونة</th>
                <th>السلوك</th>
                <th>مضيف فقط</th>
                <th>الحالة</th>
                <th>تفاصيل</th>
                <th>حفظ</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($actions as $action): ?>
            <?php $formId = 'live-action-' . (int) $action['id']; ?>
            <tr>
                <td>
                    #<?= (int) $action['id'] ?>
                    <input form="<?= htmlspecialchars($formId) ?>" type="hidden" name="action_id" value="<?= (int) $action['id'] ?>">
                </td>
                <td>
                    <form id="<?= htmlspecialchars($formId) ?>" method="post"></form>
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="section_key" value="<?= htmlspecialchars((string) $action['section_key']) ?>" placeholder="section">
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="section_title" value="<?= htmlspecialchars((string) $action['section_title']) ?>" placeholder="اسم القسم">
                    <input form="<?= htmlspecialchars($formId) ?>" type="number" name="section_order" value="<?= (int) $action['section_order'] ?>" min="0">
                </td>
                <td>
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="action_key" value="<?= htmlspecialchars((string) $action['action_key']) ?>" placeholder="action_key">
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="label" value="<?= htmlspecialchars((string) $action['label']) ?>" placeholder="اسم الزر">
                    <input form="<?= htmlspecialchars($formId) ?>" type="number" name="display_order" value="<?= (int) $action['display_order'] ?>" min="0">
                </td>
                <td>
                    <?= admin_render_media_preview((string) ($action['icon_asset'] ?? ''), (string) $action['label']) ?>
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="icon_kind" value="<?= htmlspecialchars((string) $action['icon_kind']) ?>" placeholder="نوع الأيقونة">
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="icon_asset" value="<?= htmlspecialchars((string) ($action['icon_asset'] ?? '')) ?>" placeholder="مسار الصورة">
                </td>
                <td>
                    <select form="<?= htmlspecialchars($formId) ?>" name="behavior">
                        <?php foreach ($behaviorLabels as $value => $label): ?>
                            <option value="<?= htmlspecialchars($value) ?>" <?= $action['behavior'] === $value ? 'selected' : '' ?>>
                                <?= htmlspecialchars($label) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </td>
                <td>
                    <label class="checkbox-row">
                        <input form="<?= htmlspecialchars($formId) ?>" type="checkbox" name="requires_host" value="1" <?= ((int) $action['requires_host']) === 1 ? 'checked' : '' ?>>
                        <span>نعم</span>
                    </label>
                </td>
                <td>
                    <select form="<?= htmlspecialchars($formId) ?>" name="row_status">
                        <option value="active" <?= $action['status'] === 'active' ? 'selected' : '' ?>>نشط</option>
                        <option value="hidden" <?= $action['status'] === 'hidden' ? 'selected' : '' ?>>مخفي</option>
                    </select>
                </td>
                <td>
                    <input form="<?= htmlspecialchars($formId) ?>" type="text" name="detail_title" value="<?= htmlspecialchars((string) ($action['detail_title'] ?? '')) ?>" placeholder="عنوان التفاصيل">
                    <textarea form="<?= htmlspecialchars($formId) ?>" name="detail_body" rows="2" placeholder="تفاصيل الزر"><?= htmlspecialchars((string) ($action['detail_body'] ?? '')) ?></textarea>
                </td>
                <td><button form="<?= htmlspecialchars($formId) ?>" class="btn btn-secondary" type="submit">حفظ</button></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>

<section class="panel table-panel">
    <h2>آخر ضغطات الأزرار من التطبيق</h2>
    <table class="table">
        <thead>
            <tr>
                <th>#</th>
                <th>الغرفة</th>
                <th>المستخدم</th>
                <th>الزر</th>
                <th>الوقت</th>
            </tr>
        </thead>
        <tbody>
        <?php foreach ($events as $event): ?>
            <tr>
                <td>#<?= (int) $event['id'] ?></td>
                <td><?= htmlspecialchars((string) $event['room_title']) ?></td>
                <td><?= htmlspecialchars((string) ($event['user_nickname'] ?: $event['user_email'] ?: 'مستخدم')) ?></td>
                <td><?= htmlspecialchars((string) $event['action_label_snapshot']) ?></td>
                <td><?= htmlspecialchars((string) $event['created_at']) ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
</section>
<?php admin_render_footer(); ?>
